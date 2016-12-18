Rails.application.routes.draw do
  get '/notifications/:id/archive', to: 'notifications#archive'
  get '/notifications/:id/unarchive', to: 'notifications#unarchive'
  get '/notifications/:id/star', to: 'notifications#star'
  get '/sync', to: 'notifications#sync'
  root to: 'notifications#index'
end
