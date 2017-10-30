
module Predictor
  class Prediction
    attr_reader :first_team, :second_team, :winner

    def initialize(first_team, second_team, winner)
      @first_team = first_team
      @second_team = second_team
      @winner = winner
    end
  end
end

