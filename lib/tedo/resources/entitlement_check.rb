# frozen_string_literal: true

module Tedo
  # Result of an entitlement check.
  #
  # @example
  #   result = client.billing.check_entitlement(
  #     customer_id: "cus_xxx",
  #     entitlement_key: "api_requests"
  #   )
  #   result.has_access  # => true
  #   result.value       # => "10000" (the limit)
  #   result.plan_name   # => "Pro"
  #
  class EntitlementCheck < Resource
    attribute :has_access
    attribute :value
    attribute :plan_name

    # Predicate for access check
    def allowed?
      has_access == true
    end

    alias entitled? allowed?
  end
end
