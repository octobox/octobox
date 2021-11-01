json.pinned_searches do
  json.array! @pinned_searches do |pinned_search|
    json.partial! pinned_search
  end
end
