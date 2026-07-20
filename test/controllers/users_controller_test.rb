require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    stub_fetch_subject_enabled(value: false)
    stub_notifications_request
    stub_comments_requests
    @user = create(:user)
  end

  def create_token_user
    stub_personal_access_tokens_enabled
    stub_user_request(user: build(:token_user))
    @token_user = create(:token_user)
  end

  test 'does not get profile as html' do
    create_token_user
    sign_in_as(@token_user)
    stub_user_request(user: @token_user, any_auth: true)
    assert_raises ActionController::UrlGenerationError do
      get profile_users_path
    end
  end

  test 'gets profile as json' do
    create_token_user
    sign_in_as(@token_user)
    stub_user_request(user: @token_user, any_auth: true)
    get profile_users_path(format: :json)
    assert_template 'users/profile'
  end

  test 'displays settings page' do
    sign_in_as(@user)
    get settings_path
    assert_response :success
    assert_template 'users/edit'
  end

  test 'displays settings page with saved search' do
    sign_in_as(@user)
    create(:pinned_search, user: @user)
    get settings_path
    assert_template 'users/edit'
  end

  test 'assigns latest git sha on settings page' do
    sign_in_as(@user)
    get settings_path
    assert_response :success
  end

  test 'extension page allows return_to on the configured github domain' do
    Octobox.stubs(:io?).returns(true)
    sign_in_as(@user)
    get '/extension', params: { return_to: 'https://github.com/octobox/octobox/issues/1' }
    assert_response :success
    assert_equal 'https://github.com/octobox/octobox/issues/1', assigns(:return_to)
  end

  test 'extension page rejects javascript: return_to' do
    Octobox.stubs(:io?).returns(true)
    sign_in_as(@user)
    get '/extension', params: { return_to: 'javascript:alert(1)' }
    assert_response :success
    assert_equal Octobox.config.github_domain, assigns(:return_to)
  end

  test 'extension page rejects lookalike domain in return_to' do
    Octobox.stubs(:io?).returns(true)
    sign_in_as(@user)
    get '/extension', params: { return_to: 'https://github.com.evil.com/foo' }
    assert_response :success
    assert_equal Octobox.config.github_domain, assigns(:return_to)
  end

  test 'extension page falls back to github domain when return_to is blank' do
    Octobox.stubs(:io?).returns(true)
    sign_in_as(@user)
    get '/extension'
    assert_response :success
    assert_equal Octobox.config.github_domain, assigns(:return_to)
  end

  test 'extension page does not render inline onclick' do
    Octobox.stubs(:io?).returns(true)
    sign_in_as(@user)
    get '/extension', params: { return_to: 'https://github.com/octobox/octobox' }
    assert_response :success
    refute_includes response.body, 'onclick'
    assert_select 'a.js-enable-extension[data-api-token=?]', @user.api_token
    assert_select 'a.js-enable-extension[data-return-to=?]', 'https://github.com/octobox/octobox'
  end

  test 'extension page go-to-github link uses validated return_to' do
    Octobox.stubs(:io?).returns(true)
    sign_in_as(@user)
    get '/extension', params: { return_to: 'javascript:alert(1)' }
    assert_response :success
    assert_select '#installed-extension a.btn-primary[href=?]', Octobox.config.github_domain
    assert_select 'a[href^="javascript:"]', false
  end

  test 'updates api_token' do
    sign_in_as(@user)
    token = @user.api_token
    patch user_url(@user), params: {user: {regenerate_api_token: '1'}}
    @user.reload
    assert_not_equal token, @user.api_token
  end

  test 'updates personal_access_token' do
    create_token_user
    sign_in_as(@token_user)
    stub_user_request(user: @token_user, any_auth: true)
    patch user_url(@token_user), params: {user: {personal_access_token: '12345'}}
    @token_user.reload
    assert_equal '12345', @token_user.personal_access_token
  end

  test 'updates personal_access_token as json' do
    create_token_user
    sign_in_as(@token_user)
    stub_user_request(user: @token_user, any_auth: true)
    patch user_url(@token_user, format: :json), params: {user: {personal_access_token: '12345'}}
    assert_response :ok
    @token_user.reload
    assert_equal '12345', @token_user.personal_access_token
  end

  test 'will not clear personal access token if clear_personal_access_token is not set' do
    create_token_user
    stub_user_request(user: @token_user)
    sign_in_as(@token_user)
    expected_token = @token_user.personal_access_token
    patch user_url(@token_user), params: {user: {personal_access_token: ' '}}
    @token_user.reload
    assert_equal expected_token, @token_user.personal_access_token
  end

  test 'clears personal access token when clear_personal_access_token is set' do
    create_token_user
    stub_user_request(user: @token_user)
    sign_in_as(@token_user)
    patch user_url(@token_user), params: {user: {personal_access_token: 'asdf'}, clear_personal_access_token: 'on'}
    @token_user.reload
    assert_nil @token_user.personal_access_token
  end

  test 'requires logged in user' do
    create_token_user
    stub_user_request(user: @token_user)
    expected_token = @token_user.personal_access_token
    patch user_url(@token_user), params: {user: {personal_access_token: '12345'}}
    assert_redirected_to root_path
    @token_user.reload
    assert_equal expected_token, @token_user.personal_access_token
  end

  test 'rejects changing a different user' do
    create_token_user
    stub_user_request(user: @token_user)
    sign_in_as(@user)
    expected_token = @token_user.personal_access_token
    patch user_url(@token_user), params: {user: {personal_access_token: '12345'}}
    assert_response :unauthorized
    @token_user.reload
    assert_equal expected_token, @token_user.personal_access_token
    assert_nil @user.personal_access_token
  end

  test 'deletes a user' do
    sign_in_as(@user)
    delete user_url(@user)
    assert_redirected_to root_path
    assert_equal "User deleted: #{@user.github_login}", flash[:success]
    refute User.exists?(@user.id)
  end

  test 'deletes a user as json' do
    sign_in_as(@user)
    delete user_url(@user, format: :json)
    assert_response :ok
    refute User.exists?(@user.id)
  end

  test 'exports notifications as downloadable json' do
    sign_in_as(@user, initial_sync: true)
    notification1 = create(:notification, user: @user)
    notification2 = create(:notification, user: @user)

    get export_path

    assert_response :success
    assert_includes response.headers['Content-Type'], 'application/json'
    assert_equal 'attachment; filename=octobox.json', response.headers['Content-Disposition']

    exported_ids = JSON.parse(response.body).map { |notification| notification['id'] }
    assert_equal [notification1.id, notification2.id], exported_ids
  end

  test 'exports an empty notification list' do
    sign_in_as(@user, initial_sync: true)

    get export_path

    assert_response :success
    assert_equal [], JSON.parse(response.body)
  end

  test 'cannot delete another user' do
    other_user = create(:user)
    sign_in_as(other_user)
    delete user_url(@user)
    assert_response :unauthorized
    assert User.exists?(@user.id)
    assert User.exists?(other_user.id)
  end

  test 'cannot delete user without logging in' do
    delete user_url(@user)
    assert_redirected_to root_path
    assert User.exists?(@user.id)
  end

  test 'sets refresh_interval' do
    stub_user_request(user: @user)
    sign_in_as(@user)
    patch user_url(@user), params: {user: {refresh_interval: 12_345}}
    @user.reload
    assert_equal 12_345, @user.refresh_interval
  end

  [{
     refresh_interval_minutes: 2,
     expected_refresh_interval: 120_000
   },
   {
     refresh_interval_minutes: '',
     expected_refresh_interval: nil
   },
   {
     refresh_interval_minutes: 1500,
     expected_refresh_interval: nil
   }].each do |t|
    test "sets refresh_interval to #{t[:expected_refresh_interval] || 'nil'} when refresh_interval_minutes is '#{t[:refresh_interval_minutes]}'" do
      sign_in_as(@user)
      patch user_url(@user), params: {user: {refresh_interval_minutes: t[:refresh_interval_minutes]}}
      @user.reload
      if t[:expected_refresh_interval].nil?
        assert_nil @user.refresh_interval
      else
        assert_equal t[:expected_refresh_interval], @user.refresh_interval
      end
    end
  end

  test 'rejects negative refresh_interval' do
    stub_user_request(user: @user)
    sign_in_as(@user)
    patch user_url(@user), params: {user: {refresh_interval: -60_000}}
    @user.reload
    assert_nil @user.refresh_interval
  end

  test 'rejects negative refresh_interval as json' do
    stub_user_request(user: @user)
    sign_in_as(@user)
    patch user_url(@user, format: :json), params: {user: {refresh_interval: -60_000}}
    @user.reload
    assert_nil @user.refresh_interval
    assert_response :unprocessable_content
  end

  test 'imports notifications from a valid file' do
    sign_in_as(@user)
    notification = create(:notification, user: @user)
    file = fixture_file_upload_json([notification.attributes.slice('github_id').merge('unread' => false)])
    post '/import', params: {file: file}
    assert_redirected_to root_path
    assert_equal 'Import complete', flash[:success]
  end

  test 'rejects import without a file' do
    sign_in_as(@user)
    post '/import'
    assert_redirected_to '/settings'
    assert_equal 'Please choose a file to import', flash[:error]
  end

  test 'rejects import with invalid JSON' do
    sign_in_as(@user)
    file = Rack::Test::UploadedFile.new(StringIO.new('not valid json'), 'application/json', original_filename: 'octobox.json')
    post '/import', params: {file: file}
    assert_redirected_to '/settings'
    assert_equal 'Could not import file: invalid JSON', flash[:error]
  end

  private

  def fixture_file_upload_json(data)
    Rack::Test::UploadedFile.new(StringIO.new(data.to_json), 'application/json', original_filename: 'octobox.json')
  end
end
