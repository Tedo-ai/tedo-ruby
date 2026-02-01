# frozen_string_literal: true

module Tedo
  # Base error class for all Tedo errors
  class Error < StandardError
    attr_reader :code, :http_status, :field

    def initialize(message = nil, code: nil, http_status: nil, field: nil)
      @code = code
      @http_status = http_status
      @field = field
      super(message)
    end
  end

  # Raised when the API returns a 400 Bad Request
  class ValidationError < Error; end

  # Raised when the API returns a 401 Unauthorized
  class AuthenticationError < Error; end

  # Raised when the API returns a 403 Forbidden
  class PermissionError < Error; end

  # Raised when the API returns a 404 Not Found
  class NotFoundError < Error; end

  # Raised when the API returns a 429 Too Many Requests
  class RateLimitError < Error; end

  # Raised when the API returns a 5xx error
  class APIError < Error; end
end
