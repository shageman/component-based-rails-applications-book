
Rails.application.routes.draw do
  mount AppComponent::Engine, at: "/app_component"
  mount TeamsAdmin::Engine, at: "/teams_admin"
  mount GamesAdmin::Engine, at: "/games_admin"
  root to: "app_component/welcome#show"
end

