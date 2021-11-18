require 'test_helper'

class ApiNotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Octobox.config.stubs(:github_app).returns(false)
    stub_background_jobs_enabled(value: false)
    stub_fetch_subject_enabled(value: false)
    stub_notifications_request
    stub_repository_request
    stub_comments_requests
    @user = create(:user)
  end

  test 'renders the index page as json if authenticated' do
    get api_notifications_path(format: :json), headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_response :success
    assert_template 'notifications/index', file: 'notifications/index.json.jbuilder'
  end

  test 'will render 401 if not authenticated as json' do
    get api_notifications_path(format: :json)
    assert_response :unauthorized
  end

  test 'shows archived search results by default' do
    5.times.each { create(:notification, user: @user, archived: true, subject_title:'release-1') }
    get '/api/notifications?q=release', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 5
  end

  test 'shows only 20 notifications per page' do
    25.times.each { create(:notification, user: @user, archived: false) }

    get '/api/notifications', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 20
  end

  test 'redirect back to last page of results if page is out of bounds' do
    25.times.each { create(:notification, user: @user, archived: false) }

    get '/api/notifications?page=3', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_redirected_to '/api/notifications?page=2'
  end

  test 'redirect back to last page of results if page is out of bounds and send filters' do
    25.times.each { create(:notification, user: @user, archived: false, unread: true) }

    get '/api/notifications?page=3&reason=subscribed&unread=true', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_redirected_to '/api/notifications?page=2&reason=subscribed&unread=true'
  end

  test 'archives multiple notifications' do
    notification1 = create(:notification, user: @user, archived: false)
    notification2 = create(:notification, user: @user, archived: false)
    notification3 = create(:notification, user: @user, archived: false)

    stub_request(:patch, /https:\/\/api.github.com\/notifications\/threads/)

    post '/api/notifications/archive_selected', params: { id: [notification1.id, notification2.id], value: true }, xhr: true, headers: { 'Authorization' => "Bearer #{@user.api_token}" }

    assert_response :ok

    assert notification1.reload.archived?
    assert notification2.reload.archived?
    refute notification3.reload.archived?
  end

  test 'archives all notifications' do
    notification1 = create(:notification, user: @user, archived: false)
    notification2 = create(:notification, user: @user, archived: false)
    notification3 = create(:notification, user: @user, archived: false)

    stub_request(:patch, /https:\/\/api.github.com\/notifications\/threads/)

    post '/api/notifications/archive_selected', params: { id: ['all'], value: true }, xhr: true, headers: { 'Authorization' => "Bearer #{@user.api_token}" }

    assert_response :ok

    assert notification1.reload.archived?
    assert notification2.reload.archived?
    assert notification3.reload.archived?
  end

  test 'archives respects current filters' do
    notification1 = create(:notification, user: @user, archived: false, unread: false)
    notification2 = create(:notification, user: @user, archived: false)
    notification3 = create(:notification, user: @user, archived: false)

    post '/api/notifications/archive_selected', params: { unread: true, id: ['all'], value: true }, xhr: true, headers: { 'Authorization' => "Bearer #{@user.api_token}" }

    assert_response :ok

    refute notification1.reload.archived?
    assert notification2.reload.archived?
    assert notification3.reload.archived?
  end

  test 'archives defaults value to true' do
    notification1 = create(:notification, user: @user, archived: false)
    notification2 = create(:notification, user: @user, archived: false)

    post '/api/notifications/archive_selected', params: { unread: true, id: ['all'], value: nil }, xhr: true, headers: { 'Authorization' => "Bearer #{@user.api_token}" }

    assert_response :ok

    assert notification1.reload.archived?
    assert notification2.reload.archived?
  end

  test 'mutes multiple notifications' do
    notification1 = create(:notification, user: @user, archived: false)
    notification2 = create(:notification, user: @user, archived: false)
    create(:notification, user: @user, archived: false)

    Notification.expects(:mute).with([notification1, notification2])

    post '/api/notifications/mute_selected', params: { id: [notification1.id, notification2.id] }, xhr: true, headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_response :ok
  end

  test 'mutes all notifications in current scope' do
    Notification.destroy_all
    notification1 = create(:notification, user: @user, archived: false)
    notification2 = create(:notification, user: @user, archived: false)
    notification3 = create(:notification, user: @user, archived: false)

    Notification.expects(:mute).with([notification1, notification2, notification3])

    post '/api/notifications/mute_selected', params: { id: ['all'] }, xhr: true, headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_response :ok
  end

  test 'marks read multiple notifications' do

    notification1 = create(:notification, user: @user, archived: false)
    notification2 = create(:notification, user: @user, archived: false)
    create(:notification, user: @user, archived: false)

    Notification.expects(:mark_read).with([notification1, notification2])

    post '/api/notifications/mark_read_selected', params: { id: [notification1.id, notification2.id] }, headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_response :ok
  end

  test 'marks read all notifications' do

    Notification.destroy_all
    notification1 = create(:notification, user: @user, archived: false)
    notification2 = create(:notification, user: @user, archived: false)
    notification3 = create(:notification, user: @user, archived: false)

    Notification.expects(:mark_read).with([notification1, notification2, notification3])

    post '/api/notifications/mark_read_selected', params: { id: ['all'] }, headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_response :ok
  end

  test 'toggles starred on a notification' do
    notification = create(:notification, user: @user, starred: false)

    post "/api/notifications/#{notification.id}/star", headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_response :ok

    assert notification.reload.starred?
  end

  test 'syncs users notifications async' do
    stub_background_jobs_enabled
    # Initial sync means we won't enqueue a sync immediately on login
    sign_in_as(@user, initial_sync: true)
    job_id = @user.sync_job_id

    inline_sidekiq_status do
      get "/api/notifications/sync", headers: { 'Authorization' => "Bearer #{@user.api_token}" }
      @user.reload

      assert_response :success
      assert_equal 1, SyncNotificationsWorker.jobs.size
      assert_not_equal job_id, @user.sync_job_id
      assert_not_nil @user.sync_job_id, 'Sync job id was nil'
    end
  end

  test 'syncs users notifications as json' do
    post "/api/notifications/sync.json", headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_response :success
  end

  test 'gracefully handles failed user notification syncs as json' do
    User.any_instance.stubs(:sync_notifications_in_foreground).raises(Octokit::BadGateway)

    post "/api/notifications/sync.json", headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_response :service_unavailable
  end

  test 'gracefully handles failed user notification syncs with bad token as json' do
    User.any_instance.stubs(:sync_notifications_in_foreground).raises(Octokit::Unauthorized)

    post "/api/notifications/sync.json", headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_response :service_unavailable
  end

  test 'gracefully handles failed user notification syncs when user is offline as json' do
    User.any_instance.stubs(:sync_notifications_in_foreground).raises(Faraday::ConnectionFailed.new('offline error'))

    post "/api/notifications/sync.json", headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_response :service_unavailable
  end

  test 'syncing returns ok when not syncing' do
    User.any_instance.expects(:syncing?).returns(false)
    get "/api/notifications/syncing.json", headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_response :ok
  end

  test 'syncing returns locked when not syncing' do
    User.any_instance.expects(:syncing?).returns(true)
    get "/api/notifications/syncing.json", headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_response :locked
  end

  test 'renders pagination info for notifications in json' do
    get api_notifications_path(format: :json), headers: { 'Authorization' => "Bearer #{@user.api_token}" }

    assert_response :success
    json = Oj.load(response.body)
    notification_count = Notification.inbox.where(user: @user).count
    assert_equal notification_count, json["pagination"]["total_notifications"]
    assert_equal 0, json["pagination"]["page"]
    assert_equal (notification_count.to_f / 20).ceil, json["pagination"]["total_pages"]
    assert_equal [notification_count, 20].min, json["pagination"]["per_page"]
  end

  test 'renders author for notifications in json' do
    skip("This test fails intermittenly")

    notification = create(:notification, user: @user, subject_type: 'Issue')
    create(:subject, notifications: [notification], author: 'andrew')

    get api_notifications_path(format: :json), headers: { 'Authorization' => "Bearer #{@user.api_token}" }

    assert_response :success
    json = Oj.load(response.body)
    found_notification = json["notifications"].find { |n| n["id"] == notification.id }
    assert found_notification["subject"]["author"]
  end

  test 'renders pagination info for zero notifications in json' do
    Notification.destroy_all

    get api_notifications_path(format: :json), headers: { 'Authorization' => "Bearer #{@user.api_token}" }

    assert_response :success
    json = Oj.load(response.body)
    assert_equal 0, json["pagination"]["total_notifications"]
    assert_equal 0, json["pagination"]["page"]
    assert_equal 0, json["pagination"]["total_pages"]
    assert_equal 0, json["pagination"]["per_page"]
  end

  test 'renders a union of notifications when multiple reasons given' do
    Notification.destroy_all

    notification1 = create(:notification, user: @user, archived: false, reason: "assign")
    notification2 = create(:notification, user: @user, archived: false, reason: "mention")
    notification3 = create(:notification, user: @user, archived: false, reason: "subscribed")

    get api_notifications_path(format: :json, reason: "assign,mention"), headers: { 'Authorization' => "Bearer #{@user.api_token}" }

    assert_response :success

    json = Oj.load(response.body)
    notification_ids = json["notifications"].map { |n| n["id"] }

    assert notification_ids.include?(notification1.id)
    assert notification_ids.include?(notification2.id)
    refute notification_ids.include?(notification3.id)
  end

  test 'search results can filter by repo' do
    create(:notification, user: @user, repository_full_name: 'a/b')
    create(:notification, user: @user, repository_full_name: 'b/c')
    get '/api/notifications?q=repo%3Aa%2Fb', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1
  end

  test 'search results can filter by multiple repo' do
    create(:notification, user: @user, repository_full_name: 'a/b')
    create(:notification, user: @user, repository_full_name: 'b/c')
    get '/api/notifications?q=repo%3Aa%2Fb%2Cb%2Fc', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 2
  end

  test 'search results can filter to exclude a repo' do
    @user.notifications.delete_all
    create(:notification, user: @user, repository_full_name: 'a/b')
    create(:notification, user: @user, repository_full_name: 'b/c')
    get '/api/notifications?q=-repo%3Aa%2Fb', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1
    assert_equal assigns(:notifications).first.repository_full_name, 'b/c'
  end

  test 'search results can filter to exclude multiple repos' do
    @user.notifications.delete_all
    create(:notification, user: @user, repository_full_name: 'a/b')
    create(:notification, user: @user, repository_full_name: 'b/c')
    get '/api/notifications?q=-repo%3Aa%2Fb%2Cb%2Fc', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 0
  end

  test 'search results can filter by owner' do
    create(:notification, user: @user, repository_owner_name: 'andrew')
    create(:notification, user: @user, repository_owner_name: 'octobox')
    get '/api/notifications?q=owner%3Aoctobox', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1
  end

  test 'search results can filter by multiple owners' do
    @user.notifications.delete_all
    create(:notification, user: @user, repository_owner_name: 'andrew')
    create(:notification, user: @user, repository_owner_name: 'octobox')
    get '/api/notifications?q=owner%3Aoctobox%2Candrew', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 2
  end

  test 'search results can filter to exclude owner' do
    @user.notifications.delete_all
    create(:notification, user: @user, repository_owner_name: 'andrew')
    create(:notification, user: @user, repository_owner_name: 'octobox')
    get '/api/notifications?q=-owner%3Aoctobox', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1
    assert_equal assigns(:notifications).first.repository_owner_name, 'andrew'
  end

  test 'search results can filter to exclude multiple owners' do

    @user.notifications.delete_all
    create(:notification, user: @user, repository_owner_name: 'andrew')
    create(:notification, user: @user, repository_owner_name: 'octobox')
    get '/api/notifications?q=-owner%3Aoctobox%2Candrew', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 0
  end

  test 'search results can filter by type' do
    create(:notification, user: @user, subject_type: 'Issue')
    create(:notification, user: @user, subject_type: 'PullRequest')
    get '/api/notifications?q=type%3Apull_request', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1
  end

  test 'search results can filter to exclude type' do
    @user.notifications.delete_all
    create(:notification, user: @user, subject_type: 'Issue')
    create(:notification, user: @user, subject_type: 'PullRequest')
    get '/api/notifications?q=-type%3Apull_request', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1
    assert_equal assigns(:notifications).first.subject_type, 'Issue'
  end

  test 'search results can filter by reason' do
    create(:notification, user: @user, reason: 'assign')
    create(:notification, user: @user, reason: 'mention')
    get '/api/notifications?q=reason%3Amention', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1
  end

  test 'search results can filter to exclude reason' do
    @user.notifications.delete_all
    create(:notification, user: @user, reason: 'assign')
    create(:notification, user: @user, reason: 'mention')
    get '/api/notifications?q=-reason%3Amention', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1
    assert_equal assigns(:notifications).first.reason, 'assign'
  end

  test 'search results can filter by starred' do
    create(:notification, user: @user, starred: true)
    create(:notification, user: @user, starred: false)
    get '/api/notifications?q=starred%3Atrue', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1
  end

  test 'search results can filter by archived' do
    create(:notification, user: @user, archived: true)
    create(:notification, user: @user, archived: false)
    get '/api/notifications?q=archived%3Atrue', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1
  end

  test 'search results can filter by inbox' do
    @user.notifications.delete_all
    create(:notification, user: @user, archived: true)
    notification2 = create(:notification, user: @user, archived: false)
    get '/api/notifications?q=inbox%3Atrue', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1
    assert_equal assigns(:notifications).to_a, [notification2]
  end

  test 'search results can filter by unread' do
    create(:notification, user: @user, unread: true)
    create(:notification, user: @user, unread: false)
    get '/api/notifications?q=unread%3Afalse', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1
  end

  test 'search results can filter by author' do
    notification1 = create(:notification, user: @user, subject_type: 'Issue')
    notification2 = create(:notification, user: @user, subject_type: 'PullRequest')
    create(:subject, notifications: [notification1], author: 'andrew')
    create(:subject, notifications: [notification2], author: 'benjam')
    get '/api/notifications?q=author%3Aandrew', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1
  end

  test 'search results can filter by number' do
    notification1 = create(:notification, user: @user, subject_type: 'Issue')
    notification2 = create(:notification, user: @user, subject_type: 'PullRequest')
    subject1 = create(:subject, notifications: [notification1])
    subject2 = create(:subject, notifications: [notification2])
    get '/api/notifications?q=number%3A' + subject1.url.scan(/\d+$/).first, headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1
    assert_equal assigns(:notifications).first.subject_url, subject1.url
  end

  test 'search results can filter by multiple numbers' do
    notification1 = create(:notification, user: @user, subject_type: 'Issue')
    notification2 = create(:notification, user: @user, subject_type: 'PullRequest')
    subject1 = create(:subject, notifications: [notification1])
    subject2 = create(:subject, notifications: [notification2])
    get '/api/notifications?q=number%3A' + subject1.url.scan(/\d+$/).first + '%2C' + subject2.url.scan(/\d+$/).first, headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 2
  end

  test 'search results can filter by draft' do
    notification1 = create(:notification, user: @user, subject_type: 'PullRequest')
    notification2 = create(:notification, user: @user, subject_type: 'PullRequest')
    create(:subject, notifications: [notification1], author: 'andrew', draft: false)
    create(:subject, notifications: [notification2], author: 'benjam', draft: true)
    get '/api/notifications?q=draft%3Atrue', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1
  end

  test 'search results can filter by multiple authors' do
    notification1 = create(:notification, user: @user, subject_type: 'Issue')
    notification2 = create(:notification, user: @user, subject_type: 'PullRequest')
    create(:subject, notifications: [notification1], author: 'andrew')
    create(:subject, notifications: [notification2], author: 'benjam')
    get '/api/notifications?q=author%3Aandrew%2Cbenjam', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 2
  end

  test 'search results can filter to exclude author' do
    notification1 = create(:notification, user: @user, subject_type: 'Issue')
    notification2 = create(:notification, user: @user, subject_type: 'PullRequest')
    create(:subject, notifications: [notification1], author: 'andrew')
    create(:subject, notifications: [notification2], author: 'benjam')
    get '/api/notifications?q=-author%3Aandrew', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1
    assert_equal assigns(:notifications).first.subject.author, 'benjam'
  end

  test 'search results can filter to exclude multiple authors' do
    notification1 = create(:notification, user: @user, subject_type: 'Issue')
    notification2 = create(:notification, user: @user, subject_type: 'PullRequest')
    create(:subject, notifications: [notification1], author: 'andrew')
    create(:subject, notifications: [notification2], author: 'benjam')
    get '/api/notifications?q=-author%3Aandrew%2Cbenjam', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 0
  end

  test 'search results can filter by label' do
    notification1 = create(:notification, user: @user)
    notification2 = create(:notification, user: @user)
    subject1 = create(:subject, notifications: [notification1])
    subject2 = create(:subject, notifications: [notification2])
    create(:label, subject: subject1, name: 'bug')
    create(:label, subject: subject2, name: 'feature')
    get '/api/notifications?q=label%3Abug', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1
  end

  test 'search results can filter by label with quotes' do
    notification1 = create(:notification, user: @user)
    notification2 = create(:notification, user: @user)
    subject1 = create(:subject, notifications: [notification1])
    subject2 = create(:subject, notifications: [notification2])
    create(:label, subject: subject1, name: '1 bug')
    create(:label, subject: subject2, name: '2 feature')
    get '/api/notifications?q=label%3A"1+bug"', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1
  end

  test 'search results can filter by multiple labels' do
    notification1 = create(:notification, user: @user)
    notification2 = create(:notification, user: @user)
    subject1 = create(:subject, notifications: [notification1])
    subject2 = create(:subject, notifications: [notification2])
    create(:label, subject: subject1, name: 'bug')
    create(:label, subject: subject2, name: 'feature')
    get '/api/notifications?q=label%3Abug%2Cfeature', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 2
  end

  test 'search results can filter to exclude label' do
    notification1 = create(:notification, user: @user)
    notification2 = create(:notification, user: @user)
    subject1 = create(:subject, notifications: [notification1])
    subject2 = create(:subject, notifications: [notification2])
    create(:label, subject: subject1, name: 'bug')
    create(:label, subject: subject2, name: 'feature')
    get '/api/notifications?q=-label%3Abug', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1
    assert_equal assigns(:notifications).first.labels.first.name, 'feature'
  end

  test 'search results can filter to exclude multiple labels' do
    notification1 = create(:notification, user: @user)
    notification2 = create(:notification, user: @user)
    subject1 = create(:subject, notifications: [notification1])
    subject2 = create(:subject, notifications: [notification2])
    create(:label, subject: subject1, name: 'bug')
    create(:label, subject: subject2, name: 'feature')
    get '/api/notifications?q=-label%3Abug%2Cfeature', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 0
  end

  test 'search results can filter by state' do
    notification1 = create(:notification, user: @user)
    notification2 = create(:notification, user: @user)
    create(:subject, notifications: [notification1], state: "open")
    create(:subject, notifications: [notification2], state: "closed")
    get '/api/notifications?q=state%3Aopen', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1
  end

  test 'search results can filter by multiple states' do
    notification1 = create(:notification, user: @user)
    notification2 = create(:notification, user: @user)
    create(:subject, notifications: [notification1], state: "open")
    create(:subject, notifications: [notification2], state: "closed")
    get '/api/notifications?q=state%3Aopen%2Cclosed', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 2
  end

  test 'search results can filter to exclude state' do
    notification1 = create(:notification, user: @user)
    notification2 = create(:notification, user: @user)
    create(:subject, notifications: [notification1], state: "open")
    create(:subject, notifications: [notification2], state: "closed")
    get '/api/notifications?q=-state%3Aopen', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1
    assert_equal assigns(:notifications).first.subject.state, 'closed'
  end

  test 'search results can filter to exclude multiple states' do
    notification1 = create(:notification, user: @user)
    notification2 = create(:notification, user: @user)
    create(:subject, notifications: [notification1], state: "open")
    create(:subject, notifications: [notification2], state: "closed")
    get '/api/notifications?q=-state%3Aopen%2Cclosed', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 0
  end

  test 'search results can filter by assignee' do
    notification1 = create(:notification, user: @user)
    notification2 = create(:notification, user: @user)
    create(:subject, notifications: [notification1], assignees: ":andrew:")
    create(:subject, notifications: [notification2], assignees: ":benjam:")
    get '/api/notifications?q=assignee%3Aandrew', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1
  end

  test 'search results can filter by multiple assignees' do
    notification1 = create(:notification, user: @user)
    notification2 = create(:notification, user: @user)
    create(:subject, notifications: [notification1], assignees: ":andrew:")
    create(:subject, notifications: [notification2], assignees: ":benjam:")
    get '/api/notifications?q=assignee%3Aandrew%2Cbenjam', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 2
  end

  test 'search results can filter to exclude assignee' do
    notification1 = create(:notification, user: @user)
    notification2 = create(:notification, user: @user)
    create(:subject, notifications: [notification1], assignees: ":andrew:")
    create(:subject, notifications: [notification2], assignees: ":benjam:")
    get '/api/notifications?q=-assignee%3Aandrew', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1
    assert_equal assigns(:notifications).first.subject.assignees, ":benjam:"
  end

  test 'search results can filter to exclude multiple assignees' do
    notification1 = create(:notification, user: @user)
    notification2 = create(:notification, user: @user)
    create(:subject, notifications: [notification1], assignees: ":andrew:")
    create(:subject, notifications: [notification2], assignees: ":benjam:")
    get '/api/notifications?q=-assignee%3Aandrew%2Cbenjam', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 0
  end

  test 'search results can filter by locked:true' do
    notification1 = create(:notification, user: @user, subject_type: 'Issue')
    notification2 = create(:notification, user: @user, subject_type: 'PullRequest')
    create(:subject, notifications: [notification1], locked: true)
    create(:subject, notifications: [notification2], locked: true)
    get '/api/notifications?q=locked%3Atrue', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 2
  end

  test 'search results can filter by locked:false' do
    notification1 = create(:notification, user: @user, subject_type: 'Issue')
    notification2 = create(:notification, user: @user, subject_type: 'PullRequest')
    create(:subject, notifications: [notification1], locked: false)
    create(:subject, notifications: [notification2], locked: true)
    get '/api/notifications?q=locked%3Afalse', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1
  end

  test 'search results can filter by muted:true' do
    create(:notification, user: @user, muted_at: Time.current)
    create(:notification, user: @user)
    get '/api/notifications?q=muted%3Atrue', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1
  end

  test 'search results can filter by muted:false' do
    Notification.destroy_all
    create(:notification, user: @user, muted_at: Time.current)
    create(:notification, user: @user)
    get '/api/notifications?q=muted%3Afalse', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1
  end

  test "doesn't set the per_page cookie" do
    get '/api/notifications?per_page=100'
    assert_equal nil, cookies[:per_page]
  end

  test 'ignores the per_page cookie' do
    get '/?per_page=100'
    get '/api/notifications'
    assert_equal assigns(:per_page), nil
  end

  test 'archives false Unarchives the notifications' do
    notification1 = create(:notification, user: @user, archived: true)
    create(:notification, user: @user, archived: true)
    stub_request(:patch, /https:\/\/api.github.com\/notifications\/threads/)

    post '/api/notifications/archive_selected', params: { id: [notification1.id], value: false }, xhr: true, headers: { 'Authorization' => "Bearer #{@user.api_token}" }

    assert_response :ok

    assert !notification1.reload.archived?
  end

  test 'renders results by status' do
    notification1 = create(:notification, user: @user, subject_type: 'PullRequest')
    notification2 = create(:notification, user: @user, subject_type: 'PullRequest')
    notification3 = create(:notification, user: @user, subject_type: 'PullRequest')
    notification4 = create(:notification, user: @user, subject_type: 'PullRequest')
    notification5 = create(:notification, user: @user, subject_type: 'PullRequest')
    create(:subject, notifications: [notification1], status: 'failure')
    create(:subject, notifications: [notification2], status: 'success')
    create(:subject, notifications: [notification3], status: 'pending')
    create(:subject, notifications: [notification4])
    create(:subject, notifications: [notification5], status: 'failure')

    get '/api/notifications?status=success', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1

    get '/api/notifications?status=failure', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 2

    get '/api/notifications?status=pending', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1
  end

  test 'search results can filter by status' do
    notification1 = create(:notification, user: @user, subject_type: 'PullRequest')
    notification2 = create(:notification, user: @user, subject_type: 'PullRequest')
    notification3 = create(:notification, user: @user, subject_type: 'PullRequest')
    notification4 = create(:notification, user: @user, subject_type: 'PullRequest')
    create(:subject, notifications: [notification1], status: 'failure')
    create(:subject, notifications: [notification2], status: 'success')
    create(:subject, notifications: [notification3], status: 'pending')
    create(:subject, notifications: [notification4])

    get '/api/notifications?q=status%3Asuccess', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1

    get '/api/notifications?q=status%3Afailure', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1

    get '/api/notifications?q=status%3Apending', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1
  end

  test 'search results can filter by only bot' do
    notification1 = create(:notification, user: @user)
    notification2 = create(:notification, user: @user)
    notification3 = create(:notification, user: @user)
    create(:subject, notifications: [notification1], author: 'dependabot[bot]')
    create(:subject, notifications: [notification2], author: 'py-bot')
    create(:subject, notifications: [notification3], author: 'andrew')

    get '/api/notifications?q=bot%3Atrue', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 2
  end

  test 'search results can exclude bots' do
    notification1 = create(:notification, user: @user)
    notification2 = create(:notification, user: @user)
    notification3 = create(:notification, user: @user)
    create(:subject, notifications: [notification1], author: 'dependabot[bot]')
    create(:subject, notifications: [notification2], author: 'py-bot')
    create(:subject, notifications: [notification3], author: 'andrew')

    get '/api/notifications?q=bot%3Afalse', headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_equal assigns(:notifications).length, 1
  end

  test 'renders the lookup page as json if authenticated' do
    notification = create(:notification, user: @user)

    get lookup_api_notifications_path(format: :json, url: notification.web_url), headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_response :success
    assert_template 'notifications/lookup', file: 'notifications/lookup.json.jbuilder'
  end

  test 'renders an empty object for the lookup page as json if authenticated and no url passed' do
    get lookup_api_notifications_path(format: :json), headers: { 'Authorization' => "Bearer #{@user.api_token}" }
    assert_response :success
    assert_equal '{}', response.body
  end
end
