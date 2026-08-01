# frozen_string_literal: true

module Tedo
  # Base error class for all Tedo errors
  class Error < StandardError
    attr_reader :code, :http_status, :field, :details, :request_id, :retry_after, :response_body

    def initialize(message = nil, code: nil, http_status: nil, field: nil, details: nil, request_id: nil, retry_after: nil, response_body: nil)
      @code = code
      @http_status = http_status
      @field = field
      @details = details || {}
      @request_id = request_id
      @retry_after = retry_after
      @response_body = response_body
      super(message)
    end

    def transient?
      is_a?(TransientError)
    end

    def conflict?
      is_a?(ConflictError)
    end

    def permanent?
      !transient? && !conflict?
    end
  end

  # Raised when the API returns a 400 Bad Request
  class ValidationError < Error; end

  # Raised when the API returns a 401 Unauthorized
  class AuthenticationError < Error; end
  AuthError = AuthenticationError

  # Raised when the API returns a 403 Forbidden
  class PermissionError < Error; end

  # Raised when the API returns a 404 Not Found
  class NotFoundError < Error; end

  # Raised for a durable 409 conflict such as idempotency-key payload reuse.
  class ConflictError < Error; end

  # Base class for failures that may be retried without changing the request.
  class TransientError < Error; end

  # Raised when no HTTP response was received.
  class TransportError < TransientError; end

  # Raised when the API returns a 429 Too Many Requests
  class RateLimitError < TransientError; end

  # Raised for retryable 408/425/5xx responses after retries are exhausted.
  class ServerError < TransientError; end

  # Raised when the API returns a 5xx error
  class APIError < Error; end
end
