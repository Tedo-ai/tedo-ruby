# frozen_string_literal: true

module Tedo
  # A sales note attached to a lead or deal.
  #
  # @example
  #   note = client.sales.get_note("note_xxx")
  #   note.id      # => "note_xxx"
  #   note.content # => "Discussed pricing options."
  #
  class Note < Resource
    attribute :id
    attribute :content
    attribute :created_at, type: :time
    attribute :updated_at, type: :time

    # Update this note.
    #
    # @param content [String] New content
    # @return [Note] The updated note
    def update(content:)
      raise "No client available" unless client

      client.sales.update_note(id, content: content)
    end

    # Delete this note.
    #
    # @return [void]
    def delete
      raise "No client available" unless client

      client.sales.delete_note(id)
    end
  end
end
