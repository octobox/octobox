require 'test_helper'

class LabelTest < ActiveSupport::TestCase
  test 'renders contrasting label color' do
    label = Label.new({color: 'ffffff'})
    assert_equal 'black', label.text_color

    label = Label.new({color: '000000'})
    assert_equal 'white', label.text_color

    label = Label.new({color: 'FF0000'})
    assert_equal 'black', label.text_color

    label = Label.new({color: 'EEE'})
    assert_equal 'black', label.text_color
  end
end
