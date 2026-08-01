# frozen_string_literal: true

require "spec_helper"

RSpec.describe Tedo::Resources::Billing do
  BillingFakeResponse = Struct.new(:status, :body, :headers, keyword_init: true) do
    def success?
      status >= 200 && status < 300
    end
  end

  BillingFakeRequest = Struct.new(:body, :params, :headers, keyword_init: true)

  class BillingFakeHTTP
    attr_reader :requests

    def initialize(&handler)
      @handler = handler
      @requests = []
    end

    %i[get post patch delete].each do |method_name|
      define_method(method_name) do |path, &block|
        request = BillingFakeRequest.new(body: nil, params: {}, headers: {})
        block.call(request) if block
        @requests << [method_name, path, request]
        @handler.call(method_name, path, request, @requests.length)
      end
    end
  end

  def billing_response(status, body, headers: {})
    BillingFakeResponse.new(status: status, body: body, headers: headers)
  end

  def billing_client(max_retries: 0, sleeper: ->(_seconds) {}, &handler)
    http = BillingFakeHTTP.new(&handler)
    client = Tedo::Client.new(
      api_key: "tedo_live_test",
      base_url: "https://api.test",
      http_client: http,
      max_retries: max_retries,
      retry_base_delay: 0,
      sleeper: sleeper
    )
    [client, http]
  end

  def usage_record(id: "usage-1", state: "pending")
    {
      "id" => id,
      "idempotency_key" => "bidvise:lot:123:commission:v1",
      "customer_id" => "customer-1",
      "subscription_id" => "subscription-1",
      "product_key" => "auction_commission",
      "amount_excluding_tax_cents" => 4250,
      "currency" => "EUR",
      "occurred_at" => "2026-09-18T12:30:00Z",
      "recorded_at" => "2026-09-19T00:03:00Z",
      "metadata" => { "lot_id" => "123" },
      "state" => state,
      "reversal_of" => nil,
      "applied_period_start" => nil,
      "applied_period_end" => nil,
      "charge_id" => nil,
      "invoice_id" => nil
    }
  end

  def composition_result(mode: "automatic")
    charge = if mode == "automatic"
               {
                 "id" => "charge-1",
                 "customer_id" => "customer-1",
                 "subscription_id" => "subscription-1",
                 "status" => "open",
                 "currency" => "EUR",
                 "subtotal" => 14_150,
                 "tax" => 0,
                 "total" => 14_150,
                 "amount_paid" => 0,
                 "amount_due" => 14_150,
                 "lines" => [],
                 "metadata" => {},
                 "created_at" => "2026-10-01T00:03:00Z"
               }
             end
    {
      "composition" => {
        "id" => "composition-1",
        "customer_id" => "customer-1",
        "subscription_id" => mode == "automatic" ? "subscription-1" : nil,
        "period_start" => "2026-08-31T22:00:00Z",
        "period_end" => "2026-09-30T22:00:00Z",
        "timezone" => "Europe/Amsterdam",
        "external_period_key" => "bidvise:customer:42:2026-09",
        "mode" => mode,
        "currency" => mode == "automatic" ? "EUR" : nil,
        "usage_record_count" => mode == "automatic" ? 1 : 0,
        "usage_amount_excluding_tax_cents" => mode == "automatic" ? 4250 : 0,
        "subscription_amount_excluding_tax_cents" => mode == "automatic" ? 9900 : 0,
        "total_amount_excluding_tax_cents" => mode == "automatic" ? 14_150 : 0,
        "charge_id" => mode == "automatic" ? "charge-1" : nil,
        "invoice_id" => nil,
        "reason" => mode == "manual" ? "August billed manually" : nil,
        "created_at" => "2026-10-01T00:03:00Z"
      },
      "charge" => charge,
      "usage_record_ids" => mode == "automatic" ? ["usage-1"] : [],
      "already_existed" => false
    }
  end

  it "exposes every Ruby method pinned by the generated Billing contract" do
    fixture = JSON.parse(File.read(File.join(__dir__, "fixtures", "billing_ledger_contract.json")))

    expect(fixture.fetch("endpoints").map { |endpoint| endpoint.fetch("ruby_method") }.sort).to eq(
      %w[
        close_customer_period_manually
        compose_customer_period_charge
        list_billable_usage
        record_billable_usage
      ]
    )
    fixture.fetch("endpoints").each do |endpoint|
      expect(client_method_names).to include(endpoint.fetch("ruby_method"))
    end
  end

  it "uses the API origin because resource paths include app and version" do
    expect(Tedo.base_url).to eq("https://api.tedo.ai")
  end

  it "records an immutable usage fact with the caller-provided idempotency key" do
    client, http = billing_client do |method, path, request, _count|
      expect(method).to eq(:post)
      expect(path).to eq("/billing/v1/usage-records")
      expect(request.headers["Idempotency-Key"]).to eq("bidvise:lot:123:commission:v1")
      expect(JSON.parse(request.body)).to eq(
        "subscription_id" => "subscription-1",
        "product_key" => "auction_commission",
        "amount_excluding_tax_cents" => 4250,
        "currency" => "EUR",
        "occurred_at" => "2026-09-18T14:30:00+02:00",
        "metadata" => { "lot_id" => "123" }
      )
      billing_response(201, usage_record)
    end

    record = client.billing.record_billable_usage(
      subscription_id: "subscription-1",
      product_key: "auction_commission",
      amount_excluding_tax_cents: 4250,
      currency: "EUR",
      occurred_at: "2026-09-18T14:30:00+02:00",
      metadata: { "lot_id" => "123" },
      idempotency_key: "bidvise:lot:123:commission:v1"
    )

    expect(record).to be_a(Tedo::BillableUsageRecord)
    expect(record.amount_excluding_tax_cents).to eq(4250)
    expect(record).to be_pending
    expect(http.requests.length).to eq(1)
  end

  it "requires callers to own every financial idempotency key" do
    client, = billing_client { billing_response(201, usage_record) }

    expect do
      client.billing.record_billable_usage(
        subscription_id: "subscription-1",
        product_key: "auction_commission",
        amount_excluding_tax_cents: 4250,
        currency: "EUR",
        occurred_at: "2026-09-18T14:30:00+02:00",
        idempotency_key: ""
      )
    end.to raise_error(ArgumentError, "idempotency_key is required")
  end

  it "resumes cursor pagination with the original customer and half-open period" do
    client, http = billing_client do |method, path, request, count|
      expect(method).to eq(:get)
      expect(path).to eq("/billing/v1/customers/customer-1/usage-records")
      expected = {
        occurred_at_gte: "2026-09-01T00:00:00+02:00",
        occurred_at_lt: "2026-10-01T00:00:00+02:00",
        limit: 1
      }
      expected[:cursor] = "opaque-page-2" if count == 2
      expect(request.params).to eq(expected)
      billing_response(200, {
        "records" => [usage_record(id: "usage-#{count}")],
        "next_cursor" => count == 1 ? "opaque-page-2" : nil,
        "has_more" => count == 1,
        "occurred_at_gte" => "2026-08-31T22:00:00Z",
        "occurred_at_lt" => "2026-09-30T22:00:00Z"
      })
    end

    ids = client.billing.list_billable_usage(
      customer_id: "customer-1",
      occurred_at_gte: "2026-09-01T00:00:00+02:00",
      occurred_at_lt: "2026-10-01T00:00:00+02:00",
      limit: 1
    ).auto_paging_each.map(&:id)

    expect(ids).to eq(%w[usage-1 usage-2])
    expect(http.requests.length).to eq(2)
  end

  it "wraps automatic composition and manual closure responses consistently" do
    client, = billing_client do |_method, path, request, _count|
      expect(request.headers["Idempotency-Key"]).not_to be_empty
      if path.end_with?("period-charges")
        expect(path).to eq("/billing/v1/customers/customer-1/period-charges")
        expect(JSON.parse(request.body)["external_period_key"]).to eq("bidvise:customer:42:2026-09")
        billing_response(200, composition_result)
      else
        expect(path).to eq("/billing/v1/customers/customer-1/period-closures")
        expect(JSON.parse(request.body)).to include(
          "reason" => "August billed manually",
          "charge_id" => "charge-august"
        )
        billing_response(200, composition_result(mode: "manual"))
      end
    end

    composed = client.billing.compose_customer_period_charge(
      customer_id: "customer-1",
      subscription_id: "subscription-1",
      period_start: "2026-09-01T00:00:00+02:00",
      period_end: "2026-10-01T00:00:00+02:00",
      timezone: "Europe/Amsterdam",
      external_period_key: "bidvise:customer:42:2026-09",
      idempotency_key: "bidvise:customer:42:2026-09:compose:v1"
    )
    expect(composed.composition).to be_automatic
    expect(composed.charge.total).to eq(14_150)
    expect(composed.usage_record_ids).to eq(["usage-1"])
    expect(composed).not_to be_already_existed

    closed = client.billing.close_customer_period_manually(
      customer_id: "customer-1",
      period_start: "2026-08-01T00:00:00+02:00",
      period_end: "2026-09-01T00:00:00+02:00",
      timezone: "Europe/Amsterdam",
      external_period_key: "bidvise:customer:42:2026-08",
      reason: "August billed manually",
      charge_id: "charge-august",
      idempotency_key: "bidvise:customer:42:2026-08:manual:v1"
    )
    expect(closed.composition).to be_manual
    expect(closed.charge).to be_nil
  end

  it "raises a typed conflict for canonical idempotency mismatches" do
    client, = billing_client do
      billing_response(409, {
        "code" => "idempotency_conflict",
        "message" => "Idempotency-Key is already bound to a different payload",
        "details" => { "field" => "Idempotency-Key" },
        "request_id" => "request-1"
      })
    end

    expect do
      client.billing.record_billable_usage(
        subscription_id: "subscription-1",
        product_key: "auction_commission",
        amount_excluding_tax_cents: 4250,
        currency: "EUR",
        occurred_at: "2026-09-18T14:30:00+02:00",
        idempotency_key: "bidvise:lot:123:commission:v1"
      )
    end.to raise_error(Tedo::ConflictError) { |error|
      expect(error).to be_conflict
      expect(error).not_to be_transient
      expect(error.request_id).to eq("request-1")
    }
  end

  it "retries transient financial writes with the identical key and body" do
    client, http = billing_client(max_retries: 1) do |_method, _path, _request, count|
      if count == 1
        billing_response(503, { "code" => "temporarily_unavailable", "message" => "try again" })
      else
        billing_response(201, usage_record)
      end
    end

    record = client.billing.record_billable_usage(
      subscription_id: "subscription-1",
      product_key: "auction_commission",
      amount_excluding_tax_cents: 4250,
      currency: "EUR",
      occurred_at: "2026-09-18T14:30:00+02:00",
      idempotency_key: "bidvise:lot:123:commission:v1"
    )

    expect(record.id).to eq("usage-1")
    expect(http.requests.length).to eq(2)
    expect(http.requests.map { |_method, _path, request| request.headers["Idempotency-Key"] }.uniq)
      .to eq(["bidvise:lot:123:commission:v1"])
    expect(http.requests.map { |_method, _path, request| request.body }.uniq.length).to eq(1)
  end

  it "does not retry an unsafe POST without an idempotency key" do
    client, http = billing_client(max_retries: 2) do
      billing_response(503, { "code" => "temporarily_unavailable", "message" => "try again" })
    end

    expect { client.post("/billing/v1/legacy-write", { amount: 1 }) }
      .to raise_error(Tedo::ServerError) { |error| expect(error).to be_transient }
    expect(http.requests.length).to eq(1)
  end

  def client_method_names
    described_class.public_instance_methods(false).map(&:to_s)
  end
end
