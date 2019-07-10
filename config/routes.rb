Rails.application.routes.draw do
  devise_for :users
  root to: 'rooms#index'
  resources :rooms
  resources :battles, only: :index

  # Sidekiq Web UI, only for admins.
  require "sidekiq/web"
  authenticate :user, lambda { |u| u.admin } do
    mount Sidekiq::Web => '/sidekiq'
  end
end
