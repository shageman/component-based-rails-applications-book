
Rails.application.routes.draw do
  mount PredictionUi::Engine, at: "/prediction_ui"
  mount TeamsAdmin::Engine, at: "/teams_admin"
  mount GamesAdmin::Engine, at: "/games_admin"
  root to: "app_component/welcome#show"
end

