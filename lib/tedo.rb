# frozen_string_literal: true

require "faraday"
require "json"
require "time"

require_relative "tedo/version"
require_relative "tedo/errors"
require_relative "tedo/client"
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
  end

  self.base_url = "https://api.tedo.ai/v1"
end
