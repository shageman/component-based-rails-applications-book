Rails.application.routes.draw do
  mount Games::Engine => "/games"
end
