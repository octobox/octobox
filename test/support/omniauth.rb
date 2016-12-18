# frozen_string_literal: true
OmniAuth.config.test_mode = true

OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
  'provider'    => 'github',
  'uid'         => 42,
  'credentials' => { 'token' => SecureRandom.hex(20) }
)
