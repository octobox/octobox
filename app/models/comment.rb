class Comment < ApplicationRecord
  belongs_to :subject

  def web_url
    "#{subject.html_url}#issuecomment-#{github_id}"
  end
end
