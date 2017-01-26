require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  test "should return the correct bootstrap class for each type of flash" do
    assert_equal bootstrap_class_for(:success), 'alert-success'
    assert_equal bootstrap_class_for(:error), 'alert-danger'
    assert_equal bootstrap_class_for(:alert), 'alert-warning'
    assert_equal bootstrap_class_for(:notice), 'alert-info'
    assert_equal bootstrap_class_for(:foobar), 'foobar'
  end

  test 'copyright_message has no et al link when no contributors are found' do
    Octobox.stubs(:contributors).returns(nil)
    assert_equal '© 2017 Andrew Nesbitt, et al', copyright_message
  end

  test 'copyright_message has et al link' do
    stub_contributors
    assert_equal "© 2017 <a href='https://github.com/andrew' target='_blank'>Andrew Nesbitt</a>, <a href='#' data-toggle='modal' data-target='#et-al'>et al</a>", copyright_message
  end

  test 'license_message has correct link when SOURCE_REPO is not set' do
    ENV.stubs(:[]).with('SOURCE_REPO').returns(nil)
    expected_message = "<a href='https://github.com/octobox/octobox' target='_blank'>Source</a> available under <a href='https://github.com/octobox/octobox/blob/master/LICENSE.txt' target='_blank'>AGPL 3.0</a>"
    assert_equal expected_message, license_message
  end

  test 'license_message has correct link when SOURCE_REPO is set' do
    ENV.stubs(:[]).with('SOURCE_REPO').returns('https://github.com/foo/bar')
    expected_message = "<a href='https://github.com/foo/bar' target='_blank'>Source</a> available under <a href='https://github.com/foo/bar/blob/master/LICENSE.txt' target='_blank'>AGPL 3.0</a>"
    assert_equal expected_message, license_message
  end
end
