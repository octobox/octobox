require 'pagy/extras/headers'
Pagy::VARS[:items] = 20
require 'pagy/extras/overflow'
Pagy::VARS[:overflow] = :last_page
