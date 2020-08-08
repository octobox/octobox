# frozen_string_literal: true

require 'sidekiq/web'
require 'sidekiq-status/web'
if Octobox.config.sidekiq_schedule_enabled?
  require 'sidekiq-scheduler/web'
end
require 'sidekiq_unique_jobs/web'
require 'admin_constraint'

Rails.application.routes.draw do
  root to: 'notifications#index'

  get '/404', to: 'errors#not_found'
  get '/422', to: 'errors#unprocessable'
  get '/500', to: 'errors#internal'

  constraints AdminConstraint.new do
    namespace :admin do
      mount Sidekiq::Web => "/sidekiq"
    end

    get '/admin', to: 'admin#index', as: :admin
  end

  mount ActionCable.server => '/cable'

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
      get  :syncing
      post :syncing
      post :mute_selected
      post :mark_read_selected
      get  :unread_count
      post :delete_selected
      post :snooze_selected
    end

    member do
      get  :show
      post :star
      get  :expand_comments
      post :comment
    end
  end

  get '/documentation', to: 'pages#documentation'
  get '/support', to: redirect('/documentation#support')

  post '/hooks/github', to: 'hooks#create'

  # Octobox.io specific routes
  get '/opencollective', to: 'open_collective#callback'
  get '/pricing', to: 'pages#pricing'
  get '/privacy', to: 'pages#privacy'
  get '/terms', to: 'pages#terms'

  resources :pinned_searches

  get '/settings', to: 'users#edit'
  get '/export', to: 'users#export'
  post '/import', to: 'users#import'
  resources :users, only: [:update, :destroy] do
    collection do
      scope format: true, constraints: { format: 'json' } do
        get :profile
      end
    end
  end
end
