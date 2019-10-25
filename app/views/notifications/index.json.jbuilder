json.pagination do
  json.total_notifications @total
  json.page @page
  json.total_pages((@total.to_f / @per_page).ceil)
  json.per_page @cur_selected
end

json.types @types
json.reasons @reasons
json.unread_repositories @unread_repositories

json.notifications do
  json.array! @notifications do |notification|
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
  end
end
