module DatabaseConfig
  SUPPORTED_ADAPTERS = %w(postgresql)

  class << self
    # The current adapter being used
    # Takes into account DATABASE_URL
    #
    def adapter
      adapter = if ENV['DATABASE_URL']
                  ENV['DATABASE_URL'].split(":").first
                elsif ENV['DATABASE']
                  ENV['DATABASE']
                else
                  'postgresql'
                end

      # Allow postgres://... as the Heroku buildpack dues
      adapter = 'postgresql' if adapter == 'postgres'

      unless SUPPORTED_ADAPTERS.include?(adapter)
        raise "Unsupported database adapter #{adapter} specified"
      end

      adapter
    end

    # Name for the database
    # Overridden by DATABASE_URL
    #
    def database_name(environment)
      database_url_or_fallback('database') do
        ENV.fetch('OCTOBOX_DATABASE_NAME') { "octobox_#{environment}" }
      end
    end

    # Host for the database
    # Overridden by DATABASE_URL
    #
    def host
      database_url_or_fallback('host') do
        ENV.fetch('OCTOBOX_DATABASE_HOST') { 'localhost' }
      end
    end

    # Password for the database
    # Overridden by DATABASE_URL
    #
    def password
      database_url_or_fallback('password') do
        ENV.fetch('OCTOBOX_DATABASE_PASSWORD') { '' }
      end
    end

    # Username for the database
    # Overridden by DATABASE_URL
    #
    def username
      database_url_or_fallback('username') do
        default = if Rails.env.production?
                    'octobox'
                  else
                    ''
                  end
        ENV.fetch('OCTOBOX_DATABASE_USERNAME') { default }
      end
    end

    # Encoding for the database
    # Overridden by DATABASE_URL
    #
    def encoding
      database_url_or_fallback('encoding') do
        'unicode'
      end
    end

    # Port for the database
    # Overridden by DATABASE_URL
    #
    def port
      database_url_or_fallback('port') do
        ENV.fetch('OCTOBOX_DATABASE_PORT') { 5432 }
      end
    end

    # Connection Pool count for the database
    #
    def connection_pool
      database_url_or_fallback('pool') do
        ENV.fetch("RAILS_MAX_THREADS") { 5 }.to_i
      end.to_i
    end

    def timeout
      database_url_or_fallback('timeout') do
        ENV.fetch("OCTOBOX_STATEMENT_TIMEOUT") { 10000 }.to_i
      end.to_i
    end

    private

    def database_url_or_fallback(var)
      val = database_url_config[var] if ENV['DATABASE_URL']
      val || yield
    end

    def database_url_config
      ActiveRecord::DatabaseConfigurations::ConnectionUrlResolver.new(ENV['DATABASE_URL']).to_hash.stringify_keys
    end
  end
end
