
module PredictGame
  class PredictGame
    include Publisher

    def initialize(teams, games)
      @predictor = ::Predictor::Predictor.new(teams)
      @predictor.learn(games)
    end

    def perform(team1_id, team2_id)
      if @predictor.game_predictable?(team1_id, team2_id)
        publish(
            :prediction_succeeded,
            @predictor.predict(team1_id, team2_id))
      else
        publish(
            :prediction_failed,
            @predictor.predict(team1_id, team2_id),
            "Prediction can not be performed with a team against itself")
      end
    end
  end
end
