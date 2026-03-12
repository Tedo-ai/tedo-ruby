# frozen_string_literal: true

module Tedo
  # A sales lead.
  #
  # @example
  #   lead = client.sales.get_lead("lead_xxx")
  #   lead.id    # => "lead_xxx"
  #   lead.label # => "Acme Corp Inquiry"
  #
  # @example Move to a different stage
  #   lead.move_stage(stage_id: "stage_yyy")
  #
  # @example Convert to a deal
  #   deal = lead.convert_to_deal(value: 50000, currency: "USD")
  #
  class Lead < Resource
    attribute :id
    attribute :label
    attribute :pipeline_id
    attribute :stage_id
    attribute :person_id
    attribute :organization_id
    attribute :source
    attribute :owner_id
    attribute :created_at, type: :time
    attribute :updated_at, type: :time

    # Move this lead to a different pipeline stage.
    #
    # @param stage_id [String] Target stage ID
    # @return [Lead] The updated lead
    def move_stage(stage_id:)
      raise "No client available" unless client

      client.sales.move_lead_stage(id, stage_id: stage_id)
    end

    # Convert this lead into a deal.
    #
    # @param value [Numeric, nil] Deal value
    # @param currency [String] Currency code (default: USD)
    # @param pipeline_id [String, nil] Target deal pipeline ID
    # @return [Deal] The created deal
    def convert_to_deal(value: nil, currency: "USD", pipeline_id: nil)
      raise "No client available" unless client

      client.sales.convert_lead_to_deal(id, value: value, currency: currency,
                                            pipeline_id: pipeline_id)
    end

    # Update this lead.
    #
    # @param label [String, nil] New label
    # @param person_id [String, nil] New person ID
    # @param organization_id [String, nil] New organization ID
    # @param source [String, nil] New source
    # @return [Lead] The updated lead
    def update(label: nil, person_id: nil, organization_id: nil, source: nil)
      raise "No client available" unless client

      client.sales.update_lead(id, label: label, person_id: person_id,
                                   organization_id: organization_id, source: source)
    end

    # Delete this lead.
    #
    # @return [void]
    def delete
      raise "No client available" unless client

      client.sales.delete_lead(id)
    end
  end
end
