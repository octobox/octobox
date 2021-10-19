json.(
  notification,
  :id,
  :github_id,
  :reason,
  :unread,
  :archived,
  :starred,
  :url,
  :web_url,
  :last_read_at,
  :created_at,
  :updated_at,
)

json.subject do
  json.title notification.subject_title
  json.url notification.subject_url
  json.type notification.subject_type
  json.draft notification.draft?
  json.state notification.state
  json.author notification.subject.author if notification.display_subject? && notification.subject
end

json.repo do
  json.id notification.repository_id
  json.name notification.repository_full_name
  json.owner notification.repository_owner_name
  json.repo_url notification.repo_url
end
