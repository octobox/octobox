Rails.application.routes.draw do
  get '/notifications/:id/archive', to: 'notifications#archive'
  get '/sync', to: 'notifications#sync'
  root to: 'notifications#index'
end
