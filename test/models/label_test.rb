require 'test_helper'

class LabelTest < ActiveSupport::TestCase
  setup do
    @repository = create(:repository)
    @label = Label.new({github_id: 208045946, name: "bug", color: "f29513", repository_id: @repository.id})
  end

  test 'creating Label for Unique github_id succeeds' do
    assert_difference 'Label.count', 1 do
      @label.save!
    end
  end

  test 'creating Label for duplicate github_id fails' do
    @label.save!

    assert_raises ActiveRecord::RecordNotUnique do
      create(:label, github_id: 208045946, name: "bug", color: "f29513", repository_id: @repository.id)
    end
  end

  test 'renders contrasting label color' do
    label = Label.new({color: 'ffffff'})
    assert_equal 'black', label.text_color

    label = Label.new({color: '000000'})
    assert_equal 'white', label.text_color

    label = Label.new({color: 'FF0000'})
    assert_equal 'white', label.text_color

    label = Label.new({color: 'EEE'})
    assert_equal 'black', label.text_color
  end
end