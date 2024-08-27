require 'pagy/extras/headers'
Pagy::DEFAULT[:limit] = 20
require 'pagy/extras/overflow'
Pagy::DEFAULT[:overflow] = :last_page
require 'pagy/extras/bootstrap'