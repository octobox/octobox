class SubjectLabel < ApplicationRecord
  belongs_to :subject
  belongs_to :label
end
