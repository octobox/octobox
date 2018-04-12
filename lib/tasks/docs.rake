require 'rdoc/task'

namespace :api_docs do
  RDoc::Task.new :generate do |rdoc|
    rdoc.main = "docs/API_README.md"
    rdoc.rdoc_files.include(
      "app/controllers/notifications_controller.rb",
      "app/controllers/users_controller.rb",
      "docs/API_README.md",
    )
    rdoc.rdoc_dir = "public/docs"
    rdoc.title = "Octobox API Documentation"
  end
end
