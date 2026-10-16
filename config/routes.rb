# frozen_string_literal: true

KeystoneUi::Pages::Engine.routes.draw do
  namespace :manage do
    resources :pages, only: %i[index new create show] do
      post :publish, on: :member
      resources :elements, only: %i[create update] do
        post :bind, on: :member
      end
      resources :sections, only: %i[create]
      resources :columns, only: %i[create]
      resources :rows, only: %i[create]
      resources :nodes, only: %i[update destroy] do
        post :move, on: :member
        post :duplicate, on: :member
        post :condition, on: :member
      end
      resource :document, only: %i[update]
      post :sample, to: "samples#update"
      resource :live, only: %i[show]
      resources :versions, only: %i[index show] do
        post :restore, on: :member
      end
    end
  end

  get ":slug", to: "pages#show", as: :page
end
