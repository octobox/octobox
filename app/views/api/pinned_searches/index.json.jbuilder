json.pinned_searches do
  json.array! @pinned_searches do |pinned_search|
    json.partial! 'api/pinned_searches/pinned_search', pinned_search: pinned_search
  end
end
