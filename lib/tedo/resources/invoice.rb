# frozen_string_literal: true

module Tedo
  # A billing invoice.
  #
  # @example
  #   invoice = client.billing.get_invoice("inv_xxx")
  #   invoice.status   # => "paid"
  #   invoice.paid?    # => true
  #   invoice.total    # => 500 (cents)
  #
  # @example Create checkout for an open invoice
  #   result = invoice.create_checkout
  #   redirect_to result.checkout_url
  #
  class Invoice < Resource
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
    attribute :due_date, type: :time
    attribute :lines
    attribute :notes
    attribute :metadata
    attribute :created_at, type: :time
    attribute :updated_at, type: :time

    # Status predicates
    predicate :paid, field: "status", value: "paid"
    predicate :open, field: "status", value: "open"
    predicate :draft, field: "status", value: "draft"
    predicate :void, field: "status", value: "void"

    # Create a checkout session for this invoice.
    #
    # @param redirect_url [String, nil] URL to redirect after payment
    # @return [InvoiceCheckoutResult] Result with checkout_url, payment_id
    def create_checkout(redirect_url: nil)
      raise "No client available" unless client

      client.billing.create_invoice_checkout(id, redirect_url: redirect_url)
    end
  end

  # Result of creating an invoice checkout session.
  class InvoiceCheckoutResult < Resource
    attribute :payment_id
    attribute :invoice_id
    attribute :checkout_url
  end

  # A checkout link for a subscription.
  class CheckoutLink < Resource
    attribute :checkout_url
    attribute :token
    attribute :expires_at, type: :time
  end

  # Status of a billing payment.
  class PaymentStatusResult < Resource
    attribute :id
    attribute :status
    attribute :invoice_id

    predicate :paid, field: "status", value: "paid"
    predicate :pending, field: "status", value: "pending"
    predicate :failed, field: "status", value: "failed"
  end
end
