
WelcomeUi::Engine.routes.draw do
  resource :welcome, only: [:show], controller: "/welcome_ui/welcome"
  root to: "/welcome_ui/welcome#show"
end

