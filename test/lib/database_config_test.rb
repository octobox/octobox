require 'test_helper'

class DatabaseConfigTest < ActiveSupport::TestCase
  DB_URL = "mysql2://user:password2@host.com:1234/database_name?pool=15&encoding=db_url_encoding"

  test 'chooses the right DB' do
    if ENV['DATABASE']
      assert_equal ENV['DATABASE'].downcase, ActiveRecord::Base.connection.adapter_name.downcase
    else
      assert_equal 'PostgreSQL', ActiveRecord::Base.connection.adapter_name
    end
  end

  test 'adapter is specified properly' do
    set_env('DATABASE_URL', DB_URL) do
      assert_equal 'mysql2', DatabaseConfig.adapter
    end

    set_env('DATABASE', 'mysql2') do
      assert_equal 'mysql2', DatabaseConfig.adapter
    end

    set_env('DATABASE', 'postgresql') do
      assert_equal 'postgresql', DatabaseConfig.adapter
    end

    set_env('DATABASE', 'invalid_db') do
      assert_raises do
        DatabaseConfig.adapter
      end
    end
  end

  test 'username is specified properly' do
    set_env('DATABASE_URL', DB_URL) do
      assert_equal 'user', DatabaseConfig.username
    end

    set_env('DATABASE', 'mysql2') do
      assert_equal 'root', DatabaseConfig.username
    end

    set_env('DATABASE', 'postgresql') do
      assert_equal '', DatabaseConfig.username
    end

    set_env('OCTOBOX_DATABASE_USERNAME', 'my_username') do |val|
      assert_equal val, DatabaseConfig.username
    end

    set_env('DATABASE', 'postgresql') do
      Rails.env.expects(:production?).returns(true)
      assert_equal 'octobox', DatabaseConfig.username
    end
  end

  test 'encoding is specified properly' do
    set_env('DATABASE_URL', DB_URL) do
      assert_equal 'db_url_encoding', DatabaseConfig.encoding
    end

    set_env('DATABASE', 'mysql2') do
      assert_equal 'utf8mb4', DatabaseConfig.encoding
    end

    set_env('DATABASE', 'postgresql') do
      assert_equal 'unicode', DatabaseConfig.encoding
    end
  end

  test 'password is specified properly' do
    set_env('DATABASE_URL', DB_URL) do
      assert_equal 'password2', DatabaseConfig.password
    end

    set_env('DATABASE', 'mysql2') do
      assert_equal '', DatabaseConfig.password
    end

    set_env('DATABASE', 'postgresql') do
      assert_equal '', DatabaseConfig.password
    end

    set_env('OCTOBOX_DATABASE_PASSWORD', 'my_password') do |val|
      assert_equal val, DatabaseConfig.password
    end
  end

  test 'connection_pool is specified properly' do
    set_env('DATABASE_URL', DB_URL) do
      assert_equal 15, DatabaseConfig.connection_pool
    end

    set_env('DATABASE', 'mysql2') do
      assert_equal 5, DatabaseConfig.connection_pool
    end

    set_env('DATABASE', 'postgresql') do
      assert_equal 5, DatabaseConfig.connection_pool
    end

    set_env('RAILS_MAX_THREADS', 10) do |val|
      assert_equal val, DatabaseConfig.connection_pool
    end
  end

  test 'database_name is specified properly' do
    set_env('DATABASE_URL', DB_URL) do
      assert_equal 'database_name', DatabaseConfig.database_name('test')
    end

    set_env('DATABASE', 'mysql2') do
      assert_equal 'octobox_test', DatabaseConfig.database_name('test')
    end

    set_env('DATABASE', 'postgresql') do
      assert_equal 'octobox_test', DatabaseConfig.database_name('test')
    end

    set_env('OCTOBOX_DATABASE_NAME', 'my_database') do |val|
      assert_equal val, DatabaseConfig.database_name('test')
    end
  end

  test 'host is specified properly' do
    set_env('DATABASE_URL', DB_URL) do
      assert_equal 'host.com', DatabaseConfig.host
    end

    set_env('DATABASE', 'postgresql') do
      assert_equal 'localhost', DatabaseConfig.host
    end

    set_env('DATABASE', 'mysql2') do
      assert_equal 'localhost', DatabaseConfig.host
    end

    set_env('OCTOBOX_DATABASE_HOST', '127.0.0.1') do |val|
      assert_equal val, DatabaseConfig.host
    end
  end

  test 'is_mysql? and is_postgres?' do
    set_env('DATABASE_URL', DB_URL) do
      assert DatabaseConfig.is_mysql?, 'was not mysql, it should have been'
      refute DatabaseConfig.is_postgres?, 'was postgres, it should not have been'
    end

    set_env('DATABASE', 'postgresql') do
      assert DatabaseConfig.is_postgres?, 'was not postgres, it should have been'
      refute DatabaseConfig.is_mysql?, 'was mysql, it should not have been'
    end

    set_env('DATABASE', 'mysql2') do
      assert DatabaseConfig.is_mysql?, 'was not mysql, it should have been'
      refute DatabaseConfig.is_postgres?, 'was postgres, it should not have been'
    end
  end

  test 'port is specified properly' do
    set_env('DATABASE_URL', DB_URL) do
      assert_equal 1234, DatabaseConfig.port
    end

    set_env('OCTOBOX_DATABASE_PORT', "1234") do |val|
      assert_equal val, DatabaseConfig.port
    end
  end
end
