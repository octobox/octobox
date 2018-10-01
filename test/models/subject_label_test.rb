# frozen_string_literal: true
require 'test_helper'

class SubjectLabelTest < ActiveSupport::TestCase
  setup do
    repository = create(:repository)
    @subject = create(:subject, state: 'open', url: "https://api.github.com/repos/octobox/octobox/issues/560", repository_full_name: repository.full_name)
    @label = create(:label, github_id: 208045946, name: "bug", color: "f29513", repository_id: repository.id)
  end

  test 'creating SubjectLabel mapping succeeds for Non-existing Subject & Label Mapping' do
    assert_difference 'SubjectLabel.count', 1 do
      create(:subject_label, label_id: @label.id, subject_id: @subject.id)
    end
  end

  test 'creating SubjectLabel mapping for Same subject and Label fails' do
    create(:subject_label, label_id: @label.id, subject_id: @subject.id)

    assert_raises ActiveRecord::RecordNotUnique do
      create(:subject_label, label_id: @label.id, subject_id: @subject.id)
    end
  end

end