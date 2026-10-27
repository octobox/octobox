# frozen_string_literal: true

require 'application_system_test_case'

class KeyboardShortcutsTest < ApplicationSystemTestCase
  setup do
    stub_include_comments
    @user = create(:user, disable_confirmations: true)
    @notification1 = create(:notification, user: @user, subject: create(:subject), subject_title: 'First notification')
    @notification2 = create(:notification, user: @user, subject_title: 'Second notification')
    @notification3 = create(:notification, user: @user, subject_title: 'Third notification')
    sign_in_as(@user)
  end

  test 'n and p navigate between pages' do
    create_list(:notification, 38, user: @user)
    visit '/'
    first_page_url = page.current_url

    send_keys 'p'
    assert_equal first_page_url, page.current_url

    send_keys 'n'
    assert_page 2

    send_keys 'n'
    assert_page 3
    last_page_url = page.current_url

    send_keys 'n'
    assert_equal last_page_url, page.current_url

    send_keys 'p'
    assert_page 2

    send_keys 'p'
    assert_page 1
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

  test 'j scrolls the notification list to keep the cursor visible' do
    visit_long_notification_list
    assert_current_row_visible

    30.times { send_keys 'j' }

    assert_current_row_visible
    assert_operator notification_list_scroll_top, :>, 0
  ensure
    page.current_window.resize_to(1400, 900)
  end

  test 'k scrolls the notification list to keep the cursor visible' do
    visit_long_notification_list
    30.times { send_keys 'j' }

    20.times { send_keys 'k' }

    assert_current_row_visible
  ensure
    page.current_window.resize_to(1400, 900)
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

    find('#help-box button.close').send_keys(:escape)
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

  test 'preview scrolling shortcuts move by full and half pages' do
    open_scrollable_preview

    preview_height = page.evaluate_script("document.getElementById('thread').clientHeight")
    preview_scroll_height = page.evaluate_script("document.getElementById('thread').scrollHeight")
    assert_operator preview_scroll_height, :>, preview_height

    send_keys :space
    assert_in_delta preview_height, preview_scroll_top, 2

    set_preview_scroll_top(preview_height * 2)
    send_keys :backspace
    assert_in_delta preview_height, preview_scroll_top, 2

    set_preview_scroll_top(0)
    send_keys :shift, :page_down
    assert_in_delta preview_height / 2.0, preview_scroll_top, 2

    set_preview_scroll_top(preview_height * 2)
    send_keys :shift, :page_up
    assert_in_delta preview_height * 1.5, preview_scroll_top, 2
  ensure
    page.current_window.resize_to(1400, 900)
  end

  test 'preview scrolling shortcuts preserve interactive and modified keys' do
    refute shortcut_prevented?(32)
    open_scrollable_preview

    page.execute_script(<<~JS)
      var button = document.createElement('button');
      button.id = 'preview-action';
      button.dataset.clickCount = '0';
      button.addEventListener('click', function() {
        button.dataset.clickCount = String(Number(button.dataset.clickCount) + 1);
      });
      document.getElementById('notification-thread').prepend(button);
    JS

    find('#preview-action').send_keys(:space)
    assert_equal '1', find('#preview-action')['data-click-count']
    assert_in_delta 0, preview_scroll_top, 2

    refute shortcut_prevented?(68, ctrl: true, shift: true)
    refute shortcut_prevented?(68, ctrl: true)
    refute shortcut_prevented?(85, ctrl: true)
    refute shortcut_prevented?(68, meta: true)
    refute shortcut_prevented?(32, alt: true)
    refute shortcut_prevented?(8, alt: true)
    refute shortcut_prevented?(34, shift: true, alt: true)
    refute shortcut_prevented?(191, shift: true, alt: true)
    assert_no_selector '#help-box.show'
    assert_in_delta 0, preview_scroll_top, 2

    page.execute_script("document.getElementById('help-box').classList.add('show')")
    refute shortcut_prevented?(32)
    assert_in_delta 0, preview_scroll_top, 2
  ensure
    page.current_window.resize_to(1400, 900)
  end

  test 'preview scrolling shortcuts ignore nested editable content' do
    open_scrollable_preview
    page.execute_script(<<~JS)
      var editor = document.createElement('div');
      editor.setAttribute('contenteditable', '');
      var child = document.createElement('span');
      child.id = 'editable-child';
      editor.appendChild(child);
      document.getElementById('notification-thread').appendChild(editor);
    JS

    refute shortcut_prevented?(32, target: "document.getElementById('editable-child')")
    assert_in_delta 0, preview_scroll_top, 2
  ensure
    page.current_window.resize_to(1400, 900)
  end

  def open_scrollable_preview
    page.current_window.resize_to(2400, 900)
    make_current(@notification1)
    send_keys :enter
    assert_selector '.flex-main.show-thread', wait: 2
    assert_selector '#notification-thread'

    page.execute_script(<<~JS)
      var spacer = document.createElement('div');
      spacer.style.height = '5000px';
      document.getElementById('notification-thread').appendChild(spacer);
    JS
  end

  def shortcut_prevented?(which, target: 'document.body', ctrl: false, shift: false, alt: false, meta: false)
    page.evaluate_script(<<~JS)
      (() => {
        var event = new KeyboardEvent('keydown', {
          bubbles: true,
          cancelable: true,
          ctrlKey: #{ctrl},
          shiftKey: #{shift},
          altKey: #{alt},
          metaKey: #{meta}
        });
        Object.defineProperty(event, 'which', { value: #{which} });
        #{target}.dispatchEvent(event);
        return event.defaultPrevented;
      })()
    JS
  end

  def make_current(notification)
    page.execute_script("Octobox.markRowCurrent(document.getElementById('notification-#{notification.id}'))")
    find("#notification-#{notification.id}")
  end

  def preview_scroll_top
    page.evaluate_script("document.getElementById('thread').scrollTop")
  end

  def set_preview_scroll_top(value)
    page.execute_script("document.getElementById('thread').scrollTop = #{value}")
  end

  test 'n and p route pagination through Turbolinks' do
    create_list(:notification, 50, user: @user)
    visit '/'
    next_url = find('.page-item.next .page-link').evaluate_script('this.href')
    capture_turbolinks_visits

    send_keys 'n'
    assert_equal next_url, page.evaluate_script('window.lastTurbolinksVisit')

    visit '/?page=2'
    previous_url = find('.page-item.prev .page-link').evaluate_script('this.href')
    capture_turbolinks_visits

    send_keys 'p'
    assert_equal previous_url, page.evaluate_script('window.lastTurbolinksVisit')
  end

  test 'n and p do nothing at pagination boundaries' do
    create_list(:notification, 50, user: @user)
    visit '/'
    capture_turbolinks_visits

    send_keys 'p'
    assert_nil page.evaluate_script('window.lastTurbolinksVisit')

    visit '/?page=999'
    capture_turbolinks_visits

    send_keys 'n'
    assert_nil page.evaluate_script('window.lastTurbolinksVisit')
  end

  test 'down and up arrows move cursor and prevent default scrolling' do
    initial_id = find('td.js-current').ancestor('tr')[:id]

    send_keys :down
    assert_no_selector "tr##{initial_id} td.js-current"
    assert_selector 'td.js-current', count: 1

    send_keys :up
    assert_selector "tr##{initial_id} td.js-current"

    assert shortcut_prevented?(40)
    assert shortcut_prevented?(38)
  end

  test 'right and left arrows navigate between pages' do
    create_list(:notification, 38, user: @user)
    visit '/'
    first_page_url = page.current_url

    send_keys :left
    assert_equal first_page_url, page.current_url

    send_keys :right
    assert_page 2

    send_keys :right
    assert_page 3
    last_page_url = page.current_url

    send_keys :right
    assert_equal last_page_url, page.current_url

    send_keys :left
    assert_page 2

    send_keys :left
    assert_page 1
  end

  test 'left and right arrows prevent default and do nothing at pagination boundaries' do
    create_list(:notification, 50, user: @user)
    visit '/'
    capture_turbolinks_visits

    send_keys :left
    assert_nil page.evaluate_script('window.lastTurbolinksVisit')
    assert shortcut_prevented?(37)

    visit '/?page=999'
    capture_turbolinks_visits

    send_keys :right
    assert_nil page.evaluate_script('window.lastTurbolinksVisit')
    assert shortcut_prevented?(39)
  end

  test 'arrow keys keep their normal behavior in the search box' do
    row_id = find('td.js-current').ancestor('tr')[:id]
    capture_turbolinks_visits
    send_keys '/'
    assert_equal 'search-box', page.evaluate_script('document.activeElement.id')

    search_box = find('#search-box')
    search_box.set('')
    search_box.send_keys('abc', :left, :left, 'X')
    assert_equal 'aXbc', search_box.value

    search_box.send_keys(:down, :up, :right)
    assert_equal row_id, find('td.js-current').ancestor('tr')[:id]
    assert_nil page.evaluate_script('window.lastTurbolinksVisit')

    [37, 38, 39, 40].each do |which|
      refute shortcut_prevented?(which, target: "document.getElementById('search-box')")
    end
  end

  test 'arrow keys keep their normal behavior in the comment field' do
    create_list(:notification, 50, user: @user)
    visit '/'
    row_id = find('td.js-current').ancestor('tr')[:id]
    capture_turbolinks_visits
    page.execute_script(<<~JS)
      var field = document.createElement('textarea');
      field.id = 'comment_body';
      document.body.appendChild(field);
    JS

    comment = find('#comment_body')
    comment.send_keys('abc', :left, :left, 'X')
    assert_equal 'aXbc', comment.value

    comment.send_keys(:down, :up, :right)
    assert_equal row_id, find('td.js-current').ancestor('tr')[:id]
    assert_nil page.evaluate_script('window.lastTurbolinksVisit')

    [37, 38, 39, 40].each do |which|
      refute shortcut_prevented?(which, target: "document.getElementById('comment_body')")
    end
  end

  test 'r routes foreground sync through Turbolinks' do
    stub_background_jobs_enabled(value: false)
    visit '/'
    sync_url = find('a.js-sync').evaluate_script('this.href')
    capture_turbolinks_visits

    send_keys 'r'
    sleep 0.1

    assert_equal sync_url, page.evaluate_script('window.lastTurbolinksVisit')
  end

  def visit_long_notification_list
    create_list(:notification, 60, user: @user)
    page.current_window.resize_to(1200, 500)
    visit '/?per_page=100'
    assert_selector 'td.js-current'
  end

  def assert_current_row_visible
    assert current_row_visible?, 'expected the selected notification to be visible in the notification list'
  end

  def current_row_visible?
    page.evaluate_script(<<~JS)
      (() => {
        var current = document.querySelector('td.js-current');
        if (!current) return false;
        var row = current.closest('tr');
        var list = document.querySelector('.flex-main');
        var header = list.querySelector('.card-header.sticky-top');
        var row_rect = row.getBoundingClientRect();
        var list_rect = list.getBoundingClientRect();
        var visible_top = header ? header.getBoundingClientRect().bottom : list_rect.top;
        return row_rect.top >= visible_top - 1 && row_rect.bottom <= list_rect.bottom + 1;
      })()
    JS
  end

  def notification_list_scroll_top
    page.evaluate_script("document.querySelector('.flex-main').scrollTop")
  end

  # Turbolinks changes the URL before it renders the new page
  def assert_page(number)
    assert_current_path "/?page=#{number}"
    assert_selector '.page-item.active', text: number.to_s
  end

  def capture_turbolinks_visits
    page.execute_script(<<~JS)
      window.lastTurbolinksVisit = undefined;
      Turbolinks.visit = function(url) {
        window.lastTurbolinksVisit = new URL(url, window.location.href).href;
      };
    JS
  end

  def send_keys(*keys)
    find('body').send_keys(*keys)
  end
end
