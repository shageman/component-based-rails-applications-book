
require "spec_helper"

RSpec.describe "Prediction process" do
  before do
    @team1 = OpenStruct.new(id: 6)
    @team2 = OpenStruct.new(id: 7)

    @team1.extend Predictor::Role::Contender
    @team1.extend Predictor::Role::Predictor

    @team2.extend Predictor::Role::Contender

    @team1.contenders = [@team1, @team2]
    @team1.opponent = @team2

    @predictor = @team1
  end

  it "predicts teams that have won in the past to win in the future" do
    game = OpenStruct.new(
        first_team_id: @team1.id, second_team_id: @team2.id, winning_team: 1)
    game.extend Predictor::Role::HistoricalPerformanceIndicator

    @predictor.learn([game])

    prediction = @predictor.predict
    expect(prediction.winner).to eq @team1
  end

  it "changes predictions based on games learned" do
    game1 = OpenStruct.new(
        first_team_id: @team1.id, second_team_id: @team2.id, winning_team: 1)
    game2 = OpenStruct.new(
        first_team_id: @team1.id, second_team_id: @team2.id, winning_team: 2)
    game3 = OpenStruct.new(
        first_team_id: @team1.id, second_team_id: @team2.id, winning_team: 2)
    [game1, game2, game3].each do |game|
      game.extend Predictor::Role::HistoricalPerformanceIndicator
    end
    @predictor.learn([game1, game2, game3])

    prediction = @predictor.predict
    expect(prediction.winner).to eq @team2
  end
end

