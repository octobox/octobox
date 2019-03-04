require 'test_helper'

class TermsPageTest < ActionDispatch::IntegrationTest
  def setup
    stub_notifications_request
    stub_comments_requests
    stub_fetch_subject_enabled(value: false)
    @user = create(:user)
  end

  def teardown
    User.destroy_all
  end

  def check_redirected
    get terms_path
    assert_match 'You are being', response.body
    assert_select "a[href=?]", 'http://www.example.com/422', text: 'redirected'
  end

  def check_terms_page_contents
    get terms_path
    assert_select 'h1', text: 'Terms and Conditions'
    assert_select 'h4', text: 'Acceptance (How To Accept These Things)'
    assert_select 'h4', text: 'Account Terms'
    assert_select 'h4', text: 'Cancellation and Termination (How To Cancel This Agreement)'
    assert_select 'h4', text: 'Modifications (Things We May Change)'
    assert_select 'h4', text: 'Copyrights and Content Ownership'
    assert_select 'h4', text: 'Agreements (Things You Agree To)'
    assert_select 'h4', text: 'Provisions (Things You Must Do)'
    assert_select 'h4', text: 'Restrictions (Things You Must Not Do)'
    assert_select 'h4', text: 'Limitations (Things We Cannot Promise)'
    assert_select 'h4', text: 'Bugs, Errors and Issues'
    assert_select 'h4', text: 'Support'                                
  end

  test 'terms page is not shown when OCTOBOX_IO is not set' do
    check_redirected
    sign_in_as(@user)
    check_redirected
  end

  test 'terms page is shown when OCTOBOX_IO is set' do
    set_env('OCTOBOX_IO', 'true') do
      check_terms_page_contents
      sign_in_as(@user)
      check_terms_page_contents
    end
  end

  test 'index page provides link to terms page when OCTOBOX_IO is set' do
    set_env('OCTOBOX_IO', 'true') do
      get root_path
      assert_select "a[href=?]", terms_path, text: 'Terms'
      sign_in_as(@user)
      get root_path
      assert_select "a[href=?]", terms_path, text: 'Terms'
    end
  end
end
