# frozen_string_literal: true

require 'application_system_test_case'

class SearchSuggestionTest < ApplicationSystemTestCase
  setup do
    @user = create(:user)
    create(:notification, user: @user)
    sign_in_as(@user)
  end

  test 'createSuggestionListElement renders payload as text not html' do
    payload = '<img src=x onerror=window.xss_fired=true>'

    page.execute_script(<<~JS)
      var list = document.getElementById('search-sugguestion-list');
      list.appendChild(SearchSuggestion.createSuggestionListElement(#{payload.to_json}));
      list.classList.add('d-flex');
    JS

    li = find('#search-sugguestion-list li', visible: :all)
    assert_equal payload, li.find('div', match: :first, visible: :all).text(:all)
    assert_no_selector '#search-sugguestion-list img', visible: :all
    refute page.evaluate_script('window.xss_fired'), 'onerror handler executed'
  end

  test 'createDeleteButtonElement does not break out of data-suggestion attribute' do
    payload = "foo' onclick='window.xss_fired=true"

    page.execute_script(<<~JS)
      var list = document.getElementById('search-sugguestion-list');
      list.appendChild(SearchSuggestion.createDeleteButtonElement(#{payload.to_json}));
      list.classList.add('d-flex');
    JS

    btn = find('#search-sugguestion-list .search-remove-btn', visible: :all)
    assert_equal payload, btn['data-suggestion']
    assert_nil btn['onclick']
    refute page.evaluate_script('window.xss_fired')
  end

  test 'suggestion list round-trips through delete handler' do
    # Verify the data-suggestion attribute still feeds deleteSearchString correctly
    # after switching from string concat to setAttribute.
    page.execute_script(<<~JS)
      var list = document.getElementById('search-sugguestion-list');
      list.appendChild(SearchSuggestion.createSuggestionListElement('repo:octobox/octobox'));
      list.classList.add('d-flex');
    JS

    btn = find('#search-sugguestion-list .search-remove-btn', visible: :all)
    assert_equal 'repo:octobox/octobox', btn['data-suggestion']
  end
end
