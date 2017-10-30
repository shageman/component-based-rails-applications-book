#!/bin/bash

set -v
set -x
set -e

gem install --source http://geminabox:9292 bundler -v 1.16.1 --no-ri --no-rdoc

tar -xzf code_input/$PREV_CHAPTER*.tgz -C code_output


cd code_output/sportsball

############################################################################################################
############################################################################################################
### PREDICTOR
############################################################################################################
############################################################################################################

mkdir -p components/predictor/lib/predictor/role

echo '
require "saulabs/trueskill"

module Predictor
  require "predictor/role/contender"
  require "predictor/role/predictor"
  require "predictor/role/historical_performance_indicator"
  require "predictor/prediction"
  require "predictor/prediction_error"
end
' > components/predictor/lib/predictor.rb

echo '
module Predictor
  class Prediction
    attr_reader :first_team, :second_team, :winner, :message

    def initialize(first_team, second_team, winner)
      @first_team = first_team
      @second_team = second_team
      @winner = winner
    end
  end
end
' > components/predictor/lib/predictor/prediction.rb

echo '
module Predictor
  class PredictionError < Prediction
    def initialize(first_team, second_team, message)
      super(first_team, second_team, nil)
      @message = message
    end
  end
end
' > components/predictor/lib/predictor/prediction_error.rb

echo '
module Predictor
  module Role
    module Contender
      def self.extended(base)
        base.rating = [Saulabs::TrueSkill::Rating.new(1500.0, 1000.0, 1.0)]
      end

      def rating
        @rating
      end

      def rating=(value)
        @rating = value
      end

      def mean_of_rating
        @rating.first.mean
      end
    end
  end
end
' > components/predictor/lib/predictor/role/contender.rb

echo '
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
' > components/predictor/lib/predictor/role/historical_performance_indicator.rb

echo '
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
' > components/predictor/lib/predictor/role/predictor.rb

echo '
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
' > components/predictor/spec/predictor_spec.rb



############################################################################################################
############################################################################################################
### PREDICTOR_UI
############################################################################################################
############################################################################################################
echo '
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
' > components/prediction_ui/app/controllers/prediction_ui/predictions_controller.rb

echo '
module PredictionUi
  module PredictionsHelper
    def prediction_text(team1, team2, winner)
      return "Winner not determined" if winner.nil?
      "In the game between #{team1.name} and #{team2.name} the winner will be #{winner.name}"
    end
  end
end
' > components/prediction_ui/app/helpers/prediction_ui/predictions_helper.rb

echo '
RSpec.describe PredictionUi::PredictionsHelper, :type => :helper do
  Named = Struct.new(:name)

  it "returns a nice prediction text" do
    text = prediction_text(Named.new("A"), Named.new("B"), Named.new("C"))
    expect(text).to eq "In the game between A and B the winner will be C"
  end

  it "returns a winner not determined if given no winner" do
    text = prediction_text(Named.new("A"), Named.new("B"), nil)
    expect(text).to eq "Winner not determined"
  end
end
' > components/prediction_ui/spec/helpers/predictions_helper_spec.rb

echo '
RSpec.describe PredictionUi::PredictionsController, :type => :controller do
  routes { PredictorUi::Engine.routes }

  before do
    @team1 = create_team
    @team2 = create_team
  end

  describe "GET new" do
    it "assigns all teams as @teams" do
      get :new, {}, {}
      expect(assigns(:teams)).to eq([@team1, @team2])
    end
  end

  describe "POST create" do
    it "assigns a prediction as @prediction" do
      post :create,
           {first_team: {id: @team1.id}, second_team: {id: @team2.id}},
           {}

      prediction = assigns(:prediction)
      expect(prediction).to be_a(Predictor::Prediction)
      expect(prediction.first_team).to eq(@team1)
      expect(prediction.second_team).to eq(@team2)
    end
  end
end
' > components/prediction_ui/spec/controllers/prediction_ui/predictions_controller.rb


cd ..

tar -zcvf $CHAPTER-`date +%Y%m%d%H%M%S`.tgz sportsball

