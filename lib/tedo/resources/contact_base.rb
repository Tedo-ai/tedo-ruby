# frozen_string_literal: true

module Tedo
  # A contact base for organizing persons and organizations.
  #
  # @example
  #   base = client.sales.get_contact_base("cb_xxx")
  #   base.name # => "Customers"
  #
  class ContactBase < Resource
    attribute :id
    attribute :name
    attribute :created_at, type: :time
    attribute :updated_at, type: :time
  end
end
