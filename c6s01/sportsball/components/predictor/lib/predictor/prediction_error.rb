
module Predictor
  class PredictionError < Prediction
    attr_reader :message

    def initialize(first_team, second_team, message)
      super(first_team, second_team, nil)
      @message = message
    end
  end
end

