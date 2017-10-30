
module Predictor
  module Role
    module Predictor
      def contenders=(contenders)
        @contenders_lookup = contenders.inject({}) do |memo, contender|
          memo[contender.id] = contender
          memo
        end
      end

      def opponent=(value)
        @opponent = value
      end

      def game_predictable?
        self != @opponent
      end

      def learn(games)
        games.each do |game|
          game_result = game.order_of_teams.map do |team_id|
            @contenders_lookup[team_id].rating
          end
          Saulabs::TrueSkill::FactorGraph.new(game_result, [1, 2]).update_skills
        end
      end

      def predict
        if game_predictable?
          ::Predictor::Prediction.new(
              self,
              @opponent,
              likely_winner)
        else
          ::Predictor::PredictionError.new(
              self,
              @opponent,
              "Two contenders needed for prediction")
        end
      end

      private

      def likely_winner
        team1 = @contenders_lookup[id]
        team2 = @contenders_lookup[@opponent.id]

        team1.mean_of_rating > team2.mean_of_rating ? team1 : team2
      end
    end
  end
end

