# frozen_string_literal: true

require "faraday"
require "json"
require "time"

require_relative "tedo/version"
require_relative "tedo/errors"
require_relative "tedo/resource"
require_relative "tedo/list"
require_relative "tedo/client"

# Resource types
require_relative "tedo/resources/plan"
require_relative "tedo/resources/customer"
require_relative "tedo/resources/subscription"
require_relative "tedo/resources/entitlement_check"
require_relative "tedo/resources/usage"
require_relative "tedo/resources/portal_link"
require_relative "tedo/resources/payment_config"

# API resources
require_relative "tedo/resources/billing"

module Tedo
  class << self
    attr_accessor :api_key, :base_url

    def configure
      yield self
    end

    # Convenience method for quick access
    def client
      @client ||= Client.new(api_key)
    end

    def billing
      client.billing
    end

    # Reset the default client (useful for testing)
    def reset_client!
      @client = nil
    end
  end

  self.base_url = "https://api.tedo.ai/v1"
end
