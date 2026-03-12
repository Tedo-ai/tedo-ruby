# frozen_string_literal: true

module Tedo
  # Activity type constants.
  #
  # @example
  #   client.sales.create_activity(
  #     type: Tedo::ActivityType::CALL,
  #     subject: "Follow up"
  #   )
  module ActivityType
    TASK     = "task"
    CALL     = "call"
    EMAIL    = "email"
    MEETING  = "meeting"
    DEADLINE = "deadline"

    ALL = [TASK, CALL, EMAIL, MEETING, DEADLINE].freeze
  end

  # Pipeline resource type constants.
  module ResourceType
    LEAD = "lead"
    DEAL = "deal"

    ALL = [LEAD, DEAL].freeze
  end

  # Stage outcome constants.
  module StageOutcome
    POSITIVE = "positive"
    NEGATIVE = "negative"

    ALL = [POSITIVE, NEGATIVE].freeze
  end

  # Helper to create typed entity links for activities and notes.
  #
  # @example
  #   client.sales.create_activity(
  #     type: Tedo::ActivityType::CALL,
  #     subject: "Follow up",
  #     links: [Tedo::Link.lead("lead_id"), Tedo::Link.deal("deal_id")]
  #   )
  #
  #   client.sales.create_note(
  #     content: "Great meeting",
  #     links: [Tedo::Link.deal("deal_id")]
  #   )
  module Link
    module_function

    # Create a link to a lead.
    # @param id [String] Lead ID
    # @param primary [Boolean] Whether this is the primary link (default: true)
    # @return [Hash]
    def lead(id, primary: true)
      { entity_type: "lead", entity_id: id, is_primary: primary }
    end

    # Create a link to a deal.
    # @param id [String] Deal ID
    # @param primary [Boolean] Whether this is the primary link (default: true)
    # @return [Hash]
    def deal(id, primary: true)
      { entity_type: "deal", entity_id: id, is_primary: primary }
    end

    # Create a link to a person.
    # @param id [String] Person ID
    # @param primary [Boolean] Whether this is the primary link (default: false)
    # @return [Hash]
    def person(id, primary: false)
      { entity_type: "person", entity_id: id, is_primary: primary }
    end

    # Create a link to an organization.
    # @param id [String] Organization ID
    # @param primary [Boolean] Whether this is the primary link (default: false)
    # @return [Hash]
    def organization(id, primary: false)
      { entity_type: "organization", entity_id: id, is_primary: primary }
    end
  end
end
