# frozen_string_literal: true

require "tedo"

api_key = ENV.fetch("TEDO_API_KEY")
client = Tedo::Client.new(api_key)

created = client.tables.create_table(name: "Editorial Pipeline")
table = Tedo::Table.new(created["table"], client: client)

client.tables.upsert_column(table.id, name: "Title", key: "title", type: "text")
client.tables.upsert_column(
  table.id,
  name: "Status",
  key: "status",
  type: "select",
  type_config: { options: %w[draft review published] }
)

client.tables.bulk_upsert_rows(
  table.id,
  key_column: "title",
  rows: [
    { title: "Spring launch", status: "draft" },
    { title: "Customer story", status: "review" }
  ]
)

result = client.tables.query_rows(table.id, filter: 'eq(status,"review")', limit: 10)
result["rows"].each do |row|
  puts "#{row.id} #{row.data}"
end
