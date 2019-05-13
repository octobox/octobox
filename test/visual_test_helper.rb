require 'capybara/rails'
require 'capybara/minitest'

WebMock.disable_net_connect!(allow_localhost: true)

Capybara.default_driver = :selenium

def set_dark_theme(user)
	user.theme = 'dark'
end
