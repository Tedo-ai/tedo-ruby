# frozen_string_literal: true

module Tedo
  # A sales deal.
  #
  # @example
  #   deal = client.sales.get_deal("deal_xxx")
  #   deal.id       # => "deal_xxx"
  #   deal.label    # => "Enterprise Contract"
  #   deal.value    # => 50000
  #   deal.currency # => "USD"
  #
  # @example Move to a different stage
  #   deal.move_stage(stage_id: "stage_yyy")
  #
  class Deal < Resource
    attribute :id
    attribute :label
    attribute :pipeline_id
    attribute :stage_id
    attribute :person_id
    attribute :organization_id
    attribute :value
    attribute :currency
    attribute :expected_close_date
    attribute :owner_id
    attribute :created_at, type: :time
    attribute :updated_at, type: :time

    # Move this deal to a different pipeline stage.
    #
    # @param stage_id [String] Target stage ID
    # @return [Deal] The updated deal
    def move_stage(stage_id:)
      raise "No client available" unless client

      client.sales.move_deal_stage(id, stage_id: stage_id)
    end

    # Update this deal.
    #
    # @param label [String, nil] New label
    # @param person_id [String, nil] New person ID
    # @param organization_id [String, nil] New organization ID
    # @param value [Numeric, nil] New value
    # @param currency [String, nil] New currency
    # @param expected_close_date [String, nil] New expected close date
    # @return [Deal] The updated deal
    def update(label: nil, person_id: nil, organization_id: nil, value: nil, currency: nil, expected_close_date: nil)
      raise "No client available" unless client

      client.sales.update_deal(id, label: label, person_id: person_id,
                                   organization_id: organization_id, value: value,
                                   currency: currency, expected_close_date: expected_close_date)
    end

    # Delete this deal.
    #
    # @return [void]
    def delete
      raise "No client available" unless client

      client.sales.delete_deal(id)
    end
  end
end
