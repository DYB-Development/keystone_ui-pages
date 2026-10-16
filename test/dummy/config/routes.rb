Rails.application.routes.draw do
  mount KeystoneUi::Pages::Engine => "/pages"
  get "products/:slug", to: "products#show"
end
