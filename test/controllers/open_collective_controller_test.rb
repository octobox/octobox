# frozen_string_literal: true
require 'test_helper'

class OpenCollectiveControllerTest < ActionDispatch::IntegrationTest
  setup do
    Octobox.stubs(:io?).returns(true)
    stub_notifications_request
    stub_repository_request
    stub_comments_requests
    stub_fetch_subject_enabled(value: false)
    @transactionid = 165052
    @plan = create(:subscription_plan, name: 'Open Collective Individual')
    @user = create(:user)
  end

  test 'route is only available on octobox.io' do
    sign_in_as(@user)
    Octobox.stubs(:io?).returns(false)
    get "/opencollective?transactionid=#{@transactionid}"
    assert_response :redirect
    assert_redirected_to '/422'
    assert_equal 'This page is only available on https://octobox.io', flash[:error]
  end

  test 'logged out visitor gets directed to login page' do
    get "/opencollective?transactionid=#{@transactionid}"
    assert_response :redirect
    refute @user.has_personal_plan?
  end

  test 'logged in visitor gets account upgraded' do
    sign_in_as(@user)

    stub_request(:get, "https://api.opencollective.com/v1/collectives/octobox/transactions/#{@transactionid}?apiKey=")
                .to_return({ status: 200, body: file_fixture('oc_transaction.json')})

    get "/opencollective?transactionid=#{@transactionid}"
    assert_response :redirect
    assert_redirected_to '/'
    assert @user.has_personal_plan?
  end

  test 'logged in visitor doesnt get upgraded if api errors' do
    sign_in_as(@user)

    stub_request(:get, "https://api.opencollective.com/v1/collectives/octobox/transactions/#{@transactionid}?apiKey=")
                .to_return({ status: 400, body: file_fixture('oc_error.json')})

    get "/opencollective?transactionid=#{@transactionid}"
    assert_response :redirect
    assert_redirected_to '/pricing'
    refute @user.has_personal_plan?
  end
end
