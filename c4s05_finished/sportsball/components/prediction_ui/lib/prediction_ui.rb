
require "slim-rails"
require "jquery-rails"

require "predictor"
require "app_component"

module PredictionUi
  require "games"
  require "prediction_ui/engine"

  def self.nav_entry
    {name: "Predictions", link: -> {::PredictionUi::Engine.routes.url_helpers.new_prediction_path}}
  end
end

