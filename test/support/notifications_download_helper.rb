module NotificationDownloadHelper
  def stub_notifications_request(body: nil)
    notifications_url = %r{https://api.github.com/notifications}

    body     ||= file_fixture('notifications.json')
    headers  = { 'Content-Type' => 'application/json' }
    response = { status: 200, body: body, headers: headers }

    stub_request(:get, notifications_url).to_return(response)
  end
end
