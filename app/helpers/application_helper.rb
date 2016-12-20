module ApplicationHelper
  def bootstrap_class_for(flash_type)
    { success: 'alert-success', error: 'alert-danger', alert: 'alert-warning', notice: 'alert-info' }[flash_type.to_sym] || flash_type.to_s
  end

  def flash_messages
    flash.each do |msg_type, message|
      concat(content_tag(:div, message, class: "alert #{bootstrap_class_for(msg_type)} fade in") do
        concat content_tag(:button, 'x', class: 'close', data: { dismiss: 'alert' })
        concat message
      end)
    end
    nil
  end

  def notification_icon(subject_type)
    case subject_type
    when 'RepositoryInvitation'
      'mail-read'
    when 'Issue'
      'issue-opened'
    when 'PullRequest'
      'git-pull-request'
    when 'Commit'
      'git-commit'
    end
  end

  def reason_label(reason)
    case reason
    when 'comment'
      'primary'
    when 'author'
      'success'
    when 'state_change'
      'info'
    when 'mention'
      'warning'
    when 'assign'
      'danger'
    when 'subscribed'
      'default'
    else
      'default'
    end
  end
end
