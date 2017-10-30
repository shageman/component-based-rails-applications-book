AppComponent::Engine.routes.draw do
  resources :games
  resources :teams
  root to: 'welcome#index'
  resource :prediction, only: [:new, :create]

end
