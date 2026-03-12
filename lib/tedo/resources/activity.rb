# frozen_string_literal: true

module Tedo
  # A sales activity (call, meeting, email, task, etc.).
  #
  # @example
  #   activity = client.sales.get_activity("act_xxx")
  #   activity.subject      # => "Follow-up call"
  #   activity.type         # => "call"
  #   activity.is_completed # => false
  #
  # @example Mark as completed
  #   activity.complete
  #
  class Activity < Resource
    attribute :id
    attribute :type
    attribute :subject
    attribute :description
    attribute :due_date
    attribute :due_time
    attribute :duration_minutes
    attribute :is_completed
    attribute :completed_at, type: :time
    attribute :created_at, type: :time
    attribute :updated_at, type: :time

    # Whether this activity has been completed.
    #
    # @return [Boolean]
    def completed?
      is_completed == true
    end

    # Mark this activity as completed (or uncompleted).
    #
    # @param completed [Boolean] Whether to mark as completed (default: true)
    # @return [Activity] The updated activity
    def complete(completed: true)
      raise "No client available" unless client

      client.sales.complete_activity(id, completed: completed)
    end

    # Update this activity.
    #
    # @param subject [String, nil] New subject
    # @param description [String, nil] New description
    # @param due_date [String, nil] New due date
    # @param due_time [String, nil] New due time
    # @param duration_minutes [Integer, nil] New duration in minutes
    # @return [Activity] The updated activity
    def update(subject: nil, description: nil, due_date: nil, due_time: nil, duration_minutes: nil)
      raise "No client available" unless client

      client.sales.update_activity(id, subject: subject, description: description,
                                       due_date: due_date, due_time: due_time,
                                       duration_minutes: duration_minutes)
    end

    # Delete this activity.
    #
    # @return [void]
    def delete
      raise "No client available" unless client

      client.sales.delete_activity(id)
    end
  end
end
