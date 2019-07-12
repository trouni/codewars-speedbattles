Rails.application.routes.draw do
  devise_for :users
  root to: 'rooms#index'
  resources :rooms do
    post '/refresh_user', to: 'rooms#refresh_user'
    resources :battles, only: %i[index create]
    resources :room_users, only: :create
  end
  resources :room_users, only: :destroy
  resources :battles, only: %i[update destroy] do
    resources :battle_players, only: %i[create]
  end
  resources :battle_players, only: %i[update destroy]

  # Sidekiq Web UI, only for admins.
  require "sidekiq/web"
  authenticate :user, lambda { |u| u.admin } do
    mount Sidekiq::Web => '/sidekiq'
  end
end
