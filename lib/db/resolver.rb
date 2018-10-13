module Db
  class Resolver

    attr_accessor :db

    def initialize
      @db ||= adapter
    end

    def adapter
      if DatabaseConfig.is_mysql? || ActiveRecord::Base.connection.instance_values["config"][:adapter] == "mysql"
        return Db::Mysql.new
      else
        return Db::Postgres.new
      end
    end

  end
end