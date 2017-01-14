
class DownloadService
  attr_accessor :user

  def initialize(user)
    @user = user
  end

  def github_client
    user.github_client
  end

  API_ATTRIBUTE_MAP = {
    repository_id: [:repository, :id],
    repository_full_name: [:repository, :full_name],
    repository_owner_name: [:repository, :owner, :login],
    subject_title: [:subject, :title],
    subject_type: [:subject, :type],
    subject_url: [:subject, :url],
    reason: [:reason],
    unread: [:unread],
    updated_at: [:updated_at],
    last_read_at: [:last_read_at],
    url: [:url],
    github_id: [:id]
  }.freeze

end
