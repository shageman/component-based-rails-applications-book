
module PredictionUi
  class PredictionsController < ApplicationController
    def new
      @teams = Teams::Team.all
    end

    def create
      @prediction = GamePredictionContext.call(
          Teams::Team.all,
          Games::Game.all,
          Teams::Team.find(params["first_team"]["id"]),
          Teams::Team.find(params["second_team"]["id"]))
    end
  end
end


class GamePredictionContext
  def self.call(teams, games, first_team, second_team)
    GamePredictionContext.new(teams, games, first_team, second_team).call
  end

  def initialize(teams, games, first_team, second_team)
    @contenders = teams
    @contenders.each { |contender| contender.extend Predictor::Role::Contender }

    @hpis = games
    @hpis.each { |game| game.extend Predictor::Role::HistoricalPerformanceIndicator }

    @predictor = first_team
    @predictor.extend Predictor::Role::Contender
    @predictor.extend Predictor::Role::Predictor

    @second_team = second_team
    @second_team.extend Predictor::Role::Contender
  end

  def call
    @predictor.opponent = @second_team
    @predictor.contenders = @contenders

    @predictor.learn(@hpis)
    @predictor.predict
  end
end

