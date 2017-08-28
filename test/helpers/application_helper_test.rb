require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  test "should return the correct bootstrap class for each type of flash" do
    assert_equal bootstrap_class_for(:success), 'alert-success'
    assert_equal bootstrap_class_for(:error), 'alert-danger'
    assert_equal bootstrap_class_for(:alert), 'alert-warning'
    assert_equal bootstrap_class_for(:notice), 'alert-info'
    assert_equal bootstrap_class_for(:foobar), 'foobar'
  end
end
