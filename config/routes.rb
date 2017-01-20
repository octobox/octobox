# frozen_string_literal: true
Rails.application.routes.draw do
  mount MagicLamp::Genie, at: '/magic_lamp' if defined?(MagicLamp)

  root to: 'notifications#index'

  get :login,  to: 'sessions#new'
  get :logout, to: 'sessions#destroy'

  scope :auth do
    match '/:provider/callback', to: 'sessions#create',  via: [:get, :post]
    match :failure,              to: 'sessions#failure', via: [:get, :post]
  end

  resources :notifications, only: [] do
    collection do
      post :archive_selected
      post :sync
      post :mute_selected
      post :mark_read_selected
      get :unread_count
    end

    member do
      get :star
      get :mark_read
    end
  end

  get '/settings', to: 'users#edit'
  resources :users, only: [:update, :destroy]
end
