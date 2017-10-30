#!/bin/bash

set -v
set -x
set -e

gem install --source http://geminabox:9292 bundler -v 1.16.1 --no-ri --no-rdoc

tar -xzf code_input/$PREV_CHAPTER*.tgz -C code_output


cd code_output/sportsball

sed -i "/gem 'app_component', path: 'components\/app_component'/d" Gemfile
sed -i '/source ".*"/a\\npath "components" do\n   gem "app_component"\nend\n\ngem "trueskill", git: "https:\/\/github.com\/benjaminleesmith\/trueskill", ref: "e404f45af5b3fb86982881ce064a9c764cc6a901"' Gemfile

sed -i '/gemspec/a\\ngem "trueskill", git: "https:\/\/github.com\/benjaminleesmith\/trueskill", ref: "e404f45af5b3fb86982881ce064a9c764cc6a901"' components/app_component/Gemfile


sed -i 's/s.add_dependency "rails", "~> 5.1.4"/s.add_dependency "rails", "5.1.4"\n  s.add_dependency "slim-rails", "3.1.3"\n  s.add_dependency "trueskill"/g' components/app_component/app_component.gemspec
  

echo '
require "slim-rails"
require "saulabs/trueskill"

module AppComponent
  require "app_component/engine"
end
' > components/app_component/lib/app_component.rb


sed -i '/isolate_namespace AppComponent/a\\n    config.generators do |g|\n      g.orm             :active_record\n      g.template_engine :slim\n      g.test_framework  :rspec\n    end' components/app_component/lib/app_component/engine.rb


rm components/app_component/app/views/app_component/welcome/index.html.erb
echo '
h1 Welcome to Sportsball!
p Predicting the outcome of matches since 2015.

= link_to "Manage Teams", teams_path
| &nbsp;|&nbsp;
= link_to "Manage Games", games_path
| &nbsp;|&nbsp;
= link_to "Predict an outcome!", new_prediction_path
' > components/app_component/app/views/app_component/welcome/index.html.slim


echo '
module AppComponent
  class Prediction
    attr_reader :first_team, :second_team, :winner

    def initialize(first_team, second_team, winner)
      @first_team = first_team
      @second_team = second_team
      @winner = winner
    end
  end
end
' > components/app_component/app/models/app_component/prediction.rb


echo '
module AppComponent
  class Predictor
    def initialize(teams)
      @teams_lookup = teams.inject({}) do |memo, team|
        memo[team.id] = {
            team: team,
            rating: [Saulabs::TrueSkill::Rating.new(1500.0, 1000.0, 1.0)]
        }
        memo
      end
    end

    def learn(games)
      games.each do |game|
        first_team_rating = @teams_lookup[game.first_team_id][:rating]
        second_team_rating = @teams_lookup[game.second_team_id][:rating]
        game_result = game.winning_team == 1 ?
            [first_team_rating, second_team_rating] :
            [second_team_rating, first_team_rating]
        Saulabs::TrueSkill::FactorGraph.new(game_result, [1, 2]).update_skills
      end
    end

    def predict(first_team, second_team)
      team1 = @teams_lookup[first_team.id][:team]
      team2 = @teams_lookup[second_team.id][:team]
      winner = higher_mean_team(first_team, second_team) ? team1 : team2
      AppComponent::Prediction.new(team1, team2, winner)
    end

    def higher_mean_team(first_team, second_team)
      @teams_lookup[first_team.id][:rating].first.mean >
          @teams_lookup[second_team.id][:rating].first.mean
    end
  end
end
' > components/app_component/app/models/app_component/predictor.rb


echo '
require_dependency "app_component/application_controller"
module AppComponent
  class PredictionsController < ApplicationController
    def new
      @teams = AppComponent::Team.all
    end

    def create
      predictor = Predictor.new(AppComponent::Team.all)
      predictor.learn(AppComponent::Game.all)
      @prediction = predictor.predict(
          AppComponent::Team.find(params["first_team"]["id"]),
          AppComponent::Team.find(params["second_team"]["id"]))
    end
  end
end
' > components/app_component/app/controllers/app_component/predictions_controller.rb


mkdir -p components/app_component/app/views/app_component/predictions


echo '
h1 Prediction

=prediction_text @prediction.first_team, @prediction.second_team, @prediction.winner

.actions
  = link_to "Try again!", new_prediction_path, class: "button"
' > components/app_component/app/views/app_component/predictions/create.html.slim


echo '
h1 Predictions

= form_tag prediction_path, method: "post" do |f|
  .field
    = label_tag :first_team_id
    = collection_select(:first_team, :id, @teams, :id, :name)

  .field
    = label_tag :second_team_id
    = collection_select(:second_team, :id, @teams, :id, :name)
  .actions = submit_tag "What is it going to be?", class: "button"
' > components/app_component/app/views/app_component/predictions/new.html.slim


echo '
module AppComponent
  module PredictionsHelper
    def prediction_text(team1, team2, winner)
      "In the game between #{team1.name} and #{team2.name} " +
          "the winner will be #{winner.name}"
    end
  end
end
' > components/app_component/app/helpers/app_component/predictions_helper.rb


sed -i "/root to: 'welcome#index'/a\\  resource :prediction, only: [:new, :create]" components/app_component/config/routes.rb

BUNDLE_GEMFILE=`pwd`/Gemfile bundle


cd ..
tar -zcvf $CHAPTER-`date +%Y%m%d%H%M%S`.tgz sportsball
