Rails.application.routes.draw do
  mount KeystoneUi::Pages::Engine => "/pages"
  get "products/:slug", to: "products#show"
  get "demo/visitor/:visitor", to: "demo_visitors#update", as: :demo_visitor
end
