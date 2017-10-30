
require_dependency "app_component/application_controller"
module AppComponent
  class PredictionsController < ApplicationController
    def new
      @teams = AppComponent::Team.all
    end

    def create
      predictor = ::Predictor::Predictor.new(AppComponent::Team.all)
      predictor.learn(AppComponent::Game.all)
      @prediction = predictor.predict(
          AppComponent::Team.find(params["first_team"]["id"]),
          AppComponent::Team.find(params["second_team"]["id"]))
    end
  end
end

