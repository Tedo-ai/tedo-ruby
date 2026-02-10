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

# Create a customer
customer = client.billing.create_customer(
  email: "user@example.com",
  name: "Acme Corp"
)
puts "Created: #{customer.id}"
puts "Email: #{customer.email}"

# Create a subscription
subscription = customer.subscribe(price_id: "price_xxx")
puts "Status: #{subscription.status}"
puts "Active? #{subscription.active?}"

# Check entitlement
if customer.entitled?("api_access")
  puts "Customer has API access"
end
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
  config.base_url = "https://api.tedo.ai/v1"  # optional
end

# Then use the global client
customer = Tedo.billing.create_customer(email: "user@example.com")
```

### Per-Client Configuration

```ruby
client = Tedo::Client.new(
  "tedo_live_xxx",
  base_url: "https://api.staging.tedo.ai/v1"
)
```

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
rescue Tedo::PermissionError => e
  puts "Not authorized for this action"
rescue Tedo::APIError => e
  puts "Server error: #{e.message}"
rescue Tedo::Error => e
  puts "Unknown error: #{e.message}"
end
```

## Available Methods

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

### Resource Methods

Resources have methods for common operations:

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

## License

MIT
