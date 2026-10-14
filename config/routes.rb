# frozen_string_literal: true

KeystoneUi::Pages::Engine.routes.draw do
  namespace :manage do
    resources :pages, only: %i[new create show] do
      resources :elements, only: %i[create]
    end
  end

  get ":slug", to: "pages#show", as: :page
end
