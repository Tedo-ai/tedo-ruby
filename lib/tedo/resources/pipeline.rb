# frozen_string_literal: true

module Tedo
  # A sales pipeline.
  #
  # @example
  #   pipeline = client.sales.get_pipeline("pipe_xxx")
  #   pipeline.id            # => "pipe_xxx"
  #   pipeline.name          # => "Default Pipeline"
  #   pipeline.resource_type # => "lead"
  #
  class Pipeline < Resource
    attribute :id
    attribute :name
    attribute :resource_type
    attribute :created_at, type: :time
    attribute :updated_at, type: :time

    # Update this pipeline.
    #
    # @param name [String, nil] New pipeline name
    # @return [Pipeline] The updated pipeline
    def update(name: nil)
      raise "No client available" unless client

      client.sales.update_pipeline(id, name: name)
    end

    # Delete this pipeline.
    #
    # @return [void]
    def delete
      raise "No client available" unless client

      client.sales.delete_pipeline(id)
    end
  end
end
