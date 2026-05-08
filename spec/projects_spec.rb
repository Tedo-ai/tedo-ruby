# frozen_string_literal: true

require "spec_helper"

RSpec.describe Tedo::Resources::Projects do
  FakeResponse = Struct.new(:status, :body, :headers, keyword_init: true) do
    def success?
      status >= 200 && status < 300
    end
  end

  FakeRequest = Struct.new(:body, :params, :headers, keyword_init: true)

  class FakeHTTP
    attr_reader :requests

    def initialize(&handler)
      @handler = handler
      @requests = []
    end

    %i[get post patch delete].each do |method_name|
      define_method(method_name) do |path, &block|
        request = FakeRequest.new(body: nil, params: {}, headers: {})
        block.call(request) if block
        @requests << [method_name, path, request]
        @handler.call(method_name, path, request, @requests.length)
      end
    end
  end

  def json_response(status, body, headers: {})
    FakeResponse.new(status: status, body: body, headers: headers)
  end

  def client_with(&handler)
    http = FakeHTTP.new(&handler)
    [Tedo::Client.new(api_key: "tedo_live_test", base_url: "https://api.test", http_client: http), http]
  end

  it "initializes the Projects service from the client" do
    client, = client_with { json_response(200, {}) }

    expect(client.projects).to be_a(described_class)
  end

  it "sends generated idempotency keys as headers for required create commands" do
    client, http = client_with do |method, path, request, _count|
      expect(method).to eq(:post)
      expect(path).to eq("/projects/v1/projects")
      expect(request.headers["Idempotency-Key"]).to start_with("tedo_ruby_")

      body = JSON.parse(request.body)
      expect(body).to include("name" => "Launch")
      expect(body).not_to have_key("idempotency_key")

      json_response(
        201,
        {
          "id" => "proj-1",
          "name" => "Launch",
          "archived" => false,
          "created_at" => "2026-05-08T00:00:00Z",
          "updated_at" => "2026-05-08T00:00:00Z"
        }
      )
    end

    project = client.projects.create_project(name: "Launch")

    expect(project.id).to eq("proj-1")
    expect(http.requests.length).to eq(1)
  end

  it "allows callers to override idempotency and request IDs" do
    client, = client_with do |_method, path, request, _count|
      expect(path).to eq("/projects/v1/projects/proj-1")
      expect(request.headers["Idempotency-Key"]).to eq("idem_123")
      expect(request.headers["X-Request-ID"]).to eq("req_123")
      json_response(200, { "deleted" => true, "id" => "proj-1" })
    end

    result = client.projects.delete_project("proj-1", idempotency_key: "idem_123", request_id: "req_123")

    expect(result).to be_deleted
    expect(result.id).to eq("proj-1")
  end

  it "encodes Projects list filters with snake_case query names" do
    client, = client_with do |_method, path, request, _count|
      expect(path).to eq("/projects/v1/work-items")
      expect(request.params).to eq(
        project_id: "proj-1",
        status_id: "status-1",
        priority: 2,
        include_completed: true,
        include_archived: true,
        limit: 50,
        cursor: "eyJvZmZzZXQiOjUwfQ"
      )
      json_response(200, { "items" => [], "next_cursor" => nil, "has_more" => false })
    end

    list = client.projects.list_work_items(
      project_id: "proj-1",
      status_id: "status-1",
      priority: Tedo::PROJECT_PRIORITY_MEDIUM,
      include_completed: true,
      include_archived: true,
      limit: 50,
      cursor: "eyJvZmZzZXQiOjUwfQ"
    )

    expect(list).not_to have_more
  end

  it "lazily paginates cursor lists across pages" do
    client, http = client_with do |_method, _path, request, count|
      if count == 1
        expect(request.params).to eq(limit: 1)
        json_response(
          200,
          {
            "items" => [{ "id" => "proj-1", "name" => "One" }],
            "next_cursor" => "cursor-2",
            "has_more" => true
          }
        )
      else
        expect(request.params).to eq(limit: 1, cursor: "cursor-2")
        json_response(
          200,
          {
            "items" => [{ "id" => "proj-2", "name" => "Two" }],
            "next_cursor" => nil,
            "has_more" => false
          }
        )
      end
    end

    ids = client.projects.list_projects(limit: 1).lazy.first(2).map(&:id)

    expect(ids).to eq(%w[proj-1 proj-2])
    expect(http.requests.length).to eq(2)
  end

  it "uses the read-only comments endpoint" do
    client, = client_with do |method, path, _request, _count|
      expect(method).to eq(:get)
      expect(path).to eq("/projects/v1/work-items/work-1/comments")
      json_response(
        200,
        {
          "items" => [
            {
              "id" => "comment-1",
              "work_item_id" => "work-1",
              "actor_type" => "api_key",
              "actor_ref" => "api_key:key-1",
              "content" => "ready"
            }
          ],
          "has_more" => false
        }
      )
    end

    comments = client.projects.list_comments("work-1")

    expect(comments.first.actor_ref).to eq("api_key:key-1")
  end

  it "parses canonical Projects error envelopes" do
    client, = client_with do
      json_response(
        403,
        {
          "code" => "permission_denied",
          "message" => "API key lacks projects.projects.write",
          "details" => { "permission" => "projects.projects.write" },
          "request_id" => "req_123"
        }
      )
    end

    expect { client.projects.get_project("proj-1") }
      .to raise_error(Tedo::PermissionError) { |error|
        expect(error.code).to eq("permission_denied")
        expect(error.request_id).to eq("req_123")
        expect(error.details["permission"]).to eq("projects.projects.write")
      }
  end
end
