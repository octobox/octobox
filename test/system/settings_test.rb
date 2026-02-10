# frozen_string_literal: true

require 'application_system_test_case'

class SettingsTest < ApplicationSystemTestCase
  setup do
    @user = create(:user, disable_confirmations: true)
    create(:pinned_search, user: @user, name: 'Archivable', query: 'state:closed,merged archived:false')
    sign_in_as(@user)
  end

  test 'pinned search form fields are inline' do
    visit settings_path

    within '#pinned-searches form' do
      assert_selector '.row .col input[placeholder="Name"]'
      assert_selector '.row .col input[placeholder="Search Query"]'
      assert_selector '.row .col-auto input[value="Save"]'

      name_input = find('input[placeholder="Name"]')
      query_input = find('input[placeholder="Search Query"]')
      save_button = find('input[value="Save"]')

      name_y = name_input.evaluate_script('this.getBoundingClientRect().top')
      query_y = query_input.evaluate_script('this.getBoundingClientRect().top')
      save_y = save_button.evaluate_script('this.getBoundingClientRect().top')

      assert_in_delta name_y, query_y, 5, 'Name and Search Query inputs should be on the same row'
      assert_in_delta name_y, save_y, 5, 'Name input and Save button should be on the same row'
    end
  end
end
