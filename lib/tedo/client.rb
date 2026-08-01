# frozen_string_literal: true

module Tedo
  # Main client for the Tedo API
  class Client
    attr_reader :api_key, :base_url, :max_retries

    def initialize(api_key = nil, base_url: nil, http_client: nil, **kwargs)
      api_key = kwargs[:api_key] if api_key.nil? && kwargs.key?(:api_key)
      @api_key = api_key
      @base_url = base_url || Tedo.base_url
      @http_client = http_client
      @max_retries = if kwargs.key?(:max_retries)
                       Integer(kwargs[:max_retries])
                     elsif kwargs[:retry]
                       2
                     else
                       0
                     end
      raise ArgumentError, "max_retries must be non-negative" if @max_retries.negative?

      @retry_base_delay = Float(kwargs.fetch(:retry_base_delay, 0.25))
      @sleeper = kwargs.fetch(:sleeper, ->(seconds) { sleep(seconds) })
    end

    # Service accessors
    def billing
      @billing ||= Resources::Billing.new(self)
    end

    def sales
      @sales ||= Resources::Sales.new(self)
    end

    def projects
      @projects ||= Resources::Projects.new(self)
    end

    def tables
      @tables ||= Resources::Tables.new(self)
    end

    # HTTP methods
    def get(path, params = {}, headers: {})
      request(:get, path, params, headers: headers)
    end

    def post(path, body = {}, headers: {})
      request(:post, path, body, headers: headers)
    end

    def patch(path, body = {}, headers: {})
      request(:patch, path, body, headers: headers)
    end

    def delete(path, headers: {})
      request(:delete, path, nil, headers: headers)
    end

    private

    def request(method, path, body = nil, headers: {})
      request_headers = headers ? headers.dup : {}
      attempt = 0

      loop do
        begin
          response = connection.public_send(method, path) do |req|
            req.headers.update(request_headers) unless request_headers.empty?
            req.body = body.to_json if body && [:post, :patch, :put].include?(method)
            req.params = body if body && method == :get
          end
        rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
          if retry_request?(method, request_headers, attempt)
            wait_before_retry(nil, attempt)
            attempt += 1
            next
          end
          raise TransportError.new(e.message, code: "transport_error"), cause: e
        end

        if retryable_status?(response.status) && retry_request?(method, request_headers, attempt)
          wait_before_retry(response, attempt)
          attempt += 1
          next
        end

        return handle_response(response)
      end
    end

    def connection
      return @http_client if @http_client

      @connection ||= Faraday.new(url: base_url) do |f|
        f.request :json
        f.response :json
        f.headers["Authorization"] = "Bearer #{api_key}"
        f.headers["Content-Type"] = "application/json"
        f.headers["Accept"] = "application/json"
      end
    end

    def handle_response(response)
      return response.body if response.success?

      error_body = parsed_error_body(response.body)
      message = error_body["message"] || "Unknown error"
      code = error_body["code"]
      details = error_body["details"] || {}
      field = error_body["field"] || details["field"]
      request_id = error_body["request_id"] || response.headers["X-Request-ID"] || response.headers["x-request-id"]
      retry_after = response.headers["Retry-After"] || response.headers["retry-after"]

      error_class = error_class_for(response.status, code)

      raise error_class.new(
        message,
        code: code,
        http_status: response.status,
        field: field,
        details: details,
        request_id: request_id,
        retry_after: retry_after,
        response_body: response.body
      )
    end

    def parsed_error_body(body)
      return body if body.is_a?(Hash)
      return {} if body.nil? || body.to_s.empty?

      JSON.parse(body.to_s)
    rescue JSON::ParserError
      {}
    end

    def error_class_for(status, code)
      case code
      when "unauthorized" then AuthenticationError
      when "permission_denied", "app_unavailable" then PermissionError
      when "not_found" then NotFoundError
      when "validation_failed" then ValidationError
      when "idempotency_conflict" then ConflictError
      when "rate_limited" then RateLimitError
      else
        case status
        when 400 then ValidationError
        when 401 then AuthenticationError
        when 403 then PermissionError
        when 404 then NotFoundError
        when 408, 425 then ServerError
        when 409 then ConflictError
        when 429 then RateLimitError
        when 500..599 then ServerError
        else APIError
        end
      end
    end

    def retry_request?(method, headers, attempt)
      return false if attempt >= max_retries
      return true if [:get, :head, :options, :delete].include?(method)

      key = headers["Idempotency-Key"] || headers["idempotency-key"]
      !key.nil? && !key.to_s.empty?
    end

    def retryable_status?(status)
      [408, 425, 429, 500, 502, 503, 504].include?(status.to_i)
    end

    def wait_before_retry(response, attempt)
      retry_after = response && (response.headers["Retry-After"] || response.headers["retry-after"])
      delay = begin
        Float(retry_after)
      rescue ArgumentError, TypeError
        @retry_base_delay * (2**attempt)
      end
      @sleeper.call(delay) if delay.positive?
    end
  end
end
