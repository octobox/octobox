class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.fast_total
    ActiveRecord::Base.count_by_sql "SELECT (reltuples)::integer FROM pg_class r WHERE relkind = 'r' AND relname = '#{self.table_name}'"
  end
end
