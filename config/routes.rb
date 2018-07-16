# frozen_string_literal: true

require 'sidekiq/web'
if Octobox.config.sidekiq_schedule_enabled?
  require 'sidekiq-scheduler/web'
end
require 'admin_constraint'

Rails.application.routes.draw do
  root to: 'notifications#index'

  constraints AdminConstraint.new do
    namespace :admin do
      mount Sidekiq::Web => "/sidekiq"
    end
  end

  get :login,  to: 'sessions#new'
  get :logout, to: 'sessions#destroy'

  scope :auth do
    match '/:provider/callback', to: 'sessions#create',  via: [:get, :post]
    match :failure,              to: 'sessions#failure', via: [:get, :post]
  end

  resources :notifications, only: :index, format: true, constraints: { format: :json }
  resources :notifications, only: [] do
    collection do
      post :archive_selected
      post :sync
      get  :sync
      post :mute_selected
      post :mark_read_selected
      get  :unread_count
    end

    member do
      post :star
      post :mark_read
    end
  end

  post '/hooks/github', to: 'hooks#create'

  if Octobox.config.octobox_io
    get '/privacy', to: 'pages#privacy'
    get '/terms', to: 'pages#terms'
  end

  get '/settings', to: 'users#edit'
  resources :users, only: [:update, :destroy] do
    collection do
      scope format: true, constraints: { format: 'json' } do
        get :profile
      end
    end
  end
end
