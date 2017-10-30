
AppComponent::Engine.routes.draw do

  resource :welcome, only: [:show]

  root to: "welcome#show"
end

