# frozen_string_literal: true

KeystoneUi::Pages::Engine.routes.draw do
  get ":slug", to: "pages#show", as: :page
end
