
require "slim-rails"
require "jquery-rails"

require "predictor"
require "web_ui"
require "teams_store"
require "games"
require "predict_game"

module PredictionUi
  require "prediction_ui/engine"

  def self.nav_entry
    {name: "Predictions", link: -> {::PredictionUi::Engine.routes.url_helpers.new_prediction_path}}
  end
end

