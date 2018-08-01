# frozen_string_literal: true
require 'test_helper'

class UserSettingTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
  end

  test 'initialized user setting and new_tab by true' do
    assert @user.user_settings.new_tab
  end
end
