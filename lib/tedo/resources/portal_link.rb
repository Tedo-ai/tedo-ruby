# frozen_string_literal: true

module Tedo
  # A time-limited portal link for customer self-service.
  #
  # @example
  #   link = client.billing.create_portal_link(customer_id: "cus_xxx")
  #   link.url        # => "https://billing.tedo.ai/portal/..."
  #   link.expires_at # => Time
  #   link.expired?   # => false
  #
  class PortalLink < Resource
    attribute :portal_url
    attribute :token
    attribute :expires_at, type: :time

    # Alias for portal_url
    def url
      portal_url
    end

    # Check if the link has expired.
    #
    # @return [Boolean]
    def expired?
      expires_at && Time.now > expires_at
    end

    # Check if the link is still valid.
    #
    # @return [Boolean]
    def valid?
      !expired?
    end
  end
end
