# frozen_string_literal: true

module VoiceTel
  # Response and request models, one file per resource. Every model is a
  # Data.define class whose members are snake_case mirrors of the spec's
  # camelCase wire fields. Base (class-side) builds responses, Request
  # (instance-side) renders requests.
  module Models
    # Class-side plumbing for response models. .build turns an unwrapped API
    # payload (a String-keyed, camelCase Hash) into a model instance:
    #
    # - Wire keys are mapped onto members by camelCasing the member name
    #   (campaign_id -> "campaignId"); .wire_keys overrides the exceptions
    #   (ticket_number -> "number").
    # - Members declared in .nested are built recursively; a declared member
    #   accepts either a single object or a list of them on the wire.
    # - Payload keys without a member are ignored, so the server can add
    #   fields without breaking this SDK; members absent from the payload
    #   are set to nil.
    module Base
      # Nested model classes by member — { job: MessagingEnablementJob }.
      def nested
        {}
      end

      # Wire-key overrides for members whose spec name is not the camelCase
      # form of the member — { ticket_number: "number" }.
      def wire_keys
        {}
      end

      # Build a model from an unwrapped payload. nil builds to nil (204
      # responses) and non-Hash payloads pass through untouched.
      def build(payload)
        return nil if payload.nil?
        return payload unless payload.is_a?(Hash)

        kwargs = {}
        members.each do |member|
          key = wire_keys.fetch(member) { Models.wire_key(member) }
          value = payload.key?(key) ? convert(payload[key], nested[member]) : nil
          kwargs[member] = value
        end
        new(**kwargs)
      end

      private

      def convert(value, type)
        return value if type.nil? || value.nil?

        if value.is_a?(Array)
          value.map { |item| item.is_a?(Hash) ? type.build(item) : item }
        else
          type.build(value)
        end
      end
    end

    # Instance-side plumbing for request models. #to_payload renders the
    # model as a plain snake_case Hash for the transport (which camelCases
    # the keys on the wire); nil members are omitted so PATCH/PUT bodies keep
    # "field absent" and "explicit value" distinguishable. There are no
    # defaults — pass nil for anything you don't want to send.
    module Request
      def to_payload
        self.class.members.each_with_object({}) do |member, out|
          value = public_send(member)
          out[member] = Models.plain(value) unless value.nil?
        end
      end
    end

    module_function

    # camelCase wire key for a snake_case member.
    def wire_key(member)
      s = member.to_s
      return s unless s.include?("_")

      head, *rest = s.split("_")
      head + rest.map(&:capitalize).join
    end

    # Recursively render nested request models as plain Ruby structures.
    def plain(value)
      case value
      when Hash then value.transform_values { |v| plain(v) }
      when Array then value.map { |v| plain(v) }
      else value.respond_to?(:to_payload) ? value.to_payload : value
      end
    end
  end
end
