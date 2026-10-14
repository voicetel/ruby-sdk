# frozen_string_literal: true

# Hub for the model layer — mirrors the spec's schemas one file per
# resource. Response models are built by the resource layer via .build;
# request models are accepted wherever a plain Hash body is.

require_relative "models/base"
require_relative "models/common"
require_relative "models/account"
require_relative "models/acl"
require_relative "models/authentication"
require_relative "models/e911"
require_relative "models/gateways"
require_relative "models/i_numbering"
require_relative "models/lookups"
require_relative "models/messaging"
require_relative "models/numbers"
require_relative "models/support"
