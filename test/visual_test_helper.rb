require 'capybara/rails'
require 'capybara/minitest'

WebMock.disable_net_connect!(allow_localhost: true)

if Octobox.config.percy_configured? 
	WebMock.disable_net_connect!(allow_localhost: true, allow: [/percy.io/])
	Percy::Capybara.initialize_build
	Percy.config.default_widths = [576, 768, 992]
end

Capybara.default_driver = :selenium

MiniTest.after_run { Percy::Capybara.finalize_build }

def set_dark_theme(user)
	user.theme = 'dark'
end