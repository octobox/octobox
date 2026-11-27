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
    @transaction = Oj.load(file_fixture('oc_transaction.json').read)
    @transaction['result']['createdAt'] = 2.minutes.ago.utc.strftime('%a %b %d %Y %H:%M:%S GMT+0000 (UTC)')
  end

  def stub_transaction(id: @transactionid, body: Oj.dump(@transaction))
    stub_request(:get, "https://api.opencollective.com/v1/collectives/octobox/transactions/#{id}?apiKey=")
      .to_return({ status: 200, body: body })
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
    stub_transaction

    get "/opencollective?transactionid=#{@transactionid}"
    assert_response :redirect
    assert_redirected_to '/'
    assert @user.has_personal_plan?
  end

  test 'logged in visitor doesnt get upgraded if api errors' do
    sign_in_as(@user)
    stub_transaction(body: file_fixture('oc_error.json').read)

    get "/opencollective?transactionid=#{@transactionid}"
    assert_response :redirect
    assert_redirected_to '/pricing'
    refute @user.has_personal_plan?
  end

  test 'rejects a non-integer transaction id without calling the api' do
    sign_in_as(@user)

    get "/opencollective?transactionid=5/../../../other/transactions/#{@transactionid}"
    assert_response :redirect
    assert_redirected_to '/pricing'
    refute @user.has_personal_plan?
  end

  test 'rejects a transaction to another collective' do
    sign_in_as(@user)
    @transaction['result']['collective']['slug'] = 'other-project'
    stub_transaction

    get "/opencollective?transactionid=#{@transactionid}"
    assert_redirected_to '/pricing'
    refute @user.has_personal_plan?
  end

  test 'rejects a debit transaction' do
    sign_in_as(@user)
    @transaction['result']['type'] = 'DEBIT'
    stub_transaction

    get "/opencollective?transactionid=#{@transactionid}"
    assert_redirected_to '/pricing'
    refute @user.has_personal_plan?
  end

  test 'rejects a transaction over an hour old' do
    sign_in_as(@user)
    @transaction['result']['createdAt'] = 2.hours.ago.utc.strftime('%a %b %d %Y %H:%M:%S GMT+0000 (UTC)')
    stub_transaction

    get "/opencollective?transactionid=#{@transactionid}"
    assert_redirected_to '/pricing'
    refute @user.has_personal_plan?
  end
end
