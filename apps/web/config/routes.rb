# frozen_string_literal: true

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root to: "home#index"

  get "discover", to: "discover#show", as: :discover
  patch "discover", to: "discover#update"
  post "discover", to: "discover#update"

  get "login", to: "logins#show", as: :login

  resource :cart, only: :show

  resource :checkout, only: %i[show create]
  get "checkout/thank-you", to: "checkouts#thank_you", as: :checkout_thank_you

  get "artworks/:slug", to: "artworks#show", as: :artwork, constraints: ArtworkSlugConstraint
  get "artworks(/*facets)", to: "artworks#index", as: :artworks
  get "artists/:slug", to: "artists#show", as: :artist

  resources :cart_items, only: %i[create update destroy]
  post "favourites", to: "favourites#create", as: :favourites
  delete "favourites/:artwork_id", to: "favourites#destroy", as: :favourite

  match "/palette/*path", to: "palette_proxy#forward", via: :all
end
