# frozen_string_literal: true
require 'test_helper'

class OpenCollectiveControllerTest < ActionDispatch::IntegrationTest
  setup do
    Octobox.stubs(:io?).returns(true)
    stub_notifications_request
    stub_fetch_subject_enabled(value: false)
    @transactionid = 165052
    @plan = create(:subscription_plan, name: 'Open Collective Individual')
    @user = create(:user)
  end

  test 'logged out visitor gets directed to login page' do
    get '/opencollective?transactionid=165052'
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
