module PageLimitingOctokitClient
  def paginate(url, options = {})
    under_max_results = -> (data, max_results) {
      ! max_results || ! data.respond_to?(:size) || data.size < max_results
    }

    max_results = options.delete(:max_results)
    opts = parse_query_and_convenience_headers(options.dup)

    if @auto_paginate || @per_page
      opts[:query][:per_page] ||=  @per_page || (@auto_paginate ? 100 : nil)
    end

    data = request(:get, url, opts.dup)

    if @auto_paginate
      while @last_response.rels[:next] && rate_limit.remaining > 0 && under_max_results.call(data, max_results)
        @last_response = @last_response.rels[:next].get(:headers => opts[:headers])
        if block_given?
          yield(data, @last_response)
        else
          data.concat(@last_response.data) if @last_response.data.is_a?(Array)
        end
      end

    end
    data = data.first(max_results) if max_results && data.respond_to?(:first)
    data
  end
end
