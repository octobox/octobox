# frozen_string_literal: true
Rails.application.routes.draw do
  get '/login', to: 'sessions#new', as: 'login'

  match '/auth/:provider/callback', to: 'sessions#create', via: [:get, :post]

  get '/notifications/:id/archive', to: 'notifications#archive'
  get '/notifications/:id/unarchive', to: 'notifications#unarchive'
  get '/sync', to: 'notifications#sync'
  root to: 'notifications#index'
end
