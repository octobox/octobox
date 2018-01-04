module DatabaseConfig
  SUPPORTED_ADAPTERS = %w(mysql2 postgresql)

  class << self
    def adapter
      adapter = if ENV['DATABASE']
        ENV['DATABASE']
      else
        'postgresql'
      end

      unless SUPPORTED_ADAPTERS.include?(adapter)
        raise "Unsupported database adapter #{adapter} specified"
      end

      adapter
    end

    def username
      default = if is_mysql?
        'root'
      elsif Rails.env.production?
        'octobox'
      else
        ''
      end
      ENV.fetch('OCTOBOX_DATABASE_USERNAME') { default }
    end

    def encoding
      if is_mysql?
        'utf8mb4'
      else
        'unicode'
      end
    end

    def password
      ENV.fetch('OCTOBOX_DATABASE_PASSWORD') { '' }
    end

    def connection_pool
      ENV.fetch("RAILS_MAX_THREADS") { 5 }.to_i
    end

    def database_name(environment)
      ENV.fetch('OCTOBOX_DATABASE_NAME') { "octobox_#{environment}" }
    end

    def host
      ENV.fetch('OCTOBOX_DATABASE_HOST') { 'localhost' }
    end

    def is_mysql?
      adapter.downcase == 'mysql2'
    end

    def is_postgres?
      adapter.downcase == 'postgresql'
    end
  end
end
