if ENV["ACTIVE_RECORD_QUERY_TRACE"].present?
  ActiveRecordQueryTrace.enabled = true
  ActiveRecordQueryTrace.level = :app
  ActiveRecordQueryTrace.colorize = true
end