# frozen_string_literal: true

module Tedo
  module Resources
    # Billing API resource.
    #
    # @example Create a customer
    #   customer = client.billing.create_customer(
    #     email: "user@example.com",
    #     name: "Acme Corp"
    #   )
    #   customer.id    # => "cus_xxx"
    #   customer.email # => "user@example.com"
    #
    # @example List customers with auto-pagination
    #   client.billing.list_customers.auto_paging_each do |customer|
    #     puts customer.email
    #   end
    #
    # @example Check entitlement
    #   result = client.billing.check_entitlement(
    #     customer_id: "cus_xxx",
    #     entitlement_key: "api_access"
    #   )
    #   result.has_access # => true
    #   result.allowed?   # => true
    #
    class Billing
      def initialize(client)
        @client = client
      end

      # ============================================================
      # PLANS
      # ============================================================

      # Create a new subscription plan.
      #
      # @param key [String] Unique plan identifier (e.g., 'free', 'pro')
      # @param name [String] Display name
      # @param description [String, nil] Plan description
      # @return [Plan] The created plan
      #
      # @example
      #   plan = client.billing.create_plan(
      #     key: "pro",
      #     name: "Pro Plan",
      #     description: "For growing teams"
      #   )
      #   plan.create_price(key: "monthly", amount: 2900)
      #
      def create_plan(key:, name:, description: nil)
        body = { key: key, name: name }
        body[:description] = description if description

        data = @client.post("/billing/plans", body)
        Plan.new(data, client: @client)
      end

      # List all plans.
      #
      # @return [Array<Plan>] List of plans
      def list_plans
        data = @client.get("/billing/plans")
        (data["plans"] || []).map { |p| Plan.new(p, client: @client) }
      end

      # Get a plan by ID.
      #
      # @param id [String] Plan ID
      # @return [Plan] The plan with prices and entitlements
      def get_plan(id)
        data = @client.get("/billing/plans/#{id}")
        Plan.new(data, client: @client)
      end

      # Update a plan.
      #
      # @param id [String] Plan ID
      # @param key [String, nil] New plan key
      # @param name [String, nil] New display name
      # @param description [String, nil] New description
      # @param is_active [Boolean, nil] Set active/inactive
      # @return [Plan] The updated plan
      def update_plan(id, key: nil, name: nil, description: nil, is_active: nil)
        body = {}
        body[:key] = key if key
        body[:name] = name if name
        body[:description] = description if description
        body[:is_active] = is_active unless is_active.nil?

        data = @client.patch("/billing/plans/#{id}", body)
        Plan.new(data, client: @client)
      end

      # Delete (deactivate) a plan.
      #
      # @param id [String] Plan ID
      # @return [void]
      def delete_plan(id)
        @client.delete("/billing/plans/#{id}")
        nil
      end

      # ============================================================
      # PRICES
      # ============================================================

      # Create a price for a plan.
      #
      # @param plan_id [String] Plan ID
      # @param key [String] Price identifier (e.g., 'monthly', 'yearly')
      # @param amount [Integer] Price in cents (e.g., 2900 for $29.00)
      # @param currency [String] Currency code (default: USD)
      # @param interval [String] Billing interval (month, year)
      # @param interval_count [Integer] Number of intervals
      # @param trial_days [Integer] Free trial days
      # @return [Price] The created price
      #
      # @example
      #   price = client.billing.create_price(
      #     "plan_xxx",
      #     key: "monthly",
      #     amount: 2900,
      #     interval: "month"
      #   )
      #
      def create_price(plan_id, key:, amount:, currency: "USD", interval: "month", interval_count: 1, trial_days: 0)
        body = {
          key: key,
          amount: amount,
          currency: currency,
          interval: interval,
          interval_count: interval_count,
          trial_days: trial_days
        }

        data = @client.post("/billing/plans/#{plan_id}/prices", body)
        Price.new(data, client: @client)
      end

      # List prices for a plan.
      #
      # @param plan_id [String] Plan ID
      # @return [Array<Price>] List of prices
      def list_prices(plan_id)
        data = @client.get("/billing/plans/#{plan_id}/prices")
        (data["prices"] || []).map { |p| Price.new(p, client: @client) }
      end

      # Archive a price.
      #
      # @param plan_id [String] Plan ID
      # @param price_id [String] Price ID
      # @return [void]
      def archive_price(plan_id, price_id)
        @client.delete("/billing/plans/#{plan_id}/prices/#{price_id}")
        nil
      end

      # ============================================================
      # ENTITLEMENTS (Plan Features)
      # ============================================================

      # Create an entitlement for a plan.
      #
      # @param plan_id [String] Plan ID
      # @param key [String] Feature key (e.g., 'api_access', 'max_users')
      # @param value_bool [Boolean, nil] Boolean value (for feature flags)
      # @param value_int [Integer, nil] Integer value (for limits)
      # @param overage_price [Integer, nil] Price per unit over limit
      # @param overage_unit [Integer, nil] Units per overage charge
      # @return [PlanEntitlement] The created entitlement
      #
      # @example Feature flag
      #   client.billing.create_entitlement("plan_xxx", key: "api_access", value_bool: true)
      #
      # @example Usage limit
      #   client.billing.create_entitlement("plan_xxx", key: "api_requests", value_int: 10000)
      #
      def create_entitlement(plan_id, key:, value_bool: nil, value_int: nil, overage_price: nil, overage_unit: nil)
        body = { key: key }
        body[:value_bool] = value_bool unless value_bool.nil?
        body[:value_int] = value_int if value_int
        body[:overage_price] = overage_price if overage_price
        body[:overage_unit] = overage_unit if overage_unit

        data = @client.post("/billing/plans/#{plan_id}/entitlements", body)
        PlanEntitlement.new(data, client: @client)
      end

      # List entitlements for a plan.
      #
      # @param plan_id [String] Plan ID
      # @return [Array<PlanEntitlement>] List of entitlements
      def list_entitlements(plan_id)
        data = @client.get("/billing/plans/#{plan_id}/entitlements")
        (data["entitlements"] || []).map { |e| PlanEntitlement.new(e, client: @client) }
      end

      # Archive an entitlement.
      #
      # @param plan_id [String] Plan ID
      # @param entitlement_id [String] Entitlement ID
      # @return [void]
      def archive_entitlement(plan_id, entitlement_id)
        @client.delete("/billing/plans/#{plan_id}/entitlements/#{entitlement_id}")
        nil
      end

      # ============================================================
      # CUSTOMERS
      # ============================================================

      # Create a new customer.
      #
      # @param email [String] Customer email address (required)
      # @param name [String, nil] Customer display name
      # @param external_id [String, nil] Your internal customer ID
      # @param metadata [Hash, nil] Arbitrary key-value metadata
      # @return [Customer] The created customer
      #
      # @example
      #   customer = client.billing.create_customer(
      #     email: "user@example.com",
      #     name: "Acme Corp",
      #     metadata: { plan: "enterprise" }
      #   )
      #   customer.subscribe(price_id: "price_xxx")
      #
      def create_customer(email:, name: nil, external_id: nil, metadata: nil)
        body = { email: email }
        body[:name] = name if name
        body[:external_id] = external_id if external_id
        body[:metadata] = metadata if metadata

        data = @client.post("/billing/customers", body)
        Customer.new(data, client: @client)
      end

      # Retrieve a customer by ID.
      #
      # @param id [String] Customer ID
      # @return [Customer] The customer
      def get_customer(id)
        data = @client.get("/billing/customers/#{id}")
        Customer.new(data, client: @client)
      end

      # List all customers.
      #
      # @param limit [Integer, nil] Maximum number of customers per page
      # @param cursor [String, nil] Pagination cursor
      # @return [List<Customer>] Paginated list of customers
      #
      # @example Iterate through all customers
      #   client.billing.list_customers.auto_paging_each do |customer|
      #     puts customer.email
      #   end
      #
      # @example Manual pagination
      #   list = client.billing.list_customers(limit: 10)
      #   list.each { |c| puts c.email }
      #   next_page = list.next_page if list.has_more?
      #
      def list_customers(limit: nil, cursor: nil)
        fetch_customers_page(limit: limit, cursor: cursor)
      end

      # Update a customer.
      #
      # @param id [String] Customer ID
      # @param email [String, nil] New email address
      # @param name [String, nil] New display name
      # @param external_id [String, nil] New external ID
      # @param metadata [Hash, nil] New metadata (replaces existing)
      # @return [Customer] The updated customer
      def update_customer(id, email: nil, name: nil, external_id: nil, metadata: nil)
        body = {}
        body[:email] = email if email
        body[:name] = name if name
        body[:external_id] = external_id if external_id
        body[:metadata] = metadata if metadata

        data = @client.patch("/billing/customers/#{id}", body)
        Customer.new(data, client: @client)
      end

      # Delete a customer.
      #
      # @param id [String] Customer ID
      # @return [void]
      # @note Fails if the customer has active subscriptions
      def delete_customer(id)
        @client.delete("/billing/customers/#{id}")
        nil
      end

      # ============================================================
      # SUBSCRIPTIONS
      # ============================================================

      # Create a subscription.
      #
      # @param customer_id [String] Customer ID to subscribe
      # @param price_id [String] Price ID to subscribe to
      # @param quantity [Integer, nil] Quantity (for per-seat pricing)
      # @param metadata [Hash, nil] Subscription metadata
      # @return [Subscription] The created subscription
      #
      # @example
      #   subscription = client.billing.create_subscription(
      #     customer_id: "cus_xxx",
      #     price_id: "price_xxx",
      #     quantity: 5
      #   )
      #   subscription.active? # => true
      #
      def create_subscription(customer_id:, price_id:, quantity: nil, metadata: nil)
        body = { customer_id: customer_id, price_id: price_id }
        body[:quantity] = quantity if quantity
        body[:metadata] = metadata if metadata

        data = @client.post("/billing/subscriptions", body)
        Subscription.new(data, client: @client)
      end

      # Retrieve a subscription by ID.
      #
      # @param id [String] Subscription ID
      # @return [Subscription] The subscription
      def get_subscription(id)
        data = @client.get("/billing/subscriptions/#{id}")
        Subscription.new(data, client: @client)
      end

      # Cancel a subscription.
      #
      # @param id [String] Subscription ID
      # @return [Subscription] The canceled subscription
      # @note Subscription remains active until end of current period
      def cancel_subscription(id)
        data = @client.delete("/billing/subscriptions/#{id}")
        Subscription.new(data, client: @client)
      end

      # ============================================================
      # ENTITLEMENTS
      # ============================================================

      # Check if a customer has access to a feature.
      #
      # @param customer_id [String] Customer ID
      # @param entitlement_key [String] Feature key (e.g., "api_access")
      # @return [EntitlementCheck] Result with has_access, value, plan_name
      #
      # @example
      #   result = client.billing.check_entitlement(
      #     customer_id: "cus_xxx",
      #     entitlement_key: "api_requests"
      #   )
      #   if result.allowed?
      #     puts "Limit: #{result.value}"
      #   end
      #
      def check_entitlement(customer_id:, entitlement_key:)
        data = @client.post("/billing/entitlements/check", {
          customer_id: customer_id,
          entitlement_key: entitlement_key
        })
        EntitlementCheck.new(data, client: @client)
      end

      # ============================================================
      # USAGE
      # ============================================================

      # Record usage for a metered subscription.
      #
      # @param subscription_id [String] Subscription ID
      # @param quantity [Integer] Usage quantity to record
      # @param timestamp [Time, nil] When the usage occurred (defaults to now)
      # @param idempotency_key [String, nil] Unique key to prevent duplicates
      # @return [UsageRecord] The usage record
      #
      # @example
      #   record = client.billing.record_usage(
      #     subscription_id: "sub_xxx",
      #     quantity: 100,
      #     idempotency_key: "usage-2024-01-15-batch1"
      #   )
      #
      def record_usage(subscription_id:, quantity:, timestamp: nil, idempotency_key: nil)
        body = { subscription_id: subscription_id, quantity: quantity }
        body[:timestamp] = timestamp.iso8601 if timestamp
        body[:idempotency_key] = idempotency_key if idempotency_key

        data = @client.post("/billing/usage", body)
        UsageRecord.new(data, client: @client)
      end

      # Get aggregated usage for a subscription.
      #
      # @param subscription_id [String] Subscription ID
      # @return [UsageSummary] Usage summary with total_usage, period_start, period_end
      def get_usage_summary(subscription_id:)
        data = @client.get("/billing/usage", { subscription_id: subscription_id })
        UsageSummary.new(data, client: @client)
      end

      # ============================================================
      # PORTAL
      # ============================================================

      # Create a portal link for customer self-service.
      #
      # @param customer_id [String] Customer ID
      # @param expires_in_hours [Integer] Hours until link expires (default: 24)
      # @return [PortalLink] The portal link with url, token, expires_at
      #
      # @example
      #   link = client.billing.create_portal_link(customer_id: "cus_xxx")
      #   redirect_to link.url
      #
      def create_portal_link(customer_id:, expires_in_hours: 24)
        data = @client.post("/billing/customers/#{customer_id}/portal-link", {
          expires_in_hours: expires_in_hours
        })
        PortalLink.new(data, client: @client)
      end

      private

      def fetch_customers_page(limit:, cursor:)
        params = {}
        params[:limit] = limit if limit
        params[:cursor] = cursor if cursor

        data = @client.get("/billing/customers", params)

        customers = (data["customers"] || []).map do |c|
          Customer.new(c, client: @client)
        end

        List.new(
          data: customers,
          total: data["total"] || 0,
          next_cursor: data["next_cursor"],
          client: @client,
          fetch_page: ->(next_cursor) { fetch_customers_page(limit: limit, cursor: next_cursor) }
        )
      end
    end
  end
end
