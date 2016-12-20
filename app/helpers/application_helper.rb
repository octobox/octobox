module ApplicationHelper
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
