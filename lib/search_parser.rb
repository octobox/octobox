# frozen_string_literal: true
# Simplified version of https://github.com/marcelocf/searrrch/blob/f2825e26/lib/searrrch.rb

class SearchParser
  OPERATOR_EXPRESSION = /(\-?\w+):[\ 　]?([\w\p{Han}\p{Katakana}\p{Hiragana}\p{Hangul}ー\.\-,\/]+|(["'])(\\?.)*?\3)/

  attr_accessor :freetext
  attr_accessor :operators

  def initialize(query)
    query = query.to_s
    @operators = {}

    offset = 0
    while (m = OPERATOR_EXPRESSION.match(query, offset))
      key = m[1].downcase.to_sym
      value = m[2]
      offset = m.end(2)
      @operators[key] ||= []

      value.split(',').each{ |v| @operators[key] << v }
    end
    @freetext = query[offset, query.length].strip
  end

  def [](key)
    @operators[key.to_sym] || []
  end

  def []=(key, value)
    @operators[key.to_sym] = value
  end
end
