class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.fast_total
    if DatabaseConfig.is_postgres?
      ActiveRecord::Base.count_by_sql "SELECT (reltuples)::integer FROM pg_class r WHERE relkind = 'r' AND relname = '#{self.table_name}'"
    else
      self.count
    end
  end
end
