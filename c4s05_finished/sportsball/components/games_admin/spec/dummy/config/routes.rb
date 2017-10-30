Rails.application.routes.draw do
  mount GamesAdmin::Engine => "/games_admin"
end
