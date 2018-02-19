# frozen_string_literal: true

class AdminConstraint
  def matches?(request)
    user_id = request.cookie_jar.signed[:user_id]

    if (user = User.find_by(id: user_id))
      return user.admin?
    end

    false
  end
end
