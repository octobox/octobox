class EnablePgStatStatementsExtension < ActiveRecord::Migration[5.2]
  def change
    enable_extension 'pg_stat_statements'
  end
end
