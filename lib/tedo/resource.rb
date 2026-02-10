# frozen_string_literal: true

module Tedo
  # Base class for API resources.
  #
  # Wraps API response hashes and provides:
  # - Attribute accessors (customer.email instead of customer["email"])
  # - Predicate methods for status fields (subscription.active?)
  # - Type coercion for timestamps
  # - Access to raw data via #to_h
  #
  # @example
  #   customer = Tedo::Customer.new(data, client: client)
  #   customer.email        # => "user@example.com"
  #   customer.created_at   # => Time object
  #   customer.to_h         # => raw hash
  #
  class Resource
    # @return [Hash] The raw API response data
    attr_reader :data

    # @return [Client, nil] The client used to make further requests
    attr_reader :client

    def initialize(data, client: nil)
      @data = data || {}
      @client = client
    end

    # Access attributes by name.
    #
    # @param key [String, Symbol] The attribute name
    # @return [Object] The attribute value
    def [](key)
      @data[key.to_s]
    end

    # Returns the raw hash data.
    #
    # @return [Hash]
    def to_h
      @data
    end
    alias to_hash to_h

    # Returns a JSON representation.
    #
    # @return [String]
    def to_json(*args)
      @data.to_json(*args)
    end

    # Inspect for debugging.
    def inspect
      "#<#{self.class.name} #{@data.inspect}>"
    end

    protected

    # Define an attribute accessor that reads from @data.
    #
    # @param name [Symbol] The attribute name
    # @param key [String, nil] The key in @data (defaults to name.to_s)
    # @param type [Symbol, nil] Type coercion (:time for timestamps)
    def self.attribute(name, key: nil, type: nil)
      key ||= name.to_s

      define_method(name) do
        value = @data[key]
        return nil if value.nil?

        case type
        when :time
          value.is_a?(Time) ? value : Time.parse(value.to_s)
        else
          value
        end
      end
    end

    # Define a predicate method for status checking.
    #
    # @param name [Symbol] Method name without '?' (e.g., :active for active?)
    # @param field [String] The field to check
    # @param value [Object] The value that makes it true
    def self.predicate(name, field:, value:)
      define_method("#{name}?") do
        @data[field] == value
      end
    end
  end
end
