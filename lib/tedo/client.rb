# frozen_string_literal: true

module Tedo
  # Main client for the Tedo API
  class Client
    attr_reader :api_key, :base_url

    def initialize(api_key, base_url: nil)
      @api_key = api_key
      @base_url = base_url || Tedo.base_url
    end

    # Service accessors
    def billing
      @billing ||= Resources::Billing.new(self)
    end

    # HTTP methods
    def get(path, params = {})
      request(:get, path, params)
    end

    def post(path, body = {})
      request(:post, path, body)
    end

    def patch(path, body = {})
      request(:patch, path, body)
    end

    def delete(path)
      request(:delete, path)
    end

    private

    def request(method, path, body = nil)
      response = connection.public_send(method, path) do |req|
        req.body = body.to_json if body && [:post, :patch].include?(method)
        req.params = body if body && method == :get
      end

      handle_response(response)
    end

    def connection
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

      error_body = response.body || {}
      message = error_body["message"] || "Unknown error"
      code = error_body["code"]
      field = error_body["field"]

      error_class = case response.status
                    when 400 then ValidationError
                    when 401 then AuthenticationError
                    when 403 then PermissionError
                    when 404 then NotFoundError
                    when 429 then RateLimitError
                    else APIError
                    end

      raise error_class.new(message, code: code, http_status: response.status, field: field)
    end
  end
end
