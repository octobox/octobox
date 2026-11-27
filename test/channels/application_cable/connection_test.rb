# frozen_string_literal: true
require 'test_helper'

module ApplicationCable
  class ConnectionTest < ActionCable::Connection::TestCase
    setup do
      add_permanent_to_test_cookie_jar
    end

    test 'connects as the user in the signed cookie' do
      user = create(:user)
      cookies.signed[:user_id] = user.id

      connect

      assert_equal user, connection.current_user
    end

    test 'rejects a connection without a user cookie' do
      assert_reject_connection { connect }
    end

    test 'rejects a connection for a user that no longer exists' do
      cookies.signed[:user_id] = 0

      assert_reject_connection { connect }
    end

    def add_permanent_to_test_cookie_jar
      cookies.define_singleton_method(:permanent) { self }
    end
  end
end
