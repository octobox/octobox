require 'yard'

namespace :api_docs do
  YARD::Rake::YardocTask.new :generate do |doc|
    doc.options = ["--readme", "docs/API_README.md",
                   "--title", "Octobox API Documentation",
                   "--output-dir", "public/docs",
                   "--no-private"]
    doc.files = [
      "app/controllers/api/notifications_controller.rb",
      "app/controllers/api/pinned_searches_controller.rb",
      "app/controllers/api/users_controller.rb"
    ]
  end
end
