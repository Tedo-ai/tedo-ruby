# frozen_string_literal: true

module Tedo
  COLUMN_TYPES = %w[
    text number number_with_unit boolean date timestamp url select multi_select
    reference multi_reference rollup
  ].freeze

  class TablesBase < Resource
    attribute :id
    attribute :workspace_id
    attribute :name
    attribute :description
    attribute :created_by_actor_type
    attribute :created_by_actor_id
    attribute :created_at, type: :time
    attribute :updated_at, type: :time
    attribute :archived_at, type: :time
  end

  class Table < Resource
    attribute :id
    attribute :workspace_id
    attribute :base_id
    attribute :name
    attribute :slug
    attribute :description
    attribute :primary_column_id
    attribute :position
    attribute :schema_version
    attribute :created_at, type: :time
    attribute :updated_at, type: :time
    attribute :archived_at, type: :time
  end

  class Column < Resource
    attribute :id
    attribute :table_id
    attribute :key
    attribute :name
    attribute :type
    attribute :type_config
    attribute :required
    attribute :default_value
    attribute :position
    attribute :indexed
    attribute :unique
    attribute :created_at, type: :time
    attribute :updated_at, type: :time
    attribute :archived_at, type: :time
  end

  class Row < Resource
    attribute :id
    attribute :workspace_id
    attribute :table_id
    attribute :external_key
    attribute :data
    attribute :data_version
    attribute :created_by_actor_type
    attribute :created_by_actor_id
    attribute :created_by_actor_name
    attribute :updated_by_actor_type
    attribute :updated_by_actor_id
    attribute :updated_by_actor_name
    attribute :created_at, type: :time
    attribute :updated_at, type: :time
    attribute :archived_at, type: :time
  end

  class HistoryEvent < Resource
    attribute :id
    attribute :table_id
    attribute :row_id
    attribute :operation_key
    attribute :stage
    attribute :code
    attribute :actor_type
    attribute :actor_id
    attribute :actor_name
    attribute :origin_actor_type
    attribute :origin_actor_id
    attribute :source_url
    attribute :patch
    attribute :at, type: :time
  end

  class Snapshot < Resource
    attribute :id
    attribute :table_id
    attribute :label
    attribute :schema_frozen
    attribute :data_frozen_ref
    attribute :created_by_actor_type
    attribute :created_by_actor_id
    attribute :created_at, type: :time
  end

  class ShareToken < Resource
    attribute :id
    attribute :scope_kind
    attribute :scope_id
    attribute :permissions
    attribute :kind
    attribute :token
    attribute :expires_at, type: :time
    attribute :created_at, type: :time
    attribute :revoked_at, type: :time
  end

  module Resources
    class Tables
      def initialize(client)
        @client = client
      end

      def create_base(name:, description: nil)
        data = @client.post("/tables/v1/bases", compact(name: name, description: description))
        TablesBase.new(data["base"] || data, client: @client)
      end

      def list_bases(limit: nil)
        data = @client.get("/tables/v1/bases", compact(limit: limit))
        (data["bases"] || []).map { |item| TablesBase.new(item, client: @client) }
      end

      def get_base(base_id)
        data = @client.get("/tables/v1/bases/#{escape(base_id)}")
        TablesBase.new(data["base"] || data, client: @client)
      end

      def update_base(base_id, name: nil, description: nil)
        data = @client.patch("/tables/v1/bases/#{escape(base_id)}", compact(name: name, description: description))
        TablesBase.new(data["base"] || data, client: @client)
      end

      def archive_base(base_id)
        @client.delete("/tables/v1/bases/#{escape(base_id)}")
      end

      def create_table(name:, base_id: nil, slug: nil, description: nil, columns: nil)
        @client.post("/tables/v1/tables", compact(
          base_id: base_id,
          name: name,
          slug: slug,
          description: description,
          columns: columns
        ))
      end

      def create_table_in_base(base_id, name:, slug: nil, description: nil, columns: nil)
        @client.post("/tables/v1/bases/#{escape(base_id)}/tables", compact(
          name: name,
          slug: slug,
          description: description,
          columns: columns
        ))
      end

      def list_tables(base_id: nil, limit: nil)
        data = @client.get("/tables/v1/tables", compact(base_id: base_id, limit: limit))
        (data["tables"] || []).map { |item| Table.new(item, client: @client) }
      end

      def get_table(table_id)
        @client.get("/tables/v1/tables/#{escape(table_id)}")
      end

      def update_table(table_id, name: nil, slug: nil, description: nil)
        data = @client.patch("/tables/v1/tables/#{escape(table_id)}", compact(
          name: name,
          slug: slug,
          description: description
        ))
        Table.new(data["table"] || data, client: @client)
      end

      def archive_table(table_id)
        @client.delete("/tables/v1/tables/#{escape(table_id)}")
      end

      def upsert_column(table_id, type:, name: nil, key: nil, column_id: nil, type_config: nil,
                        required: nil, default_value: nil, position: nil, indexed: nil, unique: nil)
        data = @client.post("/tables/v1/tables/#{escape(table_id)}/columns", compact(
          name: name,
          key: key,
          column_id: column_id,
          type: type,
          type_config: type_config,
          required: required,
          default_value: default_value,
          position: position,
          indexed: indexed,
          unique: unique
        ))
        wrap_column_result(data)
      end

      def list_columns(table_id)
        data = @client.get("/tables/v1/tables/#{escape(table_id)}/columns")
        (data["columns"] || []).map { |item| Column.new(item, client: @client) }
      end

      def update_column(column_id, **params)
        data = @client.patch("/tables/v1/columns/#{escape(column_id)}", compact(params))
        Column.new(data["column"] || data, client: @client)
      end

      def archive_column(column_id)
        @client.delete("/tables/v1/columns/#{escape(column_id)}")
      end

      def retype_column(table_id, column_id, type:, config: nil, mode: "preview")
        data = @client.post("/tables/v1/tables/#{escape(table_id)}/columns/#{escape(column_id)}/retype",
                            compact(type: type, config: config, mode: mode))
        wrap_column_result(data)
      end

      def upsert_row(table_id, values:, row_id: nil, key_column: nil, key_value: nil)
        data = @client.post("/tables/v1/tables/#{escape(table_id)}/rows", compact(
          values: values,
          row_id: row_id,
          key_column: key_column,
          key_value: key_value
        ))
        data["row"] = Row.new(data["row"], client: @client) if data["row"]
        data
      end

      def query_rows(table_id, filter: nil, fields: nil, sort: nil, expand: nil, cursor: nil,
                     limit: nil, group_by: nil, aggregate: nil, page: nil)
        data = @client.get("/tables/v1/tables/#{escape(table_id)}/rows", compact(
          filter: filter,
          fields: fields,
          sort: sort,
          expand: expand,
          cursor: cursor,
          limit: limit,
          group_by: group_by,
          aggregate: aggregate,
          page: page
        ))
        data["rows"] = (data["rows"] || []).map { |item| Row.new(item, client: @client) } if data.key?("rows")
        data["schema"] = (data["schema"] || []).map { |item| Column.new(item, client: @client) } if data.key?("schema")
        data
      end

      def get_row(table_id, row_id)
        data = @client.get("/tables/v1/tables/#{escape(table_id)}/rows/#{escape(row_id)}")
        Row.new(data["row"] || data, client: @client)
      end

      def row_history(table_id, row_id)
        data = @client.get("/tables/v1/tables/#{escape(table_id)}/rows/#{escape(row_id)}/history")
        (data["events"] || []).map { |item| HistoryEvent.new(item, client: @client) }
      end

      def update_row(table_id, row_id, data:)
        body = @client.patch("/tables/v1/tables/#{escape(table_id)}/rows/#{escape(row_id)}", data: data)
        Row.new(body["row"] || body, client: @client)
      end

      def delete_row(table_id, row_id)
        @client.delete("/tables/v1/tables/#{escape(table_id)}/rows/#{escape(row_id)}")
      end

      def bulk_upsert_rows(table_id, rows:, key_column: nil, delete_missing: nil, bulk_replace: nil)
        delete_missing = bulk_replace if delete_missing.nil? && !bulk_replace.nil?
        data = @client.post("/tables/v1/tables/#{escape(table_id)}/rows/bulk_upsert", compact(
          rows: rows,
          key_column: key_column,
          delete_missing: delete_missing
        ))
        data["rows"] = (data["rows"] || []).map { |item| Row.new(item, client: @client) } if data.key?("rows")
        data
      end

      def create_snapshot(table_id, label: nil)
        data = @client.post("/tables/v1/tables/#{escape(table_id)}/snapshots", compact(label: label))
        Snapshot.new(data["snapshot"] || data, client: @client)
      end

      def list_snapshots(table_id)
        data = @client.get("/tables/v1/tables/#{escape(table_id)}/snapshots")
        (data["snapshots"] || []).map { |item| Snapshot.new(item, client: @client) }
      end

      def restore_snapshot(table_id, snapshot_id)
        data = @client.post("/tables/v1/tables/#{escape(table_id)}/snapshots/#{escape(snapshot_id)}/restore")
        Snapshot.new(data["snapshot"] || data, client: @client)
      end

      def create_share_token(table_id, kind: "read", permissions: nil, expires_at: nil)
        data = @client.post("/tables/v1/tables/#{escape(table_id)}/shares", compact(
          kind: kind,
          permissions: permissions,
          expires_at: expires_at
        ))
        data["share_token"] = ShareToken.new(data["share_token"], client: @client) if data["share_token"]
        data
      end

      def revoke_share_token(token_id)
        @client.delete("/tables/v1/share_tokens/#{escape(token_id)}")
      end

      def import_csv(csv_body:, key_column:, base_id: nil, table_id: nil, name: nil, mode: nil,
                     column_types: nil, unit_defaults: nil)
        @client.post("/tables/v1/import/csv", compact(
          base_id: base_id,
          table_id: table_id,
          name: name,
          csv_body: csv_body,
          key_column: key_column,
          mode: mode,
          column_types: column_types,
          unit_defaults: unit_defaults
        ))
      end

      private

      def compact(values)
        values.each_with_object({}) do |(key, value), out|
          out[key] = value unless value.nil?
        end
      end

      def escape(value)
        Faraday::Utils.escape(value.to_s)
      end

      def wrap_column_result(data)
        data["column"] = Column.new(data["column"], client: @client) if data["column"]
        data
      end
    end
  end
end
