
module PredictionUi
  module PredictionsHelper
    def prediction_text(team1, team2, winner)
      return "Winner not determined" if winner.nil?
      "In the game between #{team1.name} and #{team2.name} the winner will be #{winner.name}"
    end
  end
end

