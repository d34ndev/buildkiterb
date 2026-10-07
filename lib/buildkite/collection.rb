module Buildkite
  class Collection
    include Enumerable

    attr_reader :data, :total, :page, :next_page_number

    # Fetches path and wraps the response. Buildkite pages results (30 per page by default,
    # 100 at most), so pass page: and per_page: in params to choose a page.
    def self.from_request(path, type:, params: {})
      response = Client.get_request(path, params: params)

      from_response(
        response,
        type: type,
        page: params[:page],
        next_page: ->(page) { from_request(path, type: type, params: params.merge(page: page)) }
      )
    end

    def self.from_response(response, type:, page: nil, next_page: nil)
      body = response.body

      new(
        data: body.map { |attrs| type.new(attrs) },
        total: body.count,
        page: page,
        next_page_number: page_from_link(response.headers["Link"], "next"),
        next_page: next_page
      )
    end

    # Reads the page number for a rel from a Link header, e.g.
    #   <https://api.buildkite.com/v2/builds?page=2&per_page=30>; rel="next"
    def self.page_from_link(header, rel)
      return unless header

      header.split(",").each do |link|
        next unless link.match?(/rel="#{rel}"/)

        url = link[/<([^>]+)>/, 1]
        number = url && url[/[?&]page=(\d+)/, 1]
        return number.to_i if number
      end

      nil
    end

    # total is the number of items on this page. Buildkite doesn't report an overall total.
    def initialize(data:, total:, page: nil, next_page_number: nil, next_page: nil)
      @data = data
      @total = total
      @page = page
      @next_page_number = next_page_number
      @next_page = next_page
    end

    def each(&block)
      data.each(&block)
    end

    def next_page?
      !@next_page.nil? && !next_page_number.nil?
    end

    # Fetches the following page, or returns nil on the last page
    def next_page
      @next_page.call(next_page_number) if next_page?
    end

    # Yields this page and each following page, fetching them as needed.
    # Returns an Enumerator without a block.
    def each_page
      return enum_for(:each_page) unless block_given?

      page = self

      while page
        yield page
        page = page.next_page
      end
    end

    # Lazily iterates over every item across all pages, fetching pages only as needed.
    #   Buildkite::Build.list(per_page: 100).auto_paginate.first(250)
    def auto_paginate
      each_page.lazy.flat_map(&:data)
    end
  end
end
