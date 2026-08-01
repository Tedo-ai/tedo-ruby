# frozen_string_literal: true

module Tedo
  # One immutable money-valued usage fact accepted by Billing.
  class BillableUsageRecord < Resource
    attribute :id
    attribute :idempotency_key
    attribute :customer_id
    attribute :subscription_id
    attribute :product_key
    attribute :amount_excluding_tax_cents
    attribute :currency
    attribute :occurred_at, type: :time
    attribute :recorded_at, type: :time
    attribute :metadata
    attribute :state
    attribute :reversal_of
    attribute :applied_period_start, type: :time
    attribute :applied_period_end, type: :time
    attribute :charge_id
    attribute :invoice_id

    predicate :pending, field: "state", value: "pending"
    predicate :applied, field: "state", value: "applied"
  end

  # The durable customer-period composition or manual closure.
  class PeriodComposition < Resource
    attribute :id
    attribute :customer_id
    attribute :subscription_id
    attribute :period_start, type: :time
    attribute :period_end, type: :time
    attribute :timezone
    attribute :external_period_key
    attribute :mode
    attribute :currency
    attribute :usage_record_count
    attribute :usage_amount_excluding_tax_cents
    attribute :subscription_amount_excluding_tax_cents
    attribute :total_amount_excluding_tax_cents
    attribute :charge_id
    attribute :invoice_id
    attribute :reason
    attribute :created_at, type: :time

    predicate :automatic, field: "mode", value: "automatic"
    predicate :manual, field: "mode", value: "manual"
  end

  # A Billing charge returned by the customer-period composer.
  class BillingCharge < Resource
    attribute :id
    attribute :customer_id
    attribute :subscription_id
    attribute :number
    attribute :status
    attribute :currency
    attribute :subtotal
    attribute :tax
    attribute :total
    attribute :amount_paid
    attribute :amount_due
    attribute :period_start, type: :time
    attribute :period_end, type: :time
    attribute :lines
    attribute :metadata
    attribute :created_at, type: :time
  end

  # Result shared by automatic composition and manual closure.
  class PeriodCompositionResult < Resource
    def composition
      value = self["composition"]
      value && PeriodComposition.new(value, client: client)
    end

    def charge
      value = self["charge"]
      value && BillingCharge.new(value, client: client)
    end

    def usage_record_ids
      self["usage_record_ids"] || []
    end

    def already_existed?
      self["already_existed"] == true
    end
  end
end
