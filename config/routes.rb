# frozen_string_literal: true

KeystoneUi::Pages::Engine.routes.draw do
  namespace :manage do
    resources :pages, only: %i[new create show] do
      post :publish, on: :member
      resources :elements, only: %i[create update]
      resources :sections, only: %i[create]
    end
  end

  get ":slug", to: "pages#show", as: :page
end
