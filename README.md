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
puts "Created customer: #{customer['id']}"

# Create a subscription
subscription = client.billing.create_subscription(
  customer_id: customer["id"],
  price_id: "price_xxx"
)
puts "Created subscription: #{subscription['id']}"

# Check entitlement
result = client.billing.check_entitlement(
  customer_id: customer["id"],
  entitlement_key: "api_access"
)
puts "Has access: #{result['has_access']}"
```

## Configuration

### Global Configuration

```ruby
Tedo.configure do |config|
  config.api_key = "tedo_live_xxx"
  config.base_url = "https://api.tedo.ai/v1"  # optional
end

# Then use the global client
Tedo.billing.create_customer(email: "user@example.com")
```

### Per-Client Configuration

```ruby
client = Tedo::Client.new(
  "tedo_live_xxx",
  base_url: "https://api.staging.tedo.ai/v1"
)
```

## Error Handling

```ruby
begin
  customer = client.billing.get_customer("cus_nonexistent")
rescue Tedo::NotFoundError => e
  puts "Customer not found: #{e.message}"
rescue Tedo::ValidationError => e
  puts "Validation error: #{e.message} (field: #{e.field})"
rescue Tedo::AuthenticationError => e
  puts "Invalid API key"
rescue Tedo::Error => e
  puts "API error: #{e.message}"
end
```

## Pagination

```ruby
# Manual pagination
cursor = nil
all_customers = []

loop do
  result = client.billing.list_customers(limit: 100, cursor: cursor)
  all_customers.concat(result["customers"])

  cursor = result["next_cursor"]
  break unless cursor
end
```

## Available Methods

### Billing

| Method | Description |
|--------|-------------|
| `create_customer` | Create a new customer |
| `get_customer` | Get a customer by ID |
| `list_customers` | List all customers |
| `update_customer` | Update a customer |
| `delete_customer` | Delete a customer |
| `create_subscription` | Create a subscription |
| `get_subscription` | Get a subscription |
| `cancel_subscription` | Cancel a subscription |
| `check_entitlement` | Check feature access |
| `record_usage` | Record metered usage |
| `get_usage_summary` | Get usage summary |

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
  def create_customer(user)
    Tedo.billing.create_customer(
      email: user.email,
      name: user.full_name,
      external_id: user.id.to_s
    )
  end
end
```

## License

MIT
