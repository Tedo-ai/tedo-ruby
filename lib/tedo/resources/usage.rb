# frozen_string_literal: true

module Tedo
  # A recorded usage event.
  #
  # @example
  #   record = client.billing.record_usage(
  #     subscription_id: "sub_xxx",
  #     quantity: 100
  #   )
  #   record.id        # => "usg_xxx"
  #   record.quantity  # => 100
  #   record.timestamp # => Time
  #
  class UsageRecord < Resource
    attribute :id
    attribute :subscription_id
    attribute :quantity
    attribute :timestamp, type: :time
  end

  # Aggregated usage summary for a billing period.
  #
  # @example
  #   summary = client.billing.get_usage_summary(subscription_id: "sub_xxx")
  #   summary.total_usage   # => 1500
  #   summary.records       # => 42 (number of records)
  #   summary.period_start  # => Time
  #   summary.period_end    # => Time
  #
  class UsageSummary < Resource
    attribute :subscription_id
    attribute :total_usage
    attribute :records
    attribute :period_start, type: :time
    attribute :period_end, type: :time
  end
end
