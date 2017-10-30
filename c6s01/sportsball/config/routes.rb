
Rails.application.routes.draw do
  mount WelcomeUi::Engine, at: "/welcome_ui"
  mount PredictionUi::Engine, at: "/prediction_ui"
  mount TeamsAdmin::Engine, at: "/teams_admin"
  mount GamesAdmin::Engine, at: "/games_admin"
  root to: "welcome_ui/welcome#show"
end

