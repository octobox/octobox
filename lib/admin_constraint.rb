# frozen_string_literal: true

class AdminConstraint
  def matches?(request)
    User.find(request.cookie_jar.signed[:user_id]).admin?
  rescue ActiveRecord::RecordNotFound
    false
  end
end
