# frozen_string_literal: true

class SearchParser
  attr_accessor :freetext
  attr_accessor :operators

  def initialize(query)
    query = query.to_s
    @operators = {}

    groups = query.split(/(\-?\w+)(:)/).compact_blank.in_groups_of(3)

    groups.each_with_index do |group, i|
      if group.length == 3 && group[1] == ':'
        key = group[0].downcase.to_sym
        value = group[2].strip
        @operators[key] ||= []

        if i == groups.length - 1
          # if last group, split last item in group and add extras to free text
          if value[0] == "'"
            parts = value.split("'")
            value = parts[1]
            @freetext = parts[2].to_s.strip
          elsif value[0] == '"'
            parts = value.split('"')
            value = parts[1]
            @freetext = parts[2].to_s.strip
          else
            parts = value.split(' ')
            value = parts[0]
            @freetext = parts.drop(1).to_a.join(' ').strip
          end
        end

        value.split(',').each{ |v| @operators[key] << v }
      else
        @freetext = group.join(' ').strip
      end
    end
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
