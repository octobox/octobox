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
    json.partial! notification
  end
end
