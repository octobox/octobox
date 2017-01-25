MagicLamp.fixture do
  user = User.new
  user.github_login = "foo"
  render partial: 'layouts/header', locals: {current_user: user}
end
