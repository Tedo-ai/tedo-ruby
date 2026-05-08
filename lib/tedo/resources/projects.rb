# frozen_string_literal: true

require "securerandom"
require "uri"

module Tedo
  PROJECT_STATUS_CATEGORY_START = "start"
  PROJECT_STATUS_CATEGORY_IN_PROGRESS = "in_progress"
  PROJECT_STATUS_CATEGORY_COMPLETED = "completed"
  PROJECT_STATUS_CATEGORY_CANCELED = "canceled"

  PROJECT_PRIORITY_NONE = 0
  PROJECT_PRIORITY_LOW = 1
  PROJECT_PRIORITY_MEDIUM = 2
  PROJECT_PRIORITY_HIGH = 3
  PROJECT_PRIORITY_URGENT = 4

  class Project < Resource
    attribute :id
    attribute :team_id
    attribute :name
    attribute :description
    attribute :archived
    attribute :created_at, type: :time
    attribute :updated_at, type: :time

    predicate :archived, field: "archived", value: true
  end

  class WorkItem < Resource
    attribute :id
    attribute :display_id
    attribute :sequence_number
    attribute :project_id
    attribute :team_id
    attribute :parent_id
    attribute :work_item_type_id
    attribute :status_id
    attribute :title
    attribute :description
    attribute :completed_at, type: :time
    attribute :archived_at, type: :time
    attribute :assignee_id
    attribute :priority
    attribute :due_date
    attribute :position
    attribute :child_count
    attribute :created_at, type: :time
    attribute :updated_at, type: :time

    def completed?
      !completed_at.nil?
    end

    def archived?
      !archived_at.nil?
    end
  end

  class WorkflowStatus < Resource
    attribute :id
    attribute :work_item_type_id
    attribute :name
    attribute :category
    attribute :position
    attribute :is_default
    attribute :created_at, type: :time
    attribute :updated_at, type: :time

    predicate :default, field: "is_default", value: true
  end

  class WorkItemType < Resource
    attribute :id
    attribute :name
    attribute :singular_name
    attribute :plural_name
    attribute :parent_type_id
    attribute :prefix
    attribute :color
    attribute :position
    attribute :show_in_sidebar
    attribute :created_at, type: :time
    attribute :updated_at, type: :time
  end

  class PriorityLevel < Resource
    attribute :id
    attribute :level
    attribute :name
    attribute :icon
    attribute :created_at, type: :time
    attribute :updated_at, type: :time
  end

  class ProjectComment < Resource
    attribute :id
    attribute :work_item_id
    attribute :actor_type
    attribute :actor_ref
    attribute :content
    attribute :created_at, type: :time
    attribute :updated_at, type: :time
  end

  class WorkItemActivity < Resource
    attribute :id
    attribute :actor_type
    attribute :actor_ref
    attribute :action
    attribute :data
    attribute :created_at, type: :time
  end

  class ProjectAttachment < Resource
    attribute :id
    attribute :work_item_id
    attribute :file_id
    attribute :position
    attribute :filename
    attribute :mime_type
    attribute :size
    attribute :title
    attribute :alt_text
    attribute :created_at, type: :time
    attribute :actor_type
    attribute :created_by_ref
  end

  class DeleteResult < Resource
    attribute :deleted
    attribute :id

    def deleted?
      deleted == true
    end
  end

  class NextDisplayID < Resource
    attribute :display_id
  end

  module Resources
    # Projects API resource.
    #
    # Exposes projects, work items, workflow configuration, comments, activity,
    # and file-reference attachments.
    class Projects
      UNSET = Object.new.freeze

      def initialize(client)
        @client = client
      end

      def list_projects(include_archived: false, limit: nil, cursor: nil)
        query = page_query(limit: limit, cursor: cursor)
        query[:include_archived] = true if include_archived
        page("/projects/v1/projects", query, Project) do |next_cursor|
          list_projects(include_archived: include_archived, limit: limit, cursor: next_cursor)
        end
      end

      def create_project(name:, description: nil, team_id: nil, idempotency_key: nil, request_id: nil)
        body = compact_nil(name: name, description: description, team_id: team_id)
        data = @client.post(
          "/projects/v1/projects",
          body,
          headers: command_headers(idempotency_key: idempotency_key, request_id: request_id, required: true)
        )
        Project.new(data, client: @client)
      end

      def get_project(project_id)
        Project.new(@client.get("/projects/v1/projects/#{path_escape(project_id)}"), client: @client)
      end

      def update_project(project_id, name: UNSET, description: UNSET, team_id: UNSET, idempotency_key: nil, request_id: nil)
        data = @client.patch(
          "/projects/v1/projects/#{path_escape(project_id)}",
          compact_unset(name: name, description: description, team_id: team_id),
          headers: command_headers(idempotency_key: idempotency_key, request_id: request_id)
        )
        Project.new(data, client: @client)
      end

      def archive_project(project_id, idempotency_key: nil, request_id: nil)
        project_action(project_id, "archive", idempotency_key: idempotency_key, request_id: request_id)
      end

      def restore_project(project_id, idempotency_key: nil, request_id: nil)
        project_action(project_id, "restore", idempotency_key: idempotency_key, request_id: request_id)
      end

      def delete_project(project_id, idempotency_key: nil, request_id: nil)
        data = @client.delete(
          "/projects/v1/projects/#{path_escape(project_id)}",
          headers: command_headers(idempotency_key: idempotency_key, request_id: request_id, required: true)
        )
        DeleteResult.new(data, client: @client)
      end

      def list_project_work_items(project_id, **params)
        query = work_item_query(params, include_project_id: false)
        page("/projects/v1/projects/#{path_escape(project_id)}/work-items", query, WorkItem) do |next_cursor|
          list_project_work_items(project_id, **params.merge(cursor: next_cursor))
        end
      end

      def create_project_work_item(project_id, **params)
        body = compact_nil(params.reject { |key, _| request_option_key?(key) }.merge(project_id: project_id))
        data = @client.post(
          "/projects/v1/projects/#{path_escape(project_id)}/work-items",
          body,
          headers: command_headers(
            idempotency_key: params[:idempotency_key],
            request_id: params[:request_id],
            required: true
          )
        )
        WorkItem.new(data, client: @client)
      end

      def list_work_items(**params)
        query = work_item_query(params, include_project_id: true)
        page("/projects/v1/work-items", query, WorkItem) do |next_cursor|
          list_work_items(**params.merge(cursor: next_cursor))
        end
      end

      def create_work_item(**params)
        data = @client.post(
          "/projects/v1/work-items",
          compact_nil(params.reject { |key, _| request_option_key?(key) }),
          headers: command_headers(
            idempotency_key: params[:idempotency_key],
            request_id: params[:request_id],
            required: true
          )
        )
        WorkItem.new(data, client: @client)
      end

      def peek_next_display_id(work_item_type_id: nil)
        query = compact_nil(work_item_type_id: work_item_type_id)
        NextDisplayID.new(@client.get("/projects/v1/work-items/next-display-id", query), client: @client)
      end

      def get_work_item(work_item_id)
        WorkItem.new(@client.get("/projects/v1/work-items/#{path_escape(work_item_id)}"), client: @client)
      end

      def update_work_item(work_item_id, **params)
        data = @client.patch(
          "/projects/v1/work-items/#{path_escape(work_item_id)}",
          compact_unset(params.reject { |key, _| request_option_key?(key) }),
          headers: command_headers(idempotency_key: params[:idempotency_key], request_id: params[:request_id])
        )
        WorkItem.new(data, client: @client)
      end

      def complete_work_item(work_item_id, completed: true, idempotency_key: nil, request_id: nil)
        data = @client.post(
          "/projects/v1/work-items/#{path_escape(work_item_id)}/complete",
          { completed: completed },
          headers: command_headers(idempotency_key: idempotency_key, request_id: request_id)
        )
        WorkItem.new(data, client: @client)
      end

      def archive_work_item(work_item_id, idempotency_key: nil, request_id: nil)
        work_item_action(work_item_id, "archive", idempotency_key: idempotency_key, request_id: request_id)
      end

      def restore_work_item(work_item_id, idempotency_key: nil, request_id: nil)
        work_item_action(work_item_id, "restore", idempotency_key: idempotency_key, request_id: request_id)
      end

      def delete_work_item(work_item_id, idempotency_key: nil, request_id: nil)
        data = @client.delete(
          "/projects/v1/work-items/#{path_escape(work_item_id)}",
          headers: command_headers(idempotency_key: idempotency_key, request_id: request_id, required: true)
        )
        DeleteResult.new(data, client: @client)
      end

      def list_subtasks(work_item_id, limit: nil, cursor: nil)
        query = page_query(limit: limit, cursor: cursor)
        page("/projects/v1/work-items/#{path_escape(work_item_id)}/subtasks", query, WorkItem) do |next_cursor|
          list_subtasks(work_item_id, limit: limit, cursor: next_cursor)
        end
      end

      def list_work_item_activity(work_item_id, include_subtasks: false, include_comments: false, limit: nil, cursor: nil)
        query = page_query(limit: limit, cursor: cursor)
        query[:include_subtasks] = true if include_subtasks
        query[:include_comments] = true if include_comments
        page("/projects/v1/work-items/#{path_escape(work_item_id)}/activity", query, WorkItemActivity) do |next_cursor|
          list_work_item_activity(
            work_item_id,
            include_subtasks: include_subtasks,
            include_comments: include_comments,
            limit: limit,
            cursor: next_cursor
          )
        end
      end

      def list_statuses(work_item_type_id: nil, limit: nil, cursor: nil)
        query = page_query(limit: limit, cursor: cursor)
        query[:work_item_type_id] = work_item_type_id if work_item_type_id
        page("/projects/v1/statuses", query, WorkflowStatus) do |next_cursor|
          list_statuses(work_item_type_id: work_item_type_id, limit: limit, cursor: next_cursor)
        end
      end

      def create_status(name:, category:, work_item_type_id: nil, position: nil, is_default: nil, idempotency_key: nil, request_id: nil)
        body = compact_nil(
          work_item_type_id: work_item_type_id,
          name: name,
          category: category,
          position: position,
          is_default: is_default
        )
        data = @client.post(
          "/projects/v1/statuses",
          body,
          headers: command_headers(idempotency_key: idempotency_key, request_id: request_id, required: true)
        )
        WorkflowStatus.new(data, client: @client)
      end

      def update_status(status_id, name: UNSET, category: UNSET, work_item_type_id: UNSET, position: UNSET, is_default: UNSET, idempotency_key: nil, request_id: nil)
        body = compact_unset(
          work_item_type_id: work_item_type_id,
          name: name,
          category: category,
          position: position,
          is_default: is_default
        )
        data = @client.patch(
          "/projects/v1/statuses/#{path_escape(status_id)}",
          body,
          headers: command_headers(idempotency_key: idempotency_key, request_id: request_id)
        )
        WorkflowStatus.new(data, client: @client)
      end

      def delete_status(status_id, idempotency_key: nil, request_id: nil)
        data = @client.delete(
          "/projects/v1/statuses/#{path_escape(status_id)}",
          headers: command_headers(idempotency_key: idempotency_key, request_id: request_id, required: true)
        )
        DeleteResult.new(data, client: @client)
      end

      def list_work_item_types(limit: nil, cursor: nil)
        query = page_query(limit: limit, cursor: cursor)
        page("/projects/v1/work-item-types", query, WorkItemType) do |next_cursor|
          list_work_item_types(limit: limit, cursor: next_cursor)
        end
      end

      def create_work_item_type(name:, singular_name: nil, plural_name: nil, parent_type_id: nil, prefix: nil, color: nil, position: nil, show_in_sidebar: nil, idempotency_key: nil, request_id: nil)
        body = compact_nil(
          name: name,
          singular_name: singular_name,
          plural_name: plural_name,
          parent_type_id: parent_type_id,
          prefix: prefix,
          color: color,
          position: position,
          show_in_sidebar: show_in_sidebar
        )
        data = @client.post(
          "/projects/v1/work-item-types",
          body,
          headers: command_headers(idempotency_key: idempotency_key, request_id: request_id, required: true)
        )
        WorkItemType.new(data, client: @client)
      end

      def update_work_item_type(work_item_type_id, **params)
        data = @client.patch(
          "/projects/v1/work-item-types/#{path_escape(work_item_type_id)}",
          compact_unset(params.reject { |key, _| request_option_key?(key) }),
          headers: command_headers(idempotency_key: params[:idempotency_key], request_id: params[:request_id])
        )
        WorkItemType.new(data, client: @client)
      end

      def delete_work_item_type(work_item_type_id, idempotency_key: nil, request_id: nil)
        data = @client.delete(
          "/projects/v1/work-item-types/#{path_escape(work_item_type_id)}",
          headers: command_headers(idempotency_key: idempotency_key, request_id: request_id, required: true)
        )
        DeleteResult.new(data, client: @client)
      end

      def list_priority_levels(limit: nil, cursor: nil)
        query = page_query(limit: limit, cursor: cursor)
        page("/projects/v1/priority-levels", query, PriorityLevel) do |next_cursor|
          list_priority_levels(limit: limit, cursor: next_cursor)
        end
      end

      def update_priority_level(level, name: UNSET, icon: UNSET, idempotency_key: nil, request_id: nil)
        data = @client.patch(
          "/projects/v1/priority-levels/#{level}",
          compact_unset(name: name, icon: icon),
          headers: command_headers(idempotency_key: idempotency_key, request_id: request_id)
        )
        PriorityLevel.new(data, client: @client)
      end

      def reset_priority_level(level, idempotency_key: nil, request_id: nil)
        data = @client.post(
          "/projects/v1/priority-levels/#{level}/reset",
          nil,
          headers: command_headers(idempotency_key: idempotency_key, request_id: request_id)
        )
        PriorityLevel.new(data, client: @client)
      end

      def list_comments(work_item_id, limit: nil, cursor: nil)
        query = page_query(limit: limit, cursor: cursor)
        page("/projects/v1/work-items/#{path_escape(work_item_id)}/comments", query, ProjectComment) do |next_cursor|
          list_comments(work_item_id, limit: limit, cursor: next_cursor)
        end
      end

      def list_attachments(work_item_id, limit: nil, cursor: nil)
        query = page_query(limit: limit, cursor: cursor)
        page("/projects/v1/work-items/#{path_escape(work_item_id)}/attachments", query, ProjectAttachment) do |next_cursor|
          list_attachments(work_item_id, limit: limit, cursor: next_cursor)
        end
      end

      def attach_file(work_item_id, file_id:, display_name: nil, idempotency_key: nil, request_id: nil)
        data = @client.post(
          "/projects/v1/work-items/#{path_escape(work_item_id)}/attachments",
          compact_nil(file_id: file_id, display_name: display_name),
          headers: command_headers(idempotency_key: idempotency_key, request_id: request_id, required: true)
        )
        ProjectAttachment.new(data, client: @client)
      end

      def detach_attachment(work_item_id, attachment_id, idempotency_key: nil, request_id: nil)
        path = "/projects/v1/work-items/#{path_escape(work_item_id)}/attachments/#{path_escape(attachment_id)}"
        data = @client.delete(
          path,
          headers: command_headers(idempotency_key: idempotency_key, request_id: request_id, required: true)
        )
        DeleteResult.new(data, client: @client)
      end

      private

      def project_action(project_id, action, idempotency_key:, request_id:)
        data = @client.post(
          "/projects/v1/projects/#{path_escape(project_id)}/#{action}",
          nil,
          headers: command_headers(idempotency_key: idempotency_key, request_id: request_id)
        )
        Project.new(data, client: @client)
      end

      def work_item_action(work_item_id, action, idempotency_key:, request_id:)
        data = @client.post(
          "/projects/v1/work-items/#{path_escape(work_item_id)}/#{action}",
          nil,
          headers: command_headers(idempotency_key: idempotency_key, request_id: request_id)
        )
        WorkItem.new(data, client: @client)
      end

      def page(path, query, resource_class, &fetch_page)
        data = @client.get(path, compact_nil(query))
        List.new(
          data: (data["items"] || []).map { |item| resource_class.new(item, client: @client) },
          total: data["total"],
          next_cursor: data["next_cursor"],
          has_more: data.key?("has_more") ? data["has_more"] : nil,
          client: @client,
          fetch_page: fetch_page
        )
      end

      def command_headers(idempotency_key: nil, request_id: nil, required: false)
        headers = {}
        key = idempotency_key
        key ||= "tedo_ruby_#{SecureRandom.hex(16)}" if required
        headers["Idempotency-Key"] = key if key && !key.empty?
        headers["X-Request-ID"] = request_id if request_id && !request_id.empty?
        headers
      end

      def page_query(limit: nil, cursor: nil)
        compact_nil(limit: limit, cursor: cursor)
      end

      def work_item_query(params, include_project_id:)
        query = {}
        query[:project_id] = params[:project_id] if include_project_id && params[:project_id]
        query[:work_item_type_id] = params[:work_item_type_id] if params[:work_item_type_id]
        query[:status_id] = params[:status_id] if params[:status_id]
        query[:parent_id] = params[:parent_id] if params[:parent_id]
        query[:assignee_id] = params[:assignee_id] if params[:assignee_id]
        query[:priority] = params[:priority] unless params[:priority].nil?
        query[:include_completed] = true if params[:include_completed]
        query[:include_archived] = true if params[:include_archived]
        query[:limit] = params[:limit] if params[:limit]
        query[:cursor] = params[:cursor] if params[:cursor]
        query
      end

      def compact_nil(hash)
        hash.each_with_object({}) do |(key, value), out|
          out[key] = value unless value.nil?
        end
      end

      def compact_unset(hash)
        hash.each_with_object({}) do |(key, value), out|
          out[key] = value unless value.equal?(UNSET)
        end
      end

      def request_option_key?(key)
        key == :idempotency_key || key == :request_id
      end

      def path_escape(value)
        URI.encode_www_form_component(value.to_s)
      end
    end
  end
end
