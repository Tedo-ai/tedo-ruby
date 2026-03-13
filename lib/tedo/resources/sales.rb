# frozen_string_literal: true

module Tedo
  module Resources
    # Sales API resource.
    #
    # @example Create a pipeline and add stages
    #   pipeline = client.sales.create_pipeline(name: "B2B Sales", resource_type: "lead")
    #   client.sales.create_stage(pipeline.id, name: "New", position: 1)
    #   client.sales.create_stage(pipeline.id, name: "Qualified", position: 2)
    #   client.sales.create_stage(pipeline.id, name: "Won", position: 3, is_terminal: true, outcome: "won")
    #
    # @example Create a lead and move through stages
    #   lead = client.sales.create_lead(label: "Acme Inquiry", pipeline_id: pipeline.id)
    #   lead.move_stage(stage_id: qualified_stage.id)
    #   deal = lead.convert_to_deal(value: 50000)
    #
    # @example Track activities
    #   activity = client.sales.create_activity(
    #     type: Tedo::ActivityType::CALL,
    #     subject: "Discovery call",
    #     links: [Tedo::Link.deal(deal.id)],
    #     due_date: "2026-03-15"
    #   )
    #   activity.complete
    #
    class Sales
      def initialize(client)
        @client = client
      end

      # ============================================================
      # PIPELINES
      # ============================================================

      # Create a new pipeline.
      #
      # @param name [String] Pipeline name
      # @param resource_type [String] Resource type this pipeline manages (e.g., "lead", "deal")
      # @return [Pipeline] The created pipeline
      #
      # @example
      #   pipeline = client.sales.create_pipeline(
      #     name: "Enterprise Sales",
      #     resource_type: "lead"
      #   )
      #
      def create_pipeline(name:, resource_type:)
        body = { name: name, resource_type: resource_type }

        data = @client.post("/sales/v1/pipelines", body)
        Pipeline.new(data, client: @client)
      end

      # List all pipelines.
      #
      # @return [Array<Pipeline>] List of pipelines
      def list_pipelines
        data = @client.get("/sales/v1/pipelines")
        (data["pipelines"] || []).map { |p| Pipeline.new(p, client: @client) }
      end

      # Get a pipeline by ID.
      #
      # @param id [String] Pipeline ID
      # @return [Pipeline] The pipeline
      def get_pipeline(id)
        data = @client.get("/sales/v1/pipelines/#{id}")
        Pipeline.new(data, client: @client)
      end

      # Update a pipeline.
      #
      # @param id [String] Pipeline ID
      # @param name [String, nil] New pipeline name
      # @return [Pipeline] The updated pipeline
      def update_pipeline(id, name: nil)
        body = {}
        body[:name] = name if name

        data = @client.patch("/sales/v1/pipelines/#{id}", body)
        Pipeline.new(data, client: @client)
      end

      # Delete a pipeline.
      #
      # @param id [String] Pipeline ID
      # @return [void]
      def delete_pipeline(id)
        @client.delete("/sales/v1/pipelines/#{id}")
        nil
      end

      # ============================================================
      # STAGES
      # ============================================================

      # Create a stage for a pipeline.
      #
      # @param pipeline_id [String] Pipeline ID
      # @param name [String] Stage name
      # @param position [Integer] Stage position (order)
      # @param is_terminal [Boolean] Whether this stage ends the pipeline (default: false)
      # @param outcome [String, nil] Outcome label for terminal stages (e.g., "won", "lost")
      # @return [PipelineStage] The created stage
      #
      # @example
      #   stage = client.sales.create_stage(
      #     "pipe_xxx",
      #     name: "Qualified",
      #     position: 2
      #   )
      #
      # @example Terminal stage
      #   stage = client.sales.create_stage(
      #     "pipe_xxx",
      #     name: "Closed Won",
      #     position: 5,
      #     is_terminal: true,
      #     outcome: "won"
      #   )
      #
      def create_stage(pipeline_id, name:, position:, is_terminal: false, outcome: nil)
        body = { pipeline_id: pipeline_id, name: name, position: position, is_terminal: is_terminal }
        body[:outcome] = outcome if outcome

        data = @client.post("/sales/v1/stages", body)
        PipelineStage.new(data, client: @client)
      end

      # List stages for a pipeline.
      #
      # @param pipeline_id [String] Pipeline ID
      # @return [Array<PipelineStage>] List of stages
      def list_stages(pipeline_id)
        data = @client.get("/sales/v1/stages", pipeline_id: pipeline_id)
        (data["stages"] || []).map { |s| PipelineStage.new(s, client: @client) }
      end

      # Get a stage by ID.
      #
      # @param id [String] Stage ID
      # @return [PipelineStage] The stage
      def get_stage(id)
        data = @client.get("/sales/v1/stages/#{id}")
        PipelineStage.new(data, client: @client)
      end

      # Update a stage.
      #
      # @param id [String] Stage ID
      # @param name [String, nil] New stage name
      # @param position [Integer, nil] New position
      # @param is_terminal [Boolean, nil] Whether this is a terminal stage
      # @param outcome [String, nil] New outcome label
      # @return [PipelineStage] The updated stage
      def update_stage(id, name: nil, position: nil, is_terminal: nil, outcome: nil)
        body = {}
        body[:name] = name if name
        body[:position] = position if position
        body[:is_terminal] = is_terminal unless is_terminal.nil?
        body[:outcome] = outcome if outcome

        data = @client.patch("/sales/v1/stages/#{id}", body)
        PipelineStage.new(data, client: @client)
      end

      # Delete a stage.
      #
      # @param id [String] Stage ID
      # @return [void]
      def delete_stage(id)
        @client.delete("/sales/v1/stages/#{id}")
        nil
      end

      # ============================================================
      # LEADS
      # ============================================================

      # Create a new lead.
      #
      # @param label [String] Lead label
      # @param pipeline_id [String] Pipeline ID
      # @param person_id [String, nil] Associated person ID
      # @param organization_id [String, nil] Associated organization ID
      # @param source [String, nil] Lead source (e.g., "website", "referral")
      # @return [Lead] The created lead
      #
      # @example
      #   lead = client.sales.create_lead(
      #     label: "Acme Corp Inquiry",
      #     pipeline_id: "pipe_xxx",
      #     source: "website"
      #   )
      #
      def create_lead(label:, pipeline_id:, person_id: nil, organization_id: nil, source: nil)
        body = { label: label, pipeline_id: pipeline_id }
        body[:person_id] = person_id if person_id
        body[:organization_id] = organization_id if organization_id
        body[:source] = source if source

        data = @client.post("/sales/v1/leads", body)
        Lead.new(data, client: @client)
      end

      # List leads, optionally filtered by pipeline.
      #
      # @param pipeline_id [String, nil] Filter by pipeline ID
      # @return [Array<Lead>] List of leads
      def list_leads(pipeline_id: nil)
        params = {}
        params[:pipeline_id] = pipeline_id if pipeline_id

        data = @client.get("/sales/v1/leads", params)
        (data["leads"] || []).map { |l| Lead.new(l, client: @client) }
      end

      # Get a lead by ID.
      #
      # @param id [String] Lead ID
      # @return [Lead] The lead
      def get_lead(id)
        data = @client.get("/sales/v1/leads/#{id}")
        Lead.new(data, client: @client)
      end

      # Update a lead.
      #
      # @param id [String] Lead ID
      # @param label [String, nil] New label
      # @param person_id [String, nil] New person ID
      # @param organization_id [String, nil] New organization ID
      # @param source [String, nil] New source
      # @return [Lead] The updated lead
      def update_lead(id, label: nil, person_id: nil, organization_id: nil, source: nil)
        body = {}
        body[:label] = label if label
        body[:person_id] = person_id if person_id
        body[:organization_id] = organization_id if organization_id
        body[:source] = source if source

        data = @client.patch("/sales/v1/leads/#{id}", body)
        Lead.new(data, client: @client)
      end

      # Delete a lead.
      #
      # @param id [String] Lead ID
      # @return [void]
      def delete_lead(id)
        @client.delete("/sales/v1/leads/#{id}")
        nil
      end

      # Move a lead to a different pipeline stage.
      #
      # @param id [String] Lead ID
      # @param stage_id [String] Target stage ID
      # @return [Lead] The updated lead
      #
      # @example
      #   lead = client.sales.move_lead_stage("lead_xxx", stage_id: "stage_yyy")
      #
      def move_lead_stage(id, stage_id:)
        data = @client.post("/sales/v1/leads/#{id}/move", { stage_id: stage_id })
        Lead.new(data, client: @client)
      end

      # Convert a lead into a deal.
      #
      # @param id [String] Lead ID
      # @param deal_pipeline_id [String] Target deal pipeline ID
      # @param deal_stage_id [String] Target deal stage ID
      # @param deal_label [String, nil] Deal label (defaults to lead label)
      # @param value [Numeric, nil] Deal value
      # @param currency [String, nil] Currency code (default: EUR)
      # @return [Deal] The created deal
      #
      # @example
      #   deal = client.sales.convert_lead_to_deal(
      #     "lead_xxx",
      #     deal_pipeline_id: "pipe_xxx",
      #     deal_stage_id: "stage_yyy",
      #     value: 50000,
      #     currency: "EUR"
      #   )
      #
      def convert_lead_to_deal(id, deal_pipeline_id:, deal_stage_id:, deal_label: nil, value: nil, currency: nil)
        body = { deal_pipeline_id: deal_pipeline_id, deal_stage_id: deal_stage_id }
        body[:deal_label] = deal_label if deal_label
        body[:value] = value if value
        body[:currency] = currency if currency

        data = @client.post("/sales/v1/leads/#{id}/convert", body)
        Deal.new(data, client: @client)
      end

      # ============================================================
      # DEALS
      # ============================================================

      # Create a new deal.
      #
      # @param label [String] Deal label
      # @param pipeline_id [String] Pipeline ID
      # @param person_id [String, nil] Associated person ID
      # @param organization_id [String, nil] Associated organization ID
      # @param value [Numeric, nil] Deal value
      # @param currency [String] Currency code (default: USD)
      # @param expected_close_date [String, nil] Expected close date (ISO 8601)
      # @return [Deal] The created deal
      #
      # @example
      #   deal = client.sales.create_deal(
      #     label: "Enterprise License",
      #     pipeline_id: "pipe_xxx",
      #     value: 120000,
      #     currency: "USD",
      #     expected_close_date: "2026-06-30"
      #   )
      #
      def create_deal(label:, pipeline_id:, person_id: nil, organization_id: nil, value: nil, currency: "USD", expected_close_date: nil)
        body = { label: label, pipeline_id: pipeline_id, currency: currency }
        body[:person_id] = person_id if person_id
        body[:organization_id] = organization_id if organization_id
        body[:value] = value if value
        body[:expected_close_date] = _format_date(expected_close_date) if expected_close_date

        data = @client.post("/sales/v1/deals", body)
        Deal.new(data, client: @client)
      end

      # List deals, optionally filtered by pipeline.
      #
      # @param pipeline_id [String, nil] Filter by pipeline ID
      # @return [Array<Deal>] List of deals
      def list_deals(pipeline_id: nil)
        params = {}
        params[:pipeline_id] = pipeline_id if pipeline_id

        data = @client.get("/sales/v1/deals", params)
        (data["deals"] || []).map { |d| Deal.new(d, client: @client) }
      end

      # Get a deal by ID.
      #
      # @param id [String] Deal ID
      # @return [Deal] The deal
      def get_deal(id)
        data = @client.get("/sales/v1/deals/#{id}")
        Deal.new(data, client: @client)
      end

      # Update a deal.
      #
      # @param id [String] Deal ID
      # @param label [String, nil] New label
      # @param person_id [String, nil] New person ID
      # @param organization_id [String, nil] New organization ID
      # @param value [Numeric, nil] New value
      # @param currency [String, nil] New currency
      # @param expected_close_date [String, nil] New expected close date
      # @return [Deal] The updated deal
      def update_deal(id, label: nil, person_id: nil, organization_id: nil, value: nil, currency: nil, expected_close_date: nil)
        body = {}
        body[:label] = label if label
        body[:person_id] = person_id if person_id
        body[:organization_id] = organization_id if organization_id
        body[:value] = value if value
        body[:currency] = currency if currency
        body[:expected_close_date] = _format_date(expected_close_date) if expected_close_date

        data = @client.patch("/sales/v1/deals/#{id}", body)
        Deal.new(data, client: @client)
      end

      # Delete a deal.
      #
      # @param id [String] Deal ID
      # @return [void]
      def delete_deal(id)
        @client.delete("/sales/v1/deals/#{id}")
        nil
      end

      # Move a deal to a different pipeline stage.
      #
      # @param id [String] Deal ID
      # @param stage_id [String] Target stage ID
      # @return [Deal] The updated deal
      #
      # @example
      #   deal = client.sales.move_deal_stage("deal_xxx", stage_id: "stage_yyy")
      #
      def move_deal_stage(id, stage_id:)
        data = @client.post("/sales/v1/deals/#{id}/move", { stage_id: stage_id })
        Deal.new(data, client: @client)
      end

      # ============================================================
      # ACTIVITIES
      # ============================================================

      # Create a new activity.
      #
      # @param type [String] Activity type (use Tedo::ActivityType constants)
      # @param subject [String] Activity subject
      # @param description [String, nil] Activity description
      # @param due_date [String, Date, nil] Due date (ISO 8601 string or Date object)
      # @param due_time [String, nil] Due time (HH:MM)
      # @param duration_minutes [Integer, nil] Duration in minutes
      # @param assigned_to_id [String, nil] Member ID to assign the activity to
      # @param links [Array<Hash>, nil] Entity links (use Tedo::Link helpers)
      # @return [Activity] The created activity
      #
      # @example
      #   activity = client.sales.create_activity(
      #     type: Tedo::ActivityType::CALL,
      #     subject: "Discovery call with Acme",
      #     due_date: "2026-03-15",
      #     due_time: "14:00",
      #     duration_minutes: 30,
      #     links: [Tedo::Link.deal("deal_xxx")]
      #   )
      #
      def create_activity(type:, subject:, description: nil, due_date: nil, due_time: nil, duration_minutes: nil, assigned_to_id: nil, links: nil)
        body = { type: type, subject: subject }
        body[:description] = description if description
        body[:due_date] = _format_date(due_date) if due_date
        body[:due_time] = due_time if due_time
        body[:duration_minutes] = duration_minutes if duration_minutes
        body[:assigned_to_id] = assigned_to_id if assigned_to_id
        body[:links] = links if links

        data = @client.post("/sales/v1/activities", body)
        Activity.new(data, client: @client)
      end

      # List activities, optionally filtered.
      #
      # @param lead_id [String, nil] Filter by lead ID
      # @param deal_id [String, nil] Filter by deal ID
      # @param type [String, nil] Filter by activity type
      # @return [Array<Activity>] List of activities
      def list_activities(lead_id: nil, deal_id: nil, type: nil)
        params = {}
        params[:lead_id] = lead_id if lead_id
        params[:deal_id] = deal_id if deal_id
        params[:type] = type if type

        data = @client.get("/sales/v1/activities", params)
        (data["activities"] || []).map { |a| Activity.new(a, client: @client) }
      end

      # Get an activity by ID.
      #
      # @param id [String] Activity ID
      # @return [Activity] The activity
      def get_activity(id)
        data = @client.get("/sales/v1/activities/#{id}")
        Activity.new(data, client: @client)
      end

      # Update an activity.
      #
      # @param id [String] Activity ID
      # @param subject [String, nil] New subject
      # @param description [String, nil] New description
      # @param due_date [String, nil] New due date
      # @param due_time [String, nil] New due time
      # @param duration_minutes [Integer, nil] New duration in minutes
      # @return [Activity] The updated activity
      def update_activity(id, subject: nil, description: nil, due_date: nil, due_time: nil, duration_minutes: nil)
        body = {}
        body[:subject] = subject if subject
        body[:description] = description if description
        body[:due_date] = _format_date(due_date) if due_date
        body[:due_time] = due_time if due_time
        body[:duration_minutes] = duration_minutes if duration_minutes

        data = @client.patch("/sales/v1/activities/#{id}", body)
        Activity.new(data, client: @client)
      end

      # Delete an activity.
      #
      # @param id [String] Activity ID
      # @return [void]
      def delete_activity(id)
        @client.delete("/sales/v1/activities/#{id}")
        nil
      end

      # Mark an activity as completed (or uncompleted).
      #
      # @param id [String] Activity ID
      # @param completed [Boolean] Whether to mark as completed (default: true)
      # @return [Activity] The updated activity
      #
      # @example
      #   client.sales.complete_activity("act_xxx")
      #   client.sales.complete_activity("act_xxx", completed: false)  # undo
      #
      def complete_activity(id, completed: true)
        data = @client.post("/sales/v1/activities/#{id}/complete", { completed: completed })
        Activity.new(data, client: @client)
      end

      # ============================================================
      # NOTES
      # ============================================================

      # Create a note.
      #
      # @param content [String] Note content
      # @param author_id [String, nil] Author member ID
      # @param links [Array<Hash>, nil] Entity links (each with entity_type, entity_id, is_primary)
      # @return [Note] The created note
      #
      # @example
      #   note = client.sales.create_note(
      #     content: "Discussed pricing. Follow up next week.",
      #     links: [{ entity_type: "sales.deal", entity_id: "deal_xxx", is_primary: true }]
      #   )
      #
      def create_note(content:, author_id: nil, links: nil)
        body = { content: content }
        body[:author_id] = author_id if author_id
        body[:links] = links if links

        data = @client.post("/sales/v1/notes", body)
        Note.new(data, client: @client)
      end

      # List notes, optionally filtered.
      #
      # @param lead_id [String, nil] Filter by lead ID
      # @param deal_id [String, nil] Filter by deal ID
      # @return [Array<Note>] List of notes
      def list_notes(lead_id: nil, deal_id: nil)
        params = {}
        params[:lead_id] = lead_id if lead_id
        params[:deal_id] = deal_id if deal_id

        data = @client.get("/sales/v1/notes", params)
        (data["notes"] || []).map { |n| Note.new(n, client: @client) }
      end

      # Get a note by ID.
      #
      # @param id [String] Note ID
      # @return [Note] The note
      def get_note(id)
        data = @client.get("/sales/v1/notes/#{id}")
        Note.new(data, client: @client)
      end

      # Update a note.
      #
      # @param id [String] Note ID
      # @param content [String] New content
      # @return [Note] The updated note
      def update_note(id, content:)
        data = @client.patch("/sales/v1/notes/#{id}", { content: content })
        Note.new(data, client: @client)
      end

      # Delete a note.
      #
      # @param id [String] Note ID
      # @return [void]
      def delete_note(id)
        @client.delete("/sales/v1/notes/#{id}")
        nil
      end

      # ============================================================
      # CONTACT BASES
      # ============================================================

      # List all contact bases.
      #
      # @return [Array<ContactBase>] List of contact bases
      def list_contact_bases
        data = @client.get("/sales/v1/contact-bases")
        (data["contact_bases"] || []).map { |cb| ContactBase.new(cb, client: @client) }
      end

      # Get a contact base by ID.
      #
      # @param id [String] Contact base ID
      # @return [ContactBase] The contact base
      def get_contact_base(id)
        data = @client.get("/sales/v1/contact-bases/#{id}")
        ContactBase.new(data, client: @client)
      end

      # ============================================================
      # PERSONS
      # ============================================================

      # Create a person (contact) in a contact base.
      #
      # @param contact_base_id [String] Contact base ID
      # @param first_name [String] First name
      # @param last_name [String] Last name
      # @param email [String] Email address (default: "")
      # @param phone [String] Phone number (default: "")
      # @param linkedin_url [String, nil] LinkedIn profile URL
      # @return [Person] The created person
      #
      # @example
      #   person = client.sales.create_person(
      #     "cb_xxx",
      #     first_name: "Jane",
      #     last_name: "Doe",
      #     email: "jane@example.com",
      #     phone: "+1-555-0100"
      #   )
      #
      def create_person(contact_base_id, first_name: "", last_name: "", email: "", phone: "", linkedin_url: nil)
        body = {
          first_name: first_name,
          last_name: last_name,
          email: email,
          phone: phone
        }
        body[:linkedin_url] = linkedin_url if linkedin_url

        data = @client.post("/sales/v1/contact-bases/#{contact_base_id}/persons", body)
        Person.new(data, client: @client)
      end

      # List all persons in a contact base.
      #
      # @param contact_base_id [String] Contact base ID
      # @return [Array<Person>] List of persons
      def list_persons(contact_base_id)
        data = @client.get("/sales/v1/contact-bases/#{contact_base_id}/persons")
        (data["persons"] || []).map { |p| Person.new(p, client: @client) }
      end

      # Get a person by ID.
      #
      # @param id [String] Person ID
      # @return [Person] The person
      def get_person(id)
        data = @client.get("/sales/v1/persons/#{id}")
        Person.new(data, client: @client)
      end

      # Update a person.
      #
      # @param id [String] Person ID
      # @param full_name [String, nil] New full name
      # @param first_name [String, nil] New first name
      # @param last_name [String, nil] New last name
      # @param email [String, nil] New email
      # @param phone [String, nil] New phone
      # @param linkedin_url [String, nil] New LinkedIn URL
      # @return [Person] The updated person
      def update_person(id, full_name: nil, first_name: nil, last_name: nil, email: nil, phone: nil, linkedin_url: nil)
        body = {}
        body[:full_name] = full_name if full_name
        body[:first_name] = first_name if first_name
        body[:last_name] = last_name if last_name
        body[:email] = email if email
        body[:phone] = phone if phone
        body[:linkedin_url] = linkedin_url if linkedin_url

        data = @client.patch("/sales/v1/persons/#{id}", body)
        Person.new(data, client: @client)
      end

      # Delete a person.
      #
      # @param id [String] Person ID
      # @return [void]
      def delete_person(id)
        @client.delete("/sales/v1/persons/#{id}")
        nil
      end

      # ============================================================
      # ORGANIZATIONS
      # ============================================================

      # Create an organization (company) in a contact base.
      #
      # @param contact_base_id [String] Contact base ID
      # @param name [String] Organization name
      # @param website [String, nil] Website URL
      # @param linkedin_url [String, nil] LinkedIn page URL
      # @return [Organization] The created organization
      #
      # @example
      #   org = client.sales.create_organization(
      #     "cb_xxx",
      #     name: "Acme Corp",
      #     website: "https://acme.com"
      #   )
      #
      def create_organization(contact_base_id, name:, website: nil, linkedin_url: nil)
        body = { name: name }
        body[:website] = website if website
        body[:linkedin_url] = linkedin_url if linkedin_url

        data = @client.post("/sales/v1/contact-bases/#{contact_base_id}/organizations", body)
        Organization.new(data, client: @client)
      end

      # List all organizations in a contact base.
      #
      # @param contact_base_id [String] Contact base ID
      # @return [Array<Organization>] List of organizations
      def list_organizations(contact_base_id)
        data = @client.get("/sales/v1/contact-bases/#{contact_base_id}/organizations")
        (data["organizations"] || []).map { |o| Organization.new(o, client: @client) }
      end

      # Get an organization by ID.
      #
      # @param id [String] Organization ID
      # @return [Organization] The organization
      def get_organization(id)
        data = @client.get("/sales/v1/organizations/#{id}")
        Organization.new(data, client: @client)
      end

      # Update an organization.
      #
      # @param id [String] Organization ID
      # @param name [String, nil] New name
      # @param website [String, nil] New website URL
      # @param linkedin_url [String, nil] New LinkedIn URL
      # @return [Organization] The updated organization
      def update_organization(id, name: nil, website: nil, linkedin_url: nil)
        body = {}
        body[:name] = name if name
        body[:website] = website if website
        body[:linkedin_url] = linkedin_url if linkedin_url

        data = @client.patch("/sales/v1/organizations/#{id}", body)
        Organization.new(data, client: @client)
      end

      # Delete an organization.
      #
      # @param id [String] Organization ID
      # @return [void]
      def delete_organization(id)
        @client.delete("/sales/v1/organizations/#{id}")
        nil
      end

      private

      # Format a date value for the API.
      # Accepts String (passed through), Date/Time objects (ISO 8601), or anything with #to_s.
      #
      # @param value [String, Date, Time, #iso8601] The date value to format
      # @return [String] Formatted date string
      def _format_date(value)
        return value if value.is_a?(String)
        return value.iso8601 if value.respond_to?(:iso8601)

        value.to_s
      end
    end
  end
end
