# frozen_string_literal: true

module Tedo
  # A payment configuration linking a provider to a workspace.
  #
  # @example
  #   config = client.billing.get_payment_config("cfg_xxx")
  #   config.provider      # => "mollie"
  #   config.payment_mode  # => "request"
  #   config.default?      # => true
  #
  class PaymentConfig < Resource
    attribute :id
    attribute :provider
    attribute :connection_id
    attribute :is_default
    attribute :payment_mode
    attribute :settings
    attribute :created_at, type: :time
    attribute :updated_at, type: :time

    # Predicate for default status.
    def default?
      is_default == true
    end

    # Update this payment config.
    #
    # @param provider [String, nil] New provider
    # @param connection_id [String, nil] New connection ID
    # @param is_default [Boolean, nil] Set as default
    # @param settings [Hash, nil] New settings
    # @return [PaymentConfig] The updated config
    def update(provider: nil, connection_id: nil, is_default: nil, settings: nil)
      raise "No client available" unless client

      client.billing.update_payment_config(id, provider: provider,
                                               connection_id: connection_id,
                                               is_default: is_default,
                                               settings: settings)
    end

    # Delete this payment config.
    #
    # @return [void]
    def delete
      raise "No client available" unless client

      client.billing.delete_payment_config(id)
    end
  end
end
