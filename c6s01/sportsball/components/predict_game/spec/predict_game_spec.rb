
require "spec_helper"

describe PredictGame do

  Struct.new("PredTeam", :id)
  Struct.new("PredGame", :first_team_id, :second_team_id, :winning_team)

  class PredictionSubscriber
    attr_reader :prediction_succeeded_result, :prediction_failed_result

    def prediction_succeeded(result)
      @prediction_succeeded_result = [result]
    end

    def prediction_failed(result, message)
      @prediction_failed_result = [result, message]
    end
  end

  describe "perform" do
    before do
      @subscriber = PredictionSubscriber.new
      @team1 = Struct::PredTeam.new(1)
      @team2 = Struct::PredTeam.new(2)

      @predict_game = PredictGame::PredictGame.new(
          [@team1, @team2],
          [Struct::PredGame.new(1, 2, 1)]
      )

      @predict_game.add_subscriber(@subscriber)
    end

    it "will publish a message for a successful prediction" do
      @predict_game.perform(@team1, @team2)

      expect(@subscriber.prediction_succeeded_result).to_not be_nil
      expect(@subscriber.prediction_failed_result).to be_nil
    end

    it "will publish a message for a unsuccessful prediction" do
      @predict_game.perform(@team1, @team1)

      expect(@subscriber.prediction_succeeded_result).to be_nil
      expect(@subscriber.prediction_failed_result).to_not be_nil
    end
  end
end

