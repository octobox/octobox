require 'test_helper'

class SearchParserTest < ActiveSupport::TestCase
  test 'only free text' do
    query = 'I only contain free text'
    search = SearchParser.new query
    assert_equal search.freetext, query
  end

  test 'after one option' do
    freetext = 'this is an example freetext'
    query = "option1: value #{freetext}"
    search = SearchParser.new query
    assert_equal search.freetext, freetext
  end

  test 'after one option ending with "' do
    freetext = 'this is an example freetext'
    query = "option1: \"a bigger value\" #{freetext}"
    search = SearchParser.new query
    assert_equal search.freetext, freetext
  end

  test 'after one option ending with \'' do
    freetext = 'this is an example freetext'
    query = "option1: \'a bigger value\' #{freetext}"
    search = SearchParser.new query
    assert_equal search.freetext, freetext
  end

  test 'with lots of ending and beginning spaces' do
    freetext = 'this is an example freetext'
    query = "option1: \'a bigger value\'     #{freetext}    "
    search = SearchParser.new query
    assert_equal search.freetext, freetext
  end

  test 'containing : but not as an operator' do
    freetext = 'this is an example with : freetext'
    query = "option1: \'a bigger value\' #{freetext}"
    search = SearchParser.new query
    assert_equal search.freetext, freetext
  end

  test 'only one as string' do
    query = 'operator: value'
    search = SearchParser.new query
    assert_equal search[:operator], ['value']
  end

  test 'has one operator with \'' do
    query = 'operator: \'123 is lol\''
    search = SearchParser.new query
    assert_equal search[:operator], ['123 is lol']
  end

  test 'has one operator with "' do
    query = 'operator: "123 is lol"'
    search = SearchParser.new query
    assert_equal search[:operator], ['123 is lol']
  end

  test 'has multiple operators with "' do
    query = 'operator: "123 is lol" otheroperator: "12" operator: "other value"'
    search = SearchParser.new query
    assert_equal search[:operator], ['123 is lol', 'other value']
  end
   #
  test 'has multiple operators with \'' do
    query = 'operator: \'123 is lol\' otheroperator: \'12\' operator: \'other value\''
    search = SearchParser.new query
    assert_equal search[:operator], ['123 is lol', 'other value']
  end

  test 'has multiple operators with \' and "' do
    query = 'operator: \'123 is " lol\' otheroperator: \'12\' operator: "other \' value"'
    search = SearchParser.new query
    assert_equal search[:operator], ["123 is \" lol", "other ' value"]
  end

  test 'has multiple operators with \' and " return as array' do
    query = 'operator: \'123 is " lol\' otheroperator: \'12\' operator: "other \' value"'
    values = ['123 is " lol', 'other \' value']
    search = SearchParser.new query
    assert_equal search[:operator], values
  end

  test 'explodes the comma' do
    query = 'user_id: 1,2,3,4'
    search = SearchParser.new query
    assert_equal search[:user_id], ['1','2','3','4']
  end

  test 'allows - in prefix' do
    query = '-repo:octobox/octobox,foo/bar'
    search = SearchParser.new query
    assert_equal search[:'-repo'], ['octobox/octobox','foo/bar']
  end
end
