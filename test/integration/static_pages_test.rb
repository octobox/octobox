# NOTES:
# The index and pricing page tests are in test/integration/index_page_test.rb.
# The documentation page tests are in test/integration/documentation_test.rb

require 'test_helper'

class StaticPagesTest < ActionDispatch::IntegrationTest
  test 'The index page (given OCTOBOX_IO=true) has a link to the terms page' do
    stub_env_var('OCTOBOX_IO', 'true')
    get root_path
    assert_select "a[href=?]", terms_path, text: 'Terms'
  end

  test 'The index page (given OCTOBOX_IO=true) has a link to the privacy page' do
    stub_env_var('OCTOBOX_IO', 'true')
    get root_path
    assert_select "a[href=?]", privacy_path, text: 'Privacy Policy'
  end

  test 'The terms page has the expected content' do
    stub_env_var('OCTOBOX_IO', 'true')
    get terms_path
    assert_select "a[href=?]", root_path
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

  test 'The privacy page has the expected content' do
    stub_env_var('OCTOBOX_IO', 'true')
    get privacy_path
    assert_select "a[href=?]", root_path
    assert_select 'h1', text: 'Privacy Policy'
    assert_select 'h2', text: 'We Care About Your Privacy'
    assert_select 'h3', text: 'Data We Collect'
    assert_select 'h3', text: 'Transmitting Your Data'
    assert_select 'h3', text: 'Processing And Storing Your Data'
    assert_select 'h3', text: 'Sharing Your Data'
    assert_select 'h2', text: 'Services We Use'
    assert_select 'h3', text: 'Cookies'
    assert_select 'h3', text: 'Logging'
    assert_select 'h4', text: "Bugsnag's DPA"
    assert_select 'h2', text: 'Your Rights'
    assert_select 'h2', text: 'Changes To This Privacy Policy'
  end
end
