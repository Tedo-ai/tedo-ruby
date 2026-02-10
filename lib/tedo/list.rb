# frozen_string_literal: true

module Tedo
  # A paginated list of resources.
  #
  # Provides Enumerable access to the current page and auto-pagination
  # to iterate through all pages transparently.
  #
  # @example Iterate current page
  #   list = client.billing.list_customers(limit: 10)
  #   list.each { |customer| puts customer.email }
  #
  # @example Check pagination info
  #   list.total        # => 150
  #   list.has_more?    # => true
  #   list.next_cursor  # => "cursor_abc123"
  #
  # @example Get next page
  #   next_page = list.next_page
  #
  # @example Auto-paginate through all results
  #   client.billing.list_customers.auto_paging_each do |customer|
  #     puts customer.email
  #   end
  #
  class List
    include Enumerable

    # @return [Array<Resource>] Resources on the current page
    attr_reader :data

    # @return [Integer] Total count across all pages
    attr_reader :total

    # @return [String, nil] Cursor for the next page
    attr_reader :next_cursor

    # @return [Client] The client for fetching more pages
    attr_reader :client

    # @param data [Array<Resource>] Resources on this page
    # @param total [Integer] Total count
    # @param next_cursor [String, nil] Cursor for next page
    # @param client [Client] Client for pagination
    # @param fetch_page [Proc] Proc to fetch the next page
    def initialize(data:, total:, next_cursor:, client:, fetch_page:)
      @data = data
      @total = total
      @next_cursor = next_cursor
      @client = client
      @fetch_page = fetch_page
    end

    # Iterate over resources on the current page.
    #
    # @yield [Resource] Each resource
    # @return [Enumerator] if no block given
    def each(&block)
      return enum_for(:each) unless block_given?

      @data.each(&block)
    end

    # Number of resources on the current page.
    #
    # @return [Integer]
    def count
      @data.length
    end
    alias size count
    alias length count

    # Check if there are more pages.
    #
    # @return [Boolean]
    def has_more?
      !@next_cursor.nil? && !@next_cursor.empty?
    end

    # Fetch the next page of results.
    #
    # @return [List, nil] The next page, or nil if no more pages
    def next_page
      return nil unless has_more?

      @fetch_page.call(@next_cursor)
    end

    # Iterate through ALL pages, fetching automatically.
    #
    # @yield [Resource] Each resource across all pages
    # @return [Enumerator] if no block given
    #
    # @example
    #   client.billing.list_customers.auto_paging_each do |customer|
    #     puts customer.email
    #   end
    #
    # @example With Enumerator
    #   all_emails = client.billing.list_customers
    #                      .auto_paging_each
    #                      .map(&:email)
    #
    def auto_paging_each
      return enum_for(:auto_paging_each) unless block_given?

      page = self
      loop do
        page.each { |item| yield item }
        break unless page.has_more?
        page = page.next_page
      end
    end

    # Collect ALL resources across all pages.
    #
    # @return [Array<Resource>]
    # @note Use with caution on large datasets
    def auto_paging_to_a
      auto_paging_each.to_a
    end

    # First resource on the current page.
    #
    # @return [Resource, nil]
    def first
      @data.first
    end

    # Last resource on the current page.
    #
    # @return [Resource, nil]
    def last
      @data.last
    end

    # Check if the current page is empty.
    #
    # @return [Boolean]
    def empty?
      @data.empty?
    end
  end
end
