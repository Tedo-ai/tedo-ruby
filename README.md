# Tedo Ruby SDK

Official Ruby client for the [Tedo API](https://tedo.ai/docs).

## Installation

Add to your Gemfile:

```ruby
gem "tedo"
```

Or install directly:

```bash
gem install tedo
```

## Quick Start

```ruby
require "tedo"

client = Tedo::Client.new("tedo_live_xxx")

# Billing: create a customer and subscribe
customer = client.billing.create_customer(
  email: "user@example.com",
  name: "Acme Corp"
)
subscription = customer.subscribe(price_id: "price_xxx")
puts "Active? #{subscription.active?}"

# Sales: set up a pipeline and capture a lead
pipeline = client.sales.create_pipeline(name: "B2B Sales", resource_type: Tedo::ResourceType::LEAD)
stage    = client.sales.create_stage(pipeline.id, name: "New",   position: 1)
won      = client.sales.create_stage(pipeline.id, name: "Won",   position: 2,
                                     is_terminal: true, outcome: Tedo::StageOutcome::POSITIVE)

lead = client.sales.create_lead(label: "Acme Inquiry", pipeline_id: pipeline.id, source: "website")
lead.move_stage(stage_id: won.id)

# Projects: create a project and work item
project = client.projects.create_project(name: "Q2 Launch")
work_item = client.projects.create_work_item(
  project_id: project.id,
  title: "Write launch checklist"
)
puts work_item.display_id

# Tables: create a table and query editorial rows
table = client.tables.create_table(name: "Editorial Pipeline")
client.tables.upsert_column(table.id, name: "Title", key: "title", type: "text")
client.tables.bulk_upsert_rows(
  table.id,
  key_column: "title",
  rows: [{ title: "Customer story" }]
)
rows = client.tables.query_rows(table.id, limit: 10)["rows"]
```

## Typed Resources

All API responses return typed Ruby objects with attribute accessors:

```ruby
customer = client.billing.get_customer("cus_xxx")

# Attribute accessors (not hash access)
customer.id           # => "cus_xxx"
customer.email        # => "user@example.com"
customer.name         # => "Acme Corp"
customer.created_at   # => Time object

# Related resources
customer.subscriptions.each do |sub|
  puts "#{sub.id}: #{sub.status}"
end

# Methods on resources
customer.update(name: "New Name")
customer.delete

# Predicate methods
subscription.active?    # => true
subscription.canceled?  # => false
subscription.past_due?  # => false

# Portal links
link = customer.create_portal_link
puts link.url           # => "https://billing.tedo.ai/portal/..."
puts link.expired?      # => false
```

## Configuration

### Global Configuration

```ruby
Tedo.configure do |config|
  config.api_key = "tedo_live_xxx"
  config.base_url = "https://api.tedo.ai"  # optional
end

# Then use the global client
customer = Tedo.billing.create_customer(email: "user@example.com")
pipeline = Tedo.sales.create_pipeline(name: "Enterprise", resource_type: "lead")
project = Tedo.projects.create_project(name: "Launch")
```

### Per-Client Configuration

```ruby
client = Tedo::Client.new(
  "tedo_live_xxx",
  base_url: "https://api.staging.tedo.ai"
)
```

Resource methods include their app and API version in the path. Configure the
API origin only; do not append `/v1` to `base_url`.

## Billing ledger and period composition

Version 0.2 adds the server-contract-tested financial slice used by the
Bidvise integration. These methods use integer cents excluding tax and require
the caller to provide the durable idempotency key.

```ruby
record = client.billing.record_billable_usage(
  subscription_id: "sub_xxx",
  product_key: "auction_commission",
  amount_excluding_tax_cents: 4_250,
  currency: "EUR",
  occurred_at: "2026-09-18T14:30:00+02:00",
  metadata: { lot_id: "123" },
  idempotency_key: "bidvise:lot:123:commission:v1"
)

client.billing.list_billable_usage(
  customer_id: "cus_xxx",
  occurred_at_gte: "2026-09-01T00:00:00+02:00",
  occurred_at_lt: "2026-10-01T00:00:00+02:00",
  limit: 100
).auto_paging_each do |usage|
  puts "#{usage.idempotency_key}: #{usage.state} #{usage.charge_id}"
end

result = client.billing.compose_customer_period_charge(
  customer_id: "cus_xxx",
  subscription_id: "sub_xxx",
  period_start: "2026-09-01T00:00:00+02:00",
  period_end: "2026-10-01T00:00:00+02:00",
  timezone: "Europe/Amsterdam",
  external_period_key: "bidvise:customer:42:2026-09",
  idempotency_key: "bidvise:customer:42:2026-09:compose:v1"
)
puts result.charge.id
```

The cursor is opaque. `auto_paging_each` passes it back unchanged together with
the original customer and half-open period.

### Safe retries

Retries are opt-in and bounded:

```ruby
client = Tedo::Client.new(
  ENV.fetch("TEDO_API_KEY"),
  max_retries: 2
)
```

GET requests may be retried. A POST/PATCH/PUT is retried only when it carries
an `Idempotency-Key`; every attempt reuses the identical key and JSON body.
Unsafe legacy writes without a key are never retried automatically.

## Pagination

### Auto-Pagination (Recommended)

Iterate through all pages automatically:

```ruby
# Process all customers one at a time
client.billing.list_customers.auto_paging_each do |customer|
  puts customer.email
end

# Collect all customers (use with caution on large datasets)
all_customers = client.billing.list_customers.auto_paging_to_a

# Use Enumerator methods
emails = client.billing.list_customers
              .auto_paging_each
              .map(&:email)
              .take(100)

# Projects lists also expose a lazy enumerator across cursor pages
first_twenty = client.projects.list_work_items.lazy.first(20)
```

### Manual Pagination

```ruby
list = client.billing.list_customers(limit: 10)

# Iterate current page
list.each { |customer| puts customer.email }

# Pagination info
puts "Total: #{list.total}"
puts "This page: #{list.count}"
puts "Has more: #{list.has_more?}"

# Get next page
if list.has_more?
  next_page = list.next_page
end
```

## Error Handling

All errors inherit from `Tedo::Error` with useful attributes:

```ruby
begin
  customer = client.billing.get_customer("cus_nonexistent")
rescue Tedo::NotFoundError => e
  puts "Customer not found: #{e.message}"
  puts "HTTP status: #{e.http_status}"  # => 404
rescue Tedo::ValidationError => e
  puts "Validation error: #{e.message}"
  puts "Field: #{e.field}"              # => "email"
  puts "Code: #{e.code}"                # => "invalid_email"
rescue Tedo::AuthenticationError => e
  puts "Invalid API key"
rescue Tedo::RateLimitError => e
  puts "Rate limited, slow down!"
rescue Tedo::ConflictError => e
  puts "Idempotency or domain conflict: #{e.code}"
rescue Tedo::TransientError => e
  puts "Safe to retry unchanged: #{e.code}"
rescue Tedo::PermissionError => e
  puts "Not authorized for this action"
rescue Tedo::APIError => e
  puts "Server error: #{e.message}"
rescue Tedo::Error => e
  puts "Unknown error: #{e.message}"
end
```

## Services

### Billing

| Method | Returns | Description |
|--------|---------|-------------|
| `create_customer(email:, name:, ...)` | `Customer` | Create a new customer |
| `get_customer(id)` | `Customer` | Get a customer by ID |
| `list_customers(limit:, cursor:)` | `List<Customer>` | List all customers |
| `update_customer(id, email:, name:, ...)` | `Customer` | Update a customer |
| `delete_customer(id)` | `nil` | Delete a customer |
| `create_subscription(customer_id:, price_id:, ...)` | `Subscription` | Create a subscription |
| `get_subscription(id)` | `Subscription` | Get a subscription |
| `cancel_subscription(id)` | `Subscription` | Cancel a subscription |
| `check_entitlement(customer_id:, entitlement_key:)` | `EntitlementCheck` | Check feature access |
| `record_usage(subscription_id:, quantity:, ...)` | `UsageRecord` | Record metered usage |
| `get_usage_summary(subscription_id:)` | `UsageSummary` | Get usage summary |
| `create_portal_link(customer_id:, expires_in_hours:)` | `PortalLink` | Create self-service portal link |

**Resource methods:**

```ruby
# Customer methods
customer.update(name: "New Name")
customer.delete
customer.subscribe(price_id: "price_xxx")
customer.entitled?("feature_key")
customer.check_entitlement("feature_key")
customer.create_portal_link

# Subscription methods
subscription.cancel
subscription.record_usage(quantity: 100)
subscription.usage_summary
```

### Sales

The Sales service covers the full CRM lifecycle: pipelines, stages, leads, deals, activities, notes, and contacts (persons and organizations).

### Projects

The Projects service covers projects, work items, workflow configuration, comments, activity, and file-reference attachments.

```ruby
project = client.projects.create_project(name: "Q2 Launch")

todo = client.projects.create_work_item(
  project_id: project.id,
  title: "Draft announcement",
  priority: Tedo::PROJECT_PRIORITY_MEDIUM,
  idempotency_key: "launch-draft-announcement"
)

client.projects.list_work_items(project_id: project.id).lazy.first(20).each do |item|
  puts "#{item.display_id}: #{item.title}"
end

client.projects.attach_file(
  todo.id,
  file_id: "file_xxx",
  display_name: "Brief.pdf"
)
```

#### Pipelines and Stages

```ruby
# Create a pipeline for leads
pipeline = client.sales.create_pipeline(
  name: "Inbound",
  resource_type: Tedo::ResourceType::LEAD  # "lead" or "deal"
)

# Add stages
client.sales.create_stage(pipeline.id, name: "New",       position: 1)
client.sales.create_stage(pipeline.id, name: "Qualified", position: 2)
client.sales.create_stage(pipeline.id, name: "Won",       position: 3,
                          is_terminal: true,
                          outcome: Tedo::StageOutcome::POSITIVE)
client.sales.create_stage(pipeline.id, name: "Lost",      position: 4,
                          is_terminal: true,
                          outcome: Tedo::StageOutcome::NEGATIVE)
```

#### Leads

```ruby
# Create a lead
lead = client.sales.create_lead(
  label:       "Acme Corp Inquiry",
  pipeline_id: pipeline.id,
  source:      "website"
)

# Move through stages
client.sales.move_lead_stage(lead.id, stage_id: qualified_stage.id)

# Convert to a deal
deal = client.sales.convert_lead_to_deal(
  lead.id,
  deal_pipeline_id: deal_pipeline.id,
  deal_stage_id:    deal_stage.id,
  value:            50_000,
  currency:         "EUR"
)

# List leads filtered by pipeline
leads = client.sales.list_leads(pipeline_id: pipeline.id)
```

#### Deals

```ruby
deal = client.sales.create_deal(
  label:               "Enterprise License",
  pipeline_id:         deal_pipeline.id,
  value:               120_000,
  currency:            "USD",
  expected_close_date: Date.new(2026, 6, 30)  # accepts Date objects
)

client.sales.move_deal_stage(deal.id, stage_id: next_stage.id)
client.sales.update_deal(deal.id, value: 135_000)
```

Date fields (`expected_close_date`, `due_date`) accept ISO 8601 strings or Ruby `Date`/`Time` objects.

#### Activities

Activities are tracked tasks, calls, emails, meetings, and deadlines. Use `Tedo::ActivityType` constants and `Tedo::Link` helpers to attach them to leads, deals, persons, or organizations.

```ruby
activity = client.sales.create_activity(
  type:             Tedo::ActivityType::CALL,
  subject:          "Discovery call with Acme",
  due_date:         Date.today + 3,
  due_time:         "14:00",
  duration_minutes: 30,
  links: [
    Tedo::Link.deal(deal.id),
    Tedo::Link.person(person.id, primary: false)
  ]
)

# Mark complete (or undo with completed: false)
client.sales.complete_activity(activity.id)
```

**`Tedo::ActivityType` constants:**

| Constant | Value |
|----------|-------|
| `Tedo::ActivityType::TASK` | `"task"` |
| `Tedo::ActivityType::CALL` | `"call"` |
| `Tedo::ActivityType::EMAIL` | `"email"` |
| `Tedo::ActivityType::MEETING` | `"meeting"` |
| `Tedo::ActivityType::DEADLINE` | `"deadline"` |

**`Tedo::Link` helpers:**

| Helper | Default `is_primary` | Description |
|--------|---------------------|-------------|
| `Tedo::Link.lead(id)` | `true` | Link to a lead |
| `Tedo::Link.deal(id)` | `true` | Link to a deal |
| `Tedo::Link.person(id)` | `false` | Link to a person |
| `Tedo::Link.organization(id)` | `false` | Link to an organization |

Pass `primary: true/false` to override the default.

#### Notes

```ruby
note = client.sales.create_note(
  content: "Discussed pricing. Follow up next week.",
  links:   [Tedo::Link.deal(deal.id)]
)

client.sales.update_note(note.id, content: "Updated summary.")
client.sales.list_notes(deal_id: deal.id)
```

#### Persons and Organizations

Persons and organizations live inside a **contact base** — a named collection of contacts.

```ruby
# List contact bases (each workspace has a default one)
bases = client.sales.list_contact_bases
base_id = bases.first.id

person = client.sales.create_person(
  base_id,
  first_name:   "Jane",
  last_name:    "Doe",
  email:        "jane@acme.com",
  phone:        "+1-555-0100",
  linkedin_url: "https://linkedin.com/in/janedoe"
)

org = client.sales.create_organization(
  base.id,
  name:    "Acme Corp",
  website: "https://acme.com"
)

# Attach to a lead
client.sales.update_lead(lead.id, person_id: person.id, organization_id: org.id)
```

#### Full Sales Method Reference

**Pipelines**

| Method | Returns | Description |
|--------|---------|-------------|
| `create_pipeline(name:, resource_type:)` | `Pipeline` | Create a pipeline |
| `list_pipelines` | `Array<Pipeline>` | List all pipelines |
| `get_pipeline(id)` | `Pipeline` | Get a pipeline by ID |
| `update_pipeline(id, name:)` | `Pipeline` | Rename a pipeline |
| `delete_pipeline(id)` | `nil` | Delete a pipeline |

**Stages**

| Method | Returns | Description |
|--------|---------|-------------|
| `create_stage(pipeline_id, name:, position:, is_terminal:, outcome:)` | `PipelineStage` | Add a stage to a pipeline |
| `list_stages(pipeline_id)` | `Array<PipelineStage>` | List stages for a pipeline |
| `get_stage(id)` | `PipelineStage` | Get a stage by ID |
| `update_stage(id, name:, position:, is_terminal:, outcome:)` | `PipelineStage` | Update a stage |
| `delete_stage(id)` | `nil` | Delete a stage |

**Leads**

| Method | Returns | Description |
|--------|---------|-------------|
| `create_lead(label:, pipeline_id:, person_id:, organization_id:, source:)` | `Lead` | Create a lead |
| `list_leads(pipeline_id:)` | `Array<Lead>` | List leads, optionally filtered |
| `get_lead(id)` | `Lead` | Get a lead by ID |
| `update_lead(id, label:, person_id:, organization_id:, source:)` | `Lead` | Update a lead |
| `delete_lead(id)` | `nil` | Delete a lead |
| `move_lead_stage(id, stage_id:)` | `Lead` | Move lead to a stage |
| `convert_lead_to_deal(id, deal_pipeline_id:, deal_stage_id:, deal_label:, value:, currency:)` | `Deal` | Convert lead to deal |

**Deals**

| Method | Returns | Description |
|--------|---------|-------------|
| `create_deal(label:, pipeline_id:, person_id:, organization_id:, value:, currency:, expected_close_date:)` | `Deal` | Create a deal |
| `list_deals(pipeline_id:)` | `Array<Deal>` | List deals, optionally filtered |
| `get_deal(id)` | `Deal` | Get a deal by ID |
| `update_deal(id, label:, person_id:, organization_id:, value:, currency:, expected_close_date:)` | `Deal` | Update a deal |
| `delete_deal(id)` | `nil` | Delete a deal |
| `move_deal_stage(id, stage_id:)` | `Deal` | Move deal to a stage |

**Activities**

| Method | Returns | Description |
|--------|---------|-------------|
| `create_activity(type:, subject:, description:, due_date:, due_time:, duration_minutes:, assigned_to_id:, links:)` | `Activity` | Create an activity |
| `list_activities(lead_id:, deal_id:, type:)` | `Array<Activity>` | List activities, optionally filtered |
| `get_activity(id)` | `Activity` | Get an activity by ID |
| `update_activity(id, subject:, description:, due_date:, due_time:, duration_minutes:)` | `Activity` | Update an activity |
| `delete_activity(id)` | `nil` | Delete an activity |
| `complete_activity(id, completed:)` | `Activity` | Mark activity complete or incomplete |

**Notes**

| Method | Returns | Description |
|--------|---------|-------------|
| `create_note(content:, author_id:, links:)` | `Note` | Create a note |
| `list_notes(lead_id:, deal_id:)` | `Array<Note>` | List notes, optionally filtered |
| `get_note(id)` | `Note` | Get a note by ID |
| `update_note(id, content:)` | `Note` | Update a note |
| `delete_note(id)` | `nil` | Delete a note |

**Contact Bases**

| Method | Returns | Description |
|--------|---------|-------------|
| `create_contact_base(name:)` | `ContactBase` | Create a new contact base |
| `list_contact_bases` | `Array<ContactBase>` | List all contact bases |
| `get_contact_base(id)` | `ContactBase` | Get a contact base by ID |

**Persons**

| Method | Returns | Description |
|--------|---------|-------------|
| `create_person(contact_base_id, first_name:, last_name:, email:, phone:, linkedin_url:)` | `Person` | Create a person |
| `list_persons(contact_base_id)` | `Array<Person>` | List persons in a contact base |
| `get_person(id)` | `Person` | Get a person by ID |
| `update_person(id, full_name:, first_name:, last_name:, email:, phone:, linkedin_url:)` | `Person` | Update a person |
| `delete_person(id)` | `nil` | Delete a person |

**Organizations**

| Method | Returns | Description |
|--------|---------|-------------|
| `create_organization(contact_base_id, name:, website:, linkedin_url:)` | `Organization` | Create an organization |
| `list_organizations(contact_base_id)` | `Array<Organization>` | List organizations in a contact base |
| `get_organization(id)` | `Organization` | Get an organization by ID |
| `update_organization(id, name:, website:, linkedin_url:)` | `Organization` | Update an organization |
| `delete_organization(id)` | `nil` | Delete an organization |

## Rails Integration

```ruby
# config/initializers/tedo.rb
Tedo.configure do |config|
  config.api_key = Rails.application.credentials.tedo_api_key
end
```

```ruby
# app/services/billing_service.rb
class BillingService
  def provision_customer(user)
    customer = Tedo.billing.create_customer(
      email: user.email,
      name: user.full_name,
      external_id: user.id.to_s
    )

    # Store the Tedo customer ID
    user.update!(tedo_customer_id: customer.id)

    customer
  end

  def entitled?(user, feature)
    return false unless user.tedo_customer_id

    Tedo.billing
        .get_customer(user.tedo_customer_id)
        .entitled?(feature)
  end
end
```

```ruby
# app/services/sales_service.rb
class SalesService
  def capture_lead(name:, email:, pipeline_id:, source: "website")
    base = Tedo.sales.list_contact_bases.first

    person = Tedo.sales.create_person(
      base.id,
      first_name: name.split.first,
      last_name:  name.split.last,
      email:      email
    )

    lead = Tedo.sales.create_lead(
      label:       name,
      pipeline_id: pipeline_id,
      person_id:   person.id,
      source:      source
    )

    Tedo.sales.create_activity(
      type:    Tedo::ActivityType::EMAIL,
      subject: "Send welcome email",
      due_date: Date.today,
      links:   [Tedo::Link.lead(lead.id)]
    )

    lead
  end
end
```

## License

MIT
