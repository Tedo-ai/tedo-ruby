# frozen_string_literal: true

module Tedo
  # A sales person (contact).
  #
  # @example
  #   person = client.sales.get_person("person_xxx")
  #   person.full_name # => "Jane Doe"
  #   person.email     # => "jane@example.com"
  #
  class Person < Resource
    attribute :id
    attribute :full_name
    attribute :first_name
    attribute :last_name
    attribute :email
    attribute :phone
    attribute :linkedin_url
    attribute :owner_id
    attribute :created_at, type: :time
    attribute :updated_at, type: :time

    # Update this person.
    #
    # @param full_name [String, nil] New full name
    # @param first_name [String, nil] New first name
    # @param last_name [String, nil] New last name
    # @param email [String, nil] New email
    # @param phone [String, nil] New phone
    # @param linkedin_url [String, nil] New LinkedIn URL
    # @return [Person] The updated person
    def update(full_name: nil, first_name: nil, last_name: nil, email: nil, phone: nil, linkedin_url: nil)
      raise "No client available" unless client

      client.sales.update_person(id, full_name: full_name, first_name: first_name,
                                     last_name: last_name, email: email, phone: phone,
                                     linkedin_url: linkedin_url)
    end

    # Delete this person.
    #
    # @return [void]
    def delete
      raise "No client available" unless client

      client.sales.delete_person(id)
    end
  end
end
