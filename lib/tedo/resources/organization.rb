# frozen_string_literal: true

module Tedo
  # A sales organization (company).
  #
  # @example
  #   org = client.sales.get_organization("org_xxx")
  #   org.name    # => "Acme Corp"
  #   org.website # => "https://acme.com"
  #
  class Organization < Resource
    attribute :id
    attribute :name
    attribute :website
    attribute :linkedin_url
    attribute :owner_id
    attribute :created_at, type: :time
    attribute :updated_at, type: :time

    # Update this organization.
    #
    # @param name [String, nil] New name
    # @param website [String, nil] New website URL
    # @param linkedin_url [String, nil] New LinkedIn URL
    # @return [Organization] The updated organization
    def update(name: nil, website: nil, linkedin_url: nil)
      raise "No client available" unless client

      client.sales.update_organization(id, name: name, website: website,
                                           linkedin_url: linkedin_url)
    end

    # Delete this organization.
    #
    # @return [void]
    def delete
      raise "No client available" unless client

      client.sales.delete_organization(id)
    end
  end
end
