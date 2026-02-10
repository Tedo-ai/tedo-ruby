# frozen_string_literal: true

module Tedo
  # A subscription plan.
  #
  # @example
  #   plan = client.billing.get_plan("plan_xxx")
  #   plan.id          # => "plan_xxx"
  #   plan.key         # => "pro"
  #   plan.name        # => "Pro Plan"
  #   plan.active?     # => true
  #
  # @example Access prices and entitlements
  #   plan.prices.each { |p| puts "#{p.key}: #{p.amount}" }
  #   plan.entitlements.each { |e| puts "#{e.key}: #{e.value_int}" }
  #
  class Plan < Resource
    attribute :id
    attribute :key
    attribute :name
    attribute :description
    attribute :is_active
    attribute :created_at, type: :time
    attribute :updated_at, type: :time

    # Predicate for active status
    def active?
      is_active == true
    end

    # Returns prices as Price objects.
    #
    # @return [Array<Price>]
    def prices
      @prices ||= (@data["prices"] || []).map do |p|
        Price.new(p, client: client)
      end
    end

    # Returns entitlements as Entitlement objects.
    #
    # @return [Array<Entitlement>]
    def entitlements
      @entitlements ||= (@data["entitlements"] || []).map do |e|
        PlanEntitlement.new(e, client: client)
      end
    end

    # Update this plan.
    #
    # @param key [String, nil] New plan key
    # @param name [String, nil] New display name
    # @param description [String, nil] New description
    # @param is_active [Boolean, nil] Set active/inactive
    # @return [Plan] The updated plan
    def update(key: nil, name: nil, description: nil, is_active: nil)
      raise "No client available" unless client

      client.billing.update_plan(id, key: key, name: name,
                                     description: description, is_active: is_active)
    end

    # Delete (deactivate) this plan.
    #
    # @return [void]
    def delete
      raise "No client available" unless client

      client.billing.delete_plan(id)
    end

    # Create a price for this plan.
    #
    # @param key [String] Price key
    # @param amount [Integer] Amount in cents
    # @param currency [String] Currency code
    # @param interval [String] Billing interval (month, year)
    # @return [Price]
    def create_price(key:, amount:, currency: "USD", interval: "month", interval_count: 1, trial_days: 0)
      raise "No client available" unless client

      client.billing.create_price(id, key: key, amount: amount, currency: currency,
                                      interval: interval, interval_count: interval_count,
                                      trial_days: trial_days)
    end

    # Create an entitlement for this plan.
    #
    # @param key [String] Feature key
    # @param value_bool [Boolean, nil] Boolean value
    # @param value_int [Integer, nil] Integer value
    # @return [PlanEntitlement]
    def create_entitlement(key:, value_bool: nil, value_int: nil, overage_price: nil, overage_unit: nil)
      raise "No client available" unless client

      client.billing.create_entitlement(id, key: key, value_bool: value_bool,
                                            value_int: value_int, overage_price: overage_price,
                                            overage_unit: overage_unit)
    end
  end

  # A price for a plan.
  #
  # @example
  #   price = plan.prices.first
  #   price.amount    # => 2900 (cents)
  #   price.currency  # => "USD"
  #   price.interval  # => "month"
  #
  class Price < Resource
    attribute :id
    attribute :plan_id
    attribute :key
    attribute :amount
    attribute :currency
    attribute :interval
    attribute :interval_count
    attribute :trial_days
    attribute :created_at, type: :time

    # Archive this price.
    #
    # @return [void]
    def archive
      raise "No client available" unless client

      client.billing.archive_price(plan_id, id)
    end
  end

  # An entitlement (feature/limit) on a plan.
  #
  # @example
  #   ent = plan.entitlements.first
  #   ent.key        # => "api_requests"
  #   ent.value_int  # => 10000
  #
  class PlanEntitlement < Resource
    attribute :id
    attribute :plan_id
    attribute :key
    attribute :value_bool
    attribute :value_int
    attribute :overage_price
    attribute :overage_unit
    attribute :created_at, type: :time

    # Archive this entitlement.
    #
    # @return [void]
    def archive
      raise "No client available" unless client

      client.billing.archive_entitlement(plan_id, id)
    end
  end
end
