# frozen_string_literal: true

class SyncSubjectWorker
  include Sidekiq::Worker
  sidekiq_options queue: :sync_subjects, unique: :until_and_while_executing

  def perform(remote_subject)
    subject = Subject.find_or_create_by(url: issue.url)
    subject.update({
      state: remote_subject.merged_at.present? ? 'merged' : remote_subject.state,
      author: remote_subject.user.login,
      html_url: remote_subject.html_url,
      created_at: remote_subject.created_at,
      updated_at: remote_subject.updated_at
    })
    subject.sync_involved_users
  end
end
