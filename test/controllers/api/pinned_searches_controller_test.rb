require 'test_helper'

class ApiPinnedSearchesControllerTest < ActionDispatch::IntegrationTest
  setup do
    stub_fetch_subject_enabled(value: false)
    stub_notifications_request
    stub_comments_requests
    @user = create(:user)
  end

  # todo doesnt work with cookies

  test 'creates new saved searches' do
    post api_pinned_searches_path, params: { pinned_search: {name: 'Work', query: 'owner:octobox'} }, headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_response :success
    assert_template 'pinned_searches/show', file: 'pinned_searches/show.json.jbuilder'
    assert_equal @user.pinned_searches.count, 4
  end

  test 'updates saved searches' do
    pinned_search = create(:pinned_search, user: @user)
    put api_pinned_search_path(pinned_search), params: { pinned_search: {name: 'Work', query: pinned_search.query + " type:issue"} }, headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_response :success
    assert_template 'pinned_searches/show', file: 'pinned_searches/show.json.jbuilder'
    pinned_search.reload
    assert_equal pinned_search.query, "inbox:true owner:octobox type:issue"
  end

  test 'will only update saved searches owned by the current user' do
    other_user = create(:user)
    pinned_search = create(:pinned_search, user: other_user)
    assert_raises ActiveRecord::RecordNotFound do
      put api_pinned_search_path(pinned_search), params: { pinned_search: {name: 'Work', query: pinned_search.query + " type:issue"} }, headers: { 'Authorization' => "Bearer #{@user.api_token}" }
      assert_response :not_found
    end
  end

  test 'will delete a saved search' do
    pinned_search = create(:pinned_search, user: @user)
    delete "/api/pinned_searches/#{pinned_search.id}", headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_response :success
    assert_equal @user.pinned_searches.count, 3
  end

  test 'will only delete saved searches owned by the current user' do
    other_user = create(:user)
    pinned_search = create(:pinned_search, user: other_user)
    assert_raises ActiveRecord::RecordNotFound do
      delete "/api/pinned_searches/#{pinned_search.id}", headers: { 'Authorization' => "Bearer #{@user.api_token}" }
      assert_response :not_found
    end

    assert_equal other_user.pinned_searches.count, 4
  end

  test 'will show json for json format' do
    pinned_search = create(:pinned_search, user: @user)

    get "/api/pinned_searches/#{pinned_search.id}.json", headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_response :success
    assert_template 'pinned_searches/show', file: 'pinned_searches/show.json.jbuilder'

    expected_attributes = {
      'id'      => pinned_search.id,
      'user_id' => pinned_search.user_id,
      'query'   => pinned_search.query,
      'name'    => pinned_search.name,
      'count'   => 0,
    }
    actual_response = JSON.parse(@response.body)
    expected_attributes.each do |attribute, value|
      assert_equal value, actual_response[attribute],
        "Expected pinned_search.#{attribute} to be #{value}, but it was #{actual_response[value]}. Full response: #{actual_response}"
    end
  end

  test 'will list pinned_searches as json for json format' do
    pinned_search = create(:pinned_search, user: @user)

    get "/api/pinned_searches.json", headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_response :success
    assert_template 'pinned_searches/index', file: 'pinned_searches/index.json.jbuilder'

    actual_response = JSON.parse(@response.body)
    assert_equal actual_response.length, 1
  end
end
