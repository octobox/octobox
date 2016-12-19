# frozen_string_literal: true
Rails.application.routes.draw do
  get '/login', to: 'sessions#new', as: 'login'
  get '/logout', to: 'sessions#destroy', as: 'logout'

  match '/auth/:provider/callback', to: 'sessions#create', via: [:get, :post]

  get '/notifications/all/archive', to: 'notifications#archive_all'
  get '/notifications/:id/archive', to: 'notifications#archive'
  get '/notifications/:id/unarchive', to: 'notifications#unarchive'
  get '/notifications/:id/star', to: 'notifications#star'
  get '/sync', to: 'notifications#sync'
  root to: 'notifications#index'
end
