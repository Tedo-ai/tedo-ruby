# frozen_string_literal: true

module Tedo
  # A billing customer.
  #
  # @example
  #   customer = client.billing.get_customer("cus_xxx")
  #   customer.id           # => "cus_xxx"
  #   customer.email        # => "user@example.com"
  #   customer.created_at   # => Time
  #   customer.metadata     # => {"plan" => "enterprise"}
  #
  # @example Update a customer
  #   customer.update(name: "New Name")
  #
  # @example Delete a customer
  #   customer.delete
  #
  class Customer < Resource
    attribute :id
    attribute :email
    attribute :name
    attribute :external_id
    attribute :metadata
    attribute :created_at, type: :time
    attribute :updated_at, type: :time

    # Returns associated subscriptions as Subscription objects.
    #
    # @return [Array<Subscription>]
    def subscriptions
      @subscriptions ||= (@data["subscriptions"] || []).map do |sub|
        Subscription.new(sub, client: client)
      end
    end

    # Update this customer.
    #
    # @param email [String, nil] New email address
    # @param name [String, nil] New display name
    # @param external_id [String, nil] New external ID
    # @param metadata [Hash, nil] New metadata (replaces existing)
    # @return [Customer] The updated customer
    def update(email: nil, name: nil, external_id: nil, metadata: nil)
      raise "No client available" unless client

      client.billing.update_customer(id, email: email, name: name,
                                         external_id: external_id, metadata: metadata)
    end

    # Delete this customer.
    #
    # @return [void]
    # @note Fails if the customer has active subscriptions
    def delete
      raise "No client available" unless client

      client.billing.delete_customer(id)
    end

    # Create a subscription for this customer.
    #
    # @param price_id [String] Price ID to subscribe to
    # @param quantity [Integer, nil] Quantity (for per-seat pricing)
    # @param metadata [Hash, nil] Subscription metadata
    # @return [Subscription]
    def subscribe(price_id:, quantity: nil, metadata: nil)
      raise "No client available" unless client

      client.billing.create_subscription(
        customer_id: id,
        price_id: price_id,
        quantity: quantity,
        metadata: metadata
      )
    end

    # Check if this customer has access to a feature.
    #
    # @param entitlement_key [String] Feature key (e.g., "api_access")
    # @return [EntitlementCheck]
    def entitled?(entitlement_key)
      raise "No client available" unless client

      result = client.billing.check_entitlement(
        customer_id: id,
        entitlement_key: entitlement_key
      )
      result.has_access
    end

    # Check entitlement with full details.
    #
    # @param entitlement_key [String] Feature key
    # @return [EntitlementCheck]
    def check_entitlement(entitlement_key)
      raise "No client available" unless client

      client.billing.check_entitlement(
        customer_id: id,
        entitlement_key: entitlement_key
      )
    end

    # Create a portal link for this customer.
    #
    # @param expires_in_hours [Integer] Hours until link expires (default: 24)
    # @return [PortalLink]
    def create_portal_link(expires_in_hours: 24)
      raise "No client available" unless client

      client.billing.create_portal_link(
        customer_id: id,
        expires_in_hours: expires_in_hours
      )
    end
  end
end
