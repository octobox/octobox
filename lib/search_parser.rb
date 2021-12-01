# frozen_string_literal: true

class SearchParser
  attr_accessor :freetext
  attr_accessor :operators

  def initialize(query)
    query = query.to_s
    @operators = {}

    ss = StringScanner.new(query)

    loop do
      # scan for key
      ss.scan_until(/([^'"]?\-?\w+):\s?/)
      if ss.captures
        key = ss.captures[0].strip.to_sym
        @operators[key] ||= []

        # scan for value
        value = ss.scan(/(("|')[^"']+('|")|(\+))|[^"'\s]+/)
        value.split(',').each{ |v| @operators[key] << v.strip }
      else
        break
      end
    end

    @freetext = ss.rest.strip
  end

  def [](key)
    values = @operators[key.to_sym] || []
    values.map do |value|
      if ["'", '"'].include?(value[0])
        value[1, value.length - 2]
      else
        value
      end
    end
  end

  def []=(key, value)
    @operators[key.to_sym] = value
  end
end
