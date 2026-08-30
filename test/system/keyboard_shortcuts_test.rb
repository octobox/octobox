# frozen_string_literal: true

require 'application_system_test_case'

class KeyboardShortcutsTest < ApplicationSystemTestCase
  setup do
    @user = create(:user, disable_confirmations: true)
    @notification1 = create(:notification, user: @user, subject_title: 'First notification')
    @notification2 = create(:notification, user: @user, subject_title: 'Second notification')
    @notification3 = create(:notification, user: @user, subject_title: 'Third notification')
    sign_in_as(@user)
  end

  test 'j moves cursor down the list' do
    assert_selector 'td.js-current'
    initial_row = find('td.js-current').ancestor('tr')

    send_keys 'j'
    sleep 0.1

    new_current = find('td.js-current').ancestor('tr')
    refute_equal initial_row[:id], new_current[:id]
  end

  test 'k moves cursor up the list' do
    send_keys 'j'
    sleep 0.1
    row_after_j = find('td.js-current').ancestor('tr')

    send_keys 'k'
    sleep 0.1

    row_after_k = find('td.js-current').ancestor('tr')
    refute_equal row_after_j[:id], row_after_k[:id]
  end

  test 'question mark opens help modal' do
    assert_no_selector '#help-box.show'

    send_keys :shift, '/'
    assert_selector '#help-box.show', wait: 2
    assert_text 'Keyboard shortcuts'
  end

  test 'escape closes help modal' do
    send_keys :shift, '/'
    assert_selector '#help-box.show', wait: 2

    send_keys :escape
    assert_no_selector '#help-box.show', wait: 2
  end

  test 'slash focuses search box' do
    send_keys '/'
    assert_equal 'search-box', page.evaluate_script('document.activeElement.id')
  end

  test 'x toggles checkbox on current row' do
    current_row = find('td.js-current').ancestor('tr')
    checkbox = current_row.find('input[type="checkbox"]', visible: :all)
    refute checkbox.checked?

    send_keys 'x'
    sleep 0.1

    assert checkbox.checked?

    send_keys 'x'
    sleep 0.1

    refute checkbox.checked?
  end

  test 's toggles star on current row' do
    current_row = find('td.js-current').ancestor('tr')
    star = current_row.find('.toggle-star')
    assert_includes star[:class], 'star-inactive'

    send_keys 's'
    sleep 0.3

    star = current_row.find('.toggle-star')
    assert_includes star[:class], 'star-active'
  end

  test 'n and p route pagination through Turbolinks' do
    create_list(:notification, 50, user: @user)
    visit '/'
    next_url = page.evaluate_script(<<~JS)
      (function() {
        var link = document.querySelector('.page-item:last-child .page-link');
        link.rel = 'next';
        return link.href;
      })()
    JS
    capture_turbolinks_visits

    send_keys 'n'
    assert_equal next_url, page.evaluate_script('window.lastTurbolinksVisit')

    visit '/?page=2'
    previous_url = page.evaluate_script(<<~JS)
      (function() {
        var link = document.querySelector('.page-item:first-child .page-link');
        link.rel = 'prev';
        return link.href;
      })()
    JS
    capture_turbolinks_visits
    send_keys 'p'
    assert_equal previous_url, page.evaluate_script('window.lastTurbolinksVisit')
  end

  def capture_turbolinks_visits
    page.execute_script(<<~JS)
      Turbolinks.visit = function(url) {
        window.lastTurbolinksVisit = new URL(url, window.location.href).href;
      };
    JS
  end

  def send_keys(*keys)
    find('body').send_keys(*keys)
  end
end
