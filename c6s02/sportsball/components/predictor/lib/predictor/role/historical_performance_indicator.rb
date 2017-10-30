
module Predictor
  module Role
    module HistoricalPerformanceIndicator
      def order_of_teams
        result = [first_team_id, second_team_id]
        result.reverse! if winning_team != 1
        result
      end
    end
  end
end

