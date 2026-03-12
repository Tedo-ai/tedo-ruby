# frozen_string_literal: true

module Tedo
  # A stage within a sales pipeline.
  #
  # @example
  #   stage = client.sales.get_stage("stage_xxx")
  #   stage.id          # => "stage_xxx"
  #   stage.name        # => "Qualified"
  #   stage.position    # => 2
  #   stage.is_terminal # => false
  #
  class PipelineStage < Resource
    attribute :id
    attribute :pipeline_id
    attribute :name
    attribute :position
    attribute :is_terminal
    attribute :outcome
    attribute :created_at, type: :time
    attribute :updated_at, type: :time

    # Whether this stage ends the pipeline.
    #
    # @return [Boolean]
    def terminal?
      is_terminal == true
    end

    # Update this stage.
    #
    # @param name [String, nil] New stage name
    # @param position [Integer, nil] New position
    # @param is_terminal [Boolean, nil] Whether this is a terminal stage
    # @param outcome [String, nil] Outcome label (e.g., "won", "lost")
    # @return [PipelineStage] The updated stage
    def update(name: nil, position: nil, is_terminal: nil, outcome: nil)
      raise "No client available" unless client

      client.sales.update_stage(id, name: name, position: position,
                                    is_terminal: is_terminal, outcome: outcome)
    end

    # Delete this stage.
    #
    # @return [void]
    def delete
      raise "No client available" unless client

      client.sales.delete_stage(id)
    end
  end
end
