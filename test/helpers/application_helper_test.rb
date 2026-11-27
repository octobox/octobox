require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  test "should return the correct bootstrap class for each type of flash" do
    assert_equal bootstrap_class_for(:success), 'alert-success'
    assert_equal bootstrap_class_for(:error), 'alert-danger'
    assert_equal bootstrap_class_for(:alert), 'alert-warning'
    assert_equal bootstrap_class_for(:notice), 'alert-info'
    assert_equal bootstrap_class_for(:foobar), 'foobar'
  end

  test 'svg returns the contents of an image as html safe markup' do
    expected = File.read(Rails.root.join('app', 'assets', 'images', 'keyboard.svg'))

    2.times do
      assert_equal expected, svg('keyboard')
      assert svg('keyboard').html_safe?
    end
  end

  test 'svg returns nil for an image that does not exist' do
    assert_nil svg('no-such-image')
  end
end
