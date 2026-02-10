# frozen_string_literal: true

module Tedo
  # A billing subscription.
  #
  # @example
  #   subscription = client.billing.get_subscription("sub_xxx")
  #   subscription.id          # => "sub_xxx"
  #   subscription.status      # => "active"
  #   subscription.active?     # => true
  #   subscription.canceled?   # => false
  #
  # @example Cancel a subscription
  #   subscription.cancel
  #
  # @example Record usage
  #   subscription.record_usage(quantity: 100)
  #
  class Subscription < Resource
    attribute :id
    attribute :customer_id
    attribute :price_id
    attribute :status
    attribute :quantity
    attribute :metadata
    attribute :started_at, type: :time
    attribute :canceled_at, type: :time
    attribute :created_at, type: :time

    # Status predicates
    predicate :active, field: "status", value: "active"
    predicate :canceled, field: "status", value: "canceled"
    predicate :past_due, field: "status", value: "past_due"
    predicate :trialing, field: "status", value: "trialing"
    predicate :paused, field: "status", value: "paused"

    # Cancel this subscription.
    #
    # @return [Subscription] The canceled subscription
    # @note Subscription remains active until end of current period
    def cancel
      raise "No client available" unless client

      client.billing.cancel_subscription(id)
    end

    # Record usage for this metered subscription.
    #
    # @param quantity [Integer] Usage quantity to record
    # @param timestamp [Time, nil] When the usage occurred (defaults to now)
    # @param idempotency_key [String, nil] Unique key to prevent duplicates
    # @return [UsageRecord]
    def record_usage(quantity:, timestamp: nil, idempotency_key: nil)
      raise "No client available" unless client

      client.billing.record_usage(
        subscription_id: id,
        quantity: quantity,
        timestamp: timestamp,
        idempotency_key: idempotency_key
      )
    end

    # Get aggregated usage for this subscription.
    #
    # @return [UsageSummary]
    def usage_summary
      raise "No client available" unless client

      client.billing.get_usage_summary(subscription_id: id)
    end
  end
end
