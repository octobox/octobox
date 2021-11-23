API Documentation
---

This is the API Documentation for Octobox. With this API, you can access and manage your Github notifications and user profile.

## Authentication

Every user has an API Token that you can see on [your settings page](/settings). Octobox uses standard API Token-based authentication.

To use this authentication, send Authentication and X-Octobox-API headers to Octobox:

```
Authorization: Bearer <token>
X-Octobox-API: 1
```

For example, here is a basic Ruby example to get notifications:

```ruby
require "net/http"
require "uri"

base_url = "https://<url>"
url = URI.parse("#{base_url}/api/notifications.json")

req = Net::HTTP::Get.new(url.path)
req.add_field("Authorization", "Bearer #{token}")
req.add_field("X-Octobox-API", "1")
res = Net::HTTP.new(url.host, url.port).start do |http|
  http.request(req)
end

puts res.body
```

## Endpoints

The endpoints are listed by controller down the left hand side of these docs.

## Questions?

Please refer to the repository for this app. [You can find the repo here](https://github.com/octobox/octobox).
