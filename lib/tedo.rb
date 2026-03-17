# frozen_string_literal: true

require "faraday"
require "json"
require "time"

require_relative "tedo/version"
require_relative "tedo/errors"
require_relative "tedo/resource"
require_relative "tedo/list"
require_relative "tedo/client"
require_relative "tedo/sales_types"

# Resource types
require_relative "tedo/resources/plan"
require_relative "tedo/resources/customer"
require_relative "tedo/resources/subscription"
require_relative "tedo/resources/entitlement_check"
require_relative "tedo/resources/usage"
require_relative "tedo/resources/portal_link"
require_relative "tedo/resources/payment_config"
require_relative "tedo/resources/invoice"
require_relative "tedo/resources/pipeline"
require_relative "tedo/resources/pipeline_stage"
require_relative "tedo/resources/lead"
require_relative "tedo/resources/deal"
require_relative "tedo/resources/activity"
require_relative "tedo/resources/note"
require_relative "tedo/resources/contact_base"
require_relative "tedo/resources/person"
require_relative "tedo/resources/organization"

# API resources
require_relative "tedo/resources/billing"
require_relative "tedo/resources/sales"

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

    def sales
      client.sales
    end

    # Reset the default client (useful for testing)
    def reset_client!
      @client = nil
    end
  end

  self.base_url = "https://api.tedo.ai/v1"
end
