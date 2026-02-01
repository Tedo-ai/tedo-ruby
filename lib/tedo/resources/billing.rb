# frozen_string_literal: true

module Tedo
  module Resources
    # Billing API resource
    #
    # @example Create a customer
    #   client = Tedo::Client.new("tedo_live_xxx")
    #   customer = client.billing.create_customer(
    #     email: "user@example.com",
    #     name: "Acme Corp"
    #   )
    #
    # @example Check entitlement
    #   result = client.billing.check_entitlement(
    #     customer_id: customer["id"],
    #     entitlement_key: "api_access"
    #   )
    #   puts "Has access: #{result['has_access']}"
    #
    class Billing
      def initialize(client)
        @client = client
      end

      # ============================================================
      # CUSTOMERS
      # ============================================================

      # Create a new customer.
      #
      # @param email [String] Customer email address (required)
      # @param name [String] Customer display name
      # @param external_id [String] Your internal customer ID
      # @param metadata [Hash] Arbitrary key-value metadata
      # @return [Hash] The created customer
      #
      # @example
      #   customer = client.billing.create_customer(
      #     email: "user@example.com",
      #     name: "Acme Corp",
      #     metadata: { plan: "enterprise" }
      #   )
      def create_customer(email:, name: nil, external_id: nil, metadata: nil)
        body = { email: email }
        body[:name] = name if name
        body[:external_id] = external_id if external_id
        body[:metadata] = metadata if metadata

        @client.post("/billing/customers", body)
      end

      # Retrieve a customer by ID.
      #
      # @param id [String] Customer ID
      # @return [Hash] The customer
      def get_customer(id)
        @client.get("/billing/customers/#{id}")
      end

      # List all customers.
      #
      # @param limit [Integer] Maximum number of customers to return
      # @param cursor [String] Pagination cursor
      # @return [Hash] Paginated list with :customers, :total, :next_cursor
      #
      # @example Iterate through all customers
      #   cursor = nil
      #   loop do
      #     result = client.billing.list_customers(limit: 100, cursor: cursor)
      #     result["customers"].each { |c| puts c["email"] }
      #     cursor = result["next_cursor"]
      #     break unless cursor
      #   end
      def list_customers(limit: nil, cursor: nil)
        params = {}
        params[:limit] = limit if limit
        params[:cursor] = cursor if cursor

        @client.get("/billing/customers", params)
      end

      # Update a customer.
      #
      # @param id [String] Customer ID
      # @param email [String] New email address
      # @param name [String] New display name
      # @param external_id [String] New external ID
      # @param metadata [Hash] New metadata (replaces existing)
      # @return [Hash] The updated customer
      def update_customer(id, email: nil, name: nil, external_id: nil, metadata: nil)
        body = {}
        body[:email] = email if email
        body[:name] = name if name
        body[:external_id] = external_id if external_id
        body[:metadata] = metadata if metadata

        @client.patch("/billing/customers/#{id}", body)
      end

      # Delete a customer.
      #
      # @param id [String] Customer ID
      # @note Fails if the customer has active subscriptions
      def delete_customer(id)
        @client.delete("/billing/customers/#{id}")
      end

      # ============================================================
      # SUBSCRIPTIONS
      # ============================================================

      # Create a subscription.
      #
      # @param customer_id [String] Customer ID to subscribe
      # @param price_id [String] Price ID to subscribe to
      # @param quantity [Integer] Quantity (for per-seat pricing)
      # @param metadata [Hash] Subscription metadata
      # @return [Hash] The created subscription
      #
      # @example
      #   subscription = client.billing.create_subscription(
      #     customer_id: "cus_xxx",
      #     price_id: "price_xxx",
      #     quantity: 5
      #   )
      def create_subscription(customer_id:, price_id:, quantity: nil, metadata: nil)
        body = { customer_id: customer_id, price_id: price_id }
        body[:quantity] = quantity if quantity
        body[:metadata] = metadata if metadata

        @client.post("/billing/subscriptions", body)
      end

      # Retrieve a subscription by ID.
      #
      # @param id [String] Subscription ID
      # @return [Hash] The subscription
      def get_subscription(id)
        @client.get("/billing/subscriptions/#{id}")
      end

      # Cancel a subscription.
      #
      # @param id [String] Subscription ID
      # @return [Hash] The canceled subscription
      # @note Subscription remains active until end of current period
      def cancel_subscription(id)
        @client.delete("/billing/subscriptions/#{id}")
      end

      # ============================================================
      # ENTITLEMENTS
      # ============================================================

      # Check if a customer has access to a feature.
      #
      # @param customer_id [String] Customer ID
      # @param entitlement_key [String] Feature key (e.g., "api_access")
      # @return [Hash] Result with :has_access, :value, :plan_name
      #
      # @example
      #   result = client.billing.check_entitlement(
      #     customer_id: "cus_xxx",
      #     entitlement_key: "api_requests"
      #   )
      #   if result["has_access"]
      #     puts "Limit: #{result['value']}"
      #   end
      def check_entitlement(customer_id:, entitlement_key:)
        @client.post("/billing/entitlements/check", {
          customer_id: customer_id,
          entitlement_key: entitlement_key
        })
      end

      # ============================================================
      # USAGE
      # ============================================================

      # Record usage for a metered subscription.
      #
      # @param subscription_id [String] Subscription ID
      # @param quantity [Integer] Usage quantity to record
      # @param timestamp [Time] When the usage occurred (defaults to now)
      # @param idempotency_key [String] Unique key to prevent duplicates
      # @return [Hash] The usage record
      #
      # @example
      #   record = client.billing.record_usage(
      #     subscription_id: "sub_xxx",
      #     quantity: 100,
      #     idempotency_key: "usage-2024-01-15-batch1"
      #   )
      def record_usage(subscription_id:, quantity:, timestamp: nil, idempotency_key: nil)
        body = { subscription_id: subscription_id, quantity: quantity }
        body[:timestamp] = timestamp.iso8601 if timestamp
        body[:idempotency_key] = idempotency_key if idempotency_key

        @client.post("/billing/usage", body)
      end

      # Get aggregated usage for a subscription.
      #
      # @param subscription_id [String] Subscription ID
      # @return [Hash] Usage summary with :total_usage, :period_start, :period_end
      def get_usage_summary(subscription_id:)
        @client.get("/billing/usage", { subscription_id: subscription_id })
      end
    end
  end
end
