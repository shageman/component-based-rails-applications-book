
module PredictionUi
  class PredictionsController < ApplicationController
    def new
      @teams = TeamsStore::TeamRepository.new.get_all
    end

    def create
      game_predictor = PredictGame::PredictGame.new(
          TeamsStore::TeamRepository.new.get_all,
          Games::Game.all)
      game_predictor.add_subscriber(PredictionResponse.new(self))
      game_predictor.perform(
          TeamsStore::TeamRepository.new.get(params["first_team"]["id"]),
          TeamsStore::TeamRepository.new.get(params["second_team"]["id"]))
    end

    class PredictionResponse < SimpleDelegator
      def prediction_succeeded(prediction)
        render locals: {prediction: prediction, message: nil}
      end

      def prediction_failed(prediction, error_message)
        render locals: {prediction: prediction, message: error_message}
      end
    end
  end
end

