# frozen_string_literal: true

module Tedo
  # Main client for the Tedo API
  class Client
    attr_reader :api_key, :base_url

    def initialize(api_key = nil, base_url: nil, http_client: nil, **kwargs)
      api_key = kwargs[:api_key] if api_key.nil? && kwargs.key?(:api_key)
      @api_key = api_key
      @base_url = base_url || Tedo.base_url
      @http_client = http_client
      @retry = kwargs[:retry]
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
      response = connection.public_send(method, path) do |req|
        req.headers.update(headers) if headers && !headers.empty?
        req.body = body.to_json if body && [:post, :patch].include?(method)
        req.params = body if body && method == :get
      end

      handle_response(response)
    end

    def connection
      return @http_client if @http_client

      @connection ||= Faraday.new(url: base_url) do |f|
        f.request :json
        f.response :json
        f.request :retry if @retry
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
        retry_after: retry_after
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
      when "rate_limited" then RateLimitError
      else
        case status
        when 400 then ValidationError
        when 401 then AuthenticationError
        when 403 then PermissionError
        when 404 then NotFoundError
        when 429 then RateLimitError
        else APIError
        end
      end
    end
  end
end
