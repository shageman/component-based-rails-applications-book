#!/bin/bash

set -v
set -x
set -e

gem install --source http://geminabox:9292 bundler -v 1.16.1 --no-ri --no-rdoc

tar -xzf code_input/$PREV_CHAPTER*.tgz -C code_output


cd code_output/sportsball

rm -rf components/app_component/app/views/app_component/games/*
rm -rf components/app_component/app/views/app_component/teams/*
rm -rf components/app_component/app/views/layouts/app_component/*

sed -i '/s.add_development_dependency "sqlite3"/a\\n\n  s.add_development_dependency "rspec-rails"\n  s.add_development_dependency "shoulda-matchers"\n  s.add_development_dependency "database_cleaner"\n  s.add_development_dependency "capybara"\n  s.add_development_dependency "rails-controller-testing"\n' components/app_component/app_component.gemspec

sed -i '/isolate_namespace AppComponent/a\\n        config.generators do |g|\n      g.orm             :active_record\n      g.template_engine :slim\n      g.test_framework  :rspec\n    end
' components/app_component/lib/app_component/engine.rb

cd components/app_component

BUNDLE_GEMFILE=`pwd`/Gemfile bundle

yes | rails g scaffold team name:string

yes | rails g scaffold game date:datetime location:string \
                      first_team_id:integer second_team_id:integer \
                      winning_team:integer \
                      first_team_score:integer second_team_score:integer

cd ../..

################################################################################################
################################################################################################

mkdir -p components/app_component/spec/support/
mkdir -p components/app_component/spec/models/app_component/
mkdir -p components/app_component/spec/controllers/app_component/
mkdir -p components/app_component/spec/helpers/app_component/
mkdir -p components/app_component/spec/features

#echo '
#require "slim-rails"
#require "saulabs/trueskill"
#
#module AppComponent
#  require "app_component/engine"
#end
#' > components/app_component/lib/app_component.rb

echo '
ENV["RAILS_ENV"] ||= "test"

require File.expand_path("../dummy/config/environment", __FILE__)

require "rspec/rails"
require "shoulda/matchers"
require "database_cleaner"
require "capybara/rails"
require "capybara/rspec"
require "ostruct"

require "rails-controller-testing"
Rails::Controller::Testing.install

Dir[AppComponent::Engine.root.join("spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.infer_spec_type_from_file_location!
  config.disable_monkey_patching!
  config.warnings = false
  config.profile_examples = nil
  config.order = :random
  Kernel.srand config.seed

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  [:controller, :view, :request].each do |type|
    config.include ::Rails::Controller::Testing::TestProcess, :type => type
    config.include ::Rails::Controller::Testing::TemplateAssertions, :type => type
    config.include ::Rails::Controller::Testing::Integration, :type => type
  end

  config.include ObjectCreationMethods
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
' > components/app_component/spec/spec_helper.rb

echo '
module ObjectCreationMethods
  def new_team(overrides = {})
    defaults = {
        name: "Some name #{counter}"
    }
    AppComponent::Team.new { |team| apply(team, defaults, overrides) }
  end

  def create_team(overrides = {})
    new_team(overrides).tap(&:save!)
  end

  def new_game(overrides = {})
    defaults = {
        first_team: -> { new_team },
        second_team: -> { new_team },
        winning_team: 2,
        first_team_score: 2,
        second_team_score: 3,
        location: "Somewhere",
        date: Date.today
    }

    AppComponent::Game.new { |game| apply(game, defaults, overrides) }
  end

  def create_game(overrides = {})
    new_game(overrides).tap(&:save!)
  end

  private

  def counter
    @counter ||= 0
    @counter += 1
  end

  def apply(object, defaults, overrides)
    options = defaults.merge(overrides)
    options.each do |method, value_or_proc|
      object.__send__(
          "#{method}=",
          value_or_proc.is_a?(Proc) ? value_or_proc.call : value_or_proc)
    end
  end
end' > components/app_component/spec/support/object_creation_methods.rb

echo '
RSpec.describe AppComponent::Game do
  it { should validate_presence_of :date }
  it { should validate_presence_of :location }
  it { should validate_presence_of :first_team }
  it { should validate_presence_of :second_team }
  it { should validate_presence_of :winning_team }
  it { should validate_presence_of :first_team_score }
  it { should validate_presence_of :second_team_score }

  it { should belong_to :first_team}
  it { should belong_to :second_team}
end
' > components/app_component/spec/models/app_component/game_spec.rb

echo '
RSpec.describe AppComponent::Predictor do
  before do
    @team1 = create_team name: "A"
    @team2 = create_team name: "B"

    @predictor = AppComponent::Predictor.new([@team1, @team2])
  end

  it "predicts teams that have won in the past to win in the future" do
    game = create_game first_team: @team1, second_team: @team2, winning_team: 1
    @predictor.learn([game])

    prediction = @predictor.predict(@team2, @team1)
    expect(prediction.winner).to eq @team1

    prediction = @predictor.predict(@team1, @team2)
    expect(prediction.winner).to eq @team1
  end

  it "changes predictions based on games learned" do
    game1 = create_game first_team: @team1, second_team: @team2, winning_team: 1
    game2 = create_game first_team: @team1, second_team: @team2, winning_team: 2
    game3 = create_game first_team: @team1, second_team: @team2, winning_team: 2
    @predictor.learn([game1, game2, game3])

    prediction = @predictor.predict(@team1, @team2)
    expect(prediction.winner).to eq @team2
  end

  it "behaves funny when teams are equally strong" do
    prediction = @predictor.predict(@team1, @team2)
    expect(prediction).to be_an AppComponent::Prediction
    expect(prediction.first_team).to eq @team1
    expect(prediction.second_team).to eq @team2
    expect(prediction.winner).to eq @team2

    prediction = @predictor.predict(@team2, @team1)
    expect(prediction).to be_an AppComponent::Prediction
    expect(prediction.first_team).to eq @team2
    expect(prediction.second_team).to eq @team1
    expect(prediction.winner).to eq @team1
  end
end
' > components/app_component/spec/models/app_component/predictor_spec.rb

echo '
RSpec.describe AppComponent::Team do
  it { should validate_presence_of :name }
end
' > components/app_component/spec/models/app_component/team_spec.rb


echo '
module AppComponent
  class Game < ApplicationRecord
    validates :date, :location, :first_team, :second_team, :winning_team,
              :first_team_score, :second_team_score, presence: true
    belongs_to :first_team, class_name: "Team"
    belongs_to :second_team, class_name: "AppComponent::Team"
  end
end
' > components/app_component/app/models/app_component/game.rb

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
module AppComponent
  class Team < ApplicationRecord
    validates :name, presence: true
  end
end
' > components/app_component/app/models/app_component/team.rb

echo '
--color
--require spec_helper
' > components/app_component/.rspec



echo '
RSpec.describe AppComponent::GamesController, :type => :controller do
  routes { AppComponent::Engine.routes }

  before do
    @team1 = create_team
    @team2 = create_team
  end

  let(:valid_attributes) { new_game(first_team_id: @team1.id, second_team_id: @team2.id).as_json }
  let(:invalid_attributes) { new_game(first_team_id: @team1.id, second_team_id: @team2.id).tap { |g| g.location = nil }.as_json }
  let(:valid_session) { {} }

  describe "GET index" do
    it "assigns all games as @games" do
      game = create_game
      get :index, params: {}, session: valid_session
      expect(assigns(:games)).to eq [game]
    end

    it "routes to #index" do
      expect(:get => "/games").to route_to("app_component/games#index")
    end
  end

  describe "GET show" do
    it "assigns the requested game as @game" do
      game = create_game
      get :show, params: {:id => game.to_param}, session: valid_session
      expect(assigns(:game)).to eq game
    end

    it "routes to #show" do
      expect(:get => "/games/1").to route_to("app_component/games#show", :id => "1")
    end
  end

  describe "GET new" do
    it "assigns a new game as @game" do
      get :new, params: {}, session: valid_session
      expect(assigns(:game)).to be_a_new AppComponent::Game
    end

    it "routes to #new" do
      expect(:get => "/games/new").to route_to("app_component/games#new")
    end
  end

  describe "GET edit" do
    it "assigns the requested game as @game" do
      game = create_game
      get :edit, params: {:id => game.to_param}, session: valid_session
      expect(assigns(:game)).to eq game
    end

    it "routes to #edit" do
      expect(:get => "/games/1/edit").to route_to("app_component/games#edit", :id => "1")
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new AppComponent::Game" do
        expect {
          post :create, params: {:game => valid_attributes}, session: valid_session
        }.to change(AppComponent::Game, :count).by 1
      end

      it "assigns a newly created game as @game" do
        post :create, params: {:game => valid_attributes}, session: valid_session
        expect(assigns(:game)).to be_a AppComponent::Game
        expect(assigns(:game)).to be_persisted
      end

      it "redirects to the created game" do
        post :create, params: {:game => valid_attributes}, session: valid_session
        expect(response).to redirect_to AppComponent::Game.last
      end

      it "routes to #create" do
        expect(:post => "/games").to route_to("app_component/games#create")
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved game as @game" do
        post :create, params: {:game => invalid_attributes}, session: valid_session
        expect(assigns(:game)).to be_a_new AppComponent::Game
      end

      it "re-renders the new template" do
        post :create, params: {:game => invalid_attributes}, session: valid_session
        expect(response).to render_template "new"
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested game" do
        game = create_game
        new_time = 1.day.ago
        put :update, params: {:id => game.to_param, :game => {date: new_time}}, session: valid_session
        game.reload
        expect(assigns(:game).date).to be_within(1).of new_time
      end

      it "assigns the requested game as @game" do
        game = create_game
        put :update, params: {:id => game.to_param, :game => valid_attributes}, session: valid_session
        expect(assigns(:game)).to eq game
      end

      it "redirects to the game" do
        game = create_game
        put :update, params: {:id => game.to_param, :game => valid_attributes}, session: valid_session
        expect(response).to redirect_to game
      end

      it "routes to #update" do
        expect(:put => "/games/1").to route_to("app_component/games#update", :id => "1")
      end
    end

    describe "with invalid params" do
      it "assigns the game as @game" do
        game = create_game
        put :update, params: {:id => game.to_param, :game => invalid_attributes}, session: valid_session
        expect(assigns(:game)).to eq game
      end

      it "re-renders the edit template" do
        game = create_game
        put :update, params: {:id => game.to_param, :game => invalid_attributes}, session: valid_session
        expect(response).to render_template "edit"
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested game" do
      game = create_game
      expect {
        delete :destroy, params: {:id => game.to_param}, session: valid_session
      }.to change(AppComponent::Game, :count).by -1
    end

    it "redirects to the games list" do
      game = create_game
      delete :destroy, params: {:id => game.to_param}, session: valid_session
      expect(response).to redirect_to games_url
    end

    it "routes to #destroy" do
      expect(:delete => "/games/1").to route_to("app_component/games#destroy", :id => "1")
    end
  end
end
' > components/app_component/spec/controllers/app_component/games_controller_spec.rb

echo '
RSpec.describe AppComponent::PredictionsController, :type => :controller do
  routes { AppComponent::Engine.routes }

  before do
    @team1 = create_team
    @team2 = create_team
  end

  describe "GET new" do
    it "assigns all teams as @teams" do
      get :new, params: {}, session: {}
      expect(assigns(:teams)).to eq [@team1, @team2]
    end
  end

  describe "POST create" do
    it "assigns a prediction as @prediction" do
      post :create,
           params: {first_team: {id: @team1.id}, second_team: {id: @team2.id}},
           session: {}

      prediction = assigns(:prediction)
      expect(prediction).to be_a AppComponent::Prediction
      expect(prediction.first_team).to eq @team1
      expect(prediction.second_team).to eq @team2
    end
  end
end

' > components/app_component/spec/controllers/app_component/predictions_controller_spec.rb

echo '
RSpec.describe AppComponent::TeamsController, :type => :controller do
  routes { AppComponent::Engine.routes }

  let(:valid_attributes) { new_team.as_json }
  let(:invalid_attributes) { new_team.tap { |g| g.name = nil }.as_json }
  let(:valid_session) { {} }

  describe "GET index" do
    it "assigns all teams as @teams" do
      team = create_team
      get :index, params: {}, session: valid_session
      expect(assigns(:teams)).to eq [team]
    end

    describe "view" do
      render_views

      it "renders a list of teams" do
        create_team name: "myteam x"
        create_team name: "myteam x"

        get :index, params: {}, session: valid_session

        assert_select "tr>td", :text => "myteam x", :count => 2
      end
    end
  end

  describe "GET new" do
    it "assigns a new team as @team" do
      get :new, params: {}, session: valid_session
      expect(assigns(:team)).to be_a_new AppComponent::Team
    end

    describe "view" do
      render_views

      it "renders new team form" do
        get :new, params: {}, session: valid_session

        assert_select "form[action=?][method=?]", teams_path, "post" do
          assert_select "input#team_name[name=?]", "team[name]"
        end
      end
    end
  end

  describe "GET edit" do
    it "assigns the requested team as @team" do
      team = create_team
      get :edit, params: {:id => team.to_param}, session: valid_session
      expect(assigns(:team)).to eq team
    end

    describe "view" do
      render_views

      it "renders the edit team form" do
        team = create_team
        get :edit, params: {:id => team.to_param}, session: valid_session

        assert_select "form[action=?][method=?]", team_path(team), "post" do
          assert_select "input#team_name[name=?]", "team[name]"
        end
      end
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new AppComponent::Team" do
        expect {
          post :create, params: {:team => valid_attributes}, session: valid_session
        }.to change(AppComponent::Team, :count).by 1
      end

      it "assigns a newly created team as @team" do
        post :create, params: {:team => valid_attributes}, session: valid_session
        expect(assigns(:team)).to be_a AppComponent::Team
        expect(assigns(:team)).to be_persisted
      end

      it "redirects to the index" do
        post :create, params: {:team => valid_attributes}, session: valid_session
        expect(response).to redirect_to teams_path
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved team as @team" do
        post :create, params: {:team => invalid_attributes}, session: valid_session
        expect(assigns(:team)).to be_a_new AppComponent::Team
      end

      it "re-renders the new template" do
        post :create, params: {:team => invalid_attributes}, session: valid_session
        expect(response).to render_template "new"
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      let(:new_attributes) {
        {name: "new team name"}
      }

      it "updates the requested team" do
        team = create_team
        put :update, params: {:id => team.to_param, :team => new_attributes}, session: valid_session
        team.reload
        expect(assigns(:team).name).to eq "new team name"
      end

      it "assigns the requested team as @team" do
        team = create_team
        put :update, params: {:id => team.to_param, :team => valid_attributes}, session: valid_session
        expect(assigns(:team)).to eq team
      end

      it "redirects to the index" do
        team = create_team
        put :update, params: {:id => team.to_param, :team => valid_attributes}, session: valid_session
        expect(response).to redirect_to teams_path
      end
    end

    describe "with invalid params" do
      it "assigns the team as @team" do
        team = create_team
        put :update, params: {:id => team.to_param, :team => invalid_attributes}, session: valid_session
        expect(assigns(:team)).to eq team
      end

      it "re-renders the edit template" do
        team = create_team
        put :update, params: {:id => team.to_param, :team => invalid_attributes}, session: valid_session
        expect(response).to render_template "edit"
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested team" do
      team = create_team
      expect {
        delete :destroy, params: {:id => team.to_param}, session: valid_session
      }.to change(AppComponent::Team, :count).by -1
    end

    it "redirects to the teams list" do
      team = create_team
      delete :destroy, params: {:id => team.to_param}, session: valid_session
      expect(response).to redirect_to teams_url
    end
  end
end
' > components/app_component/spec/controllers/app_component/teams_controller_spec.rb

echo '
RSpec.describe AppComponent::WelcomeController, :type => :controller do
  routes { AppComponent::Engine.routes }

  describe "GET index" do
    it "returns http success" do
      get :show
      expect(response).to have_http_status(:success)
    end
  end
end
' > components/app_component/spec/controllers/app_component/welcome_controller_spec.rb

echo '
require_dependency "app_component/application_controller"
module AppComponent
  class GamesController < ApplicationController
    before_action :set_game, only: [:show, :edit, :update, :destroy]

    def index
      @games = Game.all
    end

    def show
    end

    def new
      @game = Game.new
    end

    def edit
    end

    def create
      @game = Game.new(game_params)

      if @game.save
        redirect_to @game, notice: "Game was successfully created."
      else
        render :new
      end
    end

    def update
      if @game.update(game_params)
        redirect_to @game, notice: "Game was successfully updated."
      else
        render :edit
      end
    end

    def destroy
      @game.destroy
      redirect_to games_url, notice: "Game was successfully destroyed."
    end

    private
      def set_game
        @game = Game.find(params[:id])
      end

      def game_params
        params.require(:game).permit(:date, :location, :first_team_id, :second_team_id, :winning_team, :first_team_score, :second_team_score)
      end
  end
end
' > components/app_component/app/controllers/app_component/games_controller.rb

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

echo '
require_dependency "app_component/application_controller"
module AppComponent
  class TeamsController < ApplicationController
    before_action :set_team, only: [:show, :edit, :update, :destroy]

    def index
      @teams = Team.all
    end

    def new
      @team = Team.new
    end

    def edit
    end

    def create
      @team = Team.new(team_params)

      if @team.save
        redirect_to teams_url, notice: "Team was successfully created."
      else
        render :new
      end
    end

    def update
      if @team.update(team_params)
        redirect_to teams_url, notice: "Team was successfully updated."
      else
        render :edit
      end
    end

    def destroy
      @team.destroy
      redirect_to teams_url, notice: "Team was successfully destroyed."
    end

    private
      def set_team
        @team = Team.find(params[:id])
      end

      def team_params
        params.require(:team).permit(:name)
      end
  end
end
' > components/app_component/app/controllers/app_component/teams_controller.rb

echo '
require_dependency "app_component/application_controller"
module AppComponent
  class WelcomeController < ApplicationController
    def show
    end
  end
end
' > components/app_component/app/controllers/app_component/welcome_controller.rb

echo '
AppComponent::Engine.routes.draw do
  resources :games
  resources :teams

  resource :welcome, only: [:show]
  resource :prediction, only: [:new, :create]

  root to: "welcome#show"
end
' > components/app_component/config/routes.rb

echo '
h1 Teams

table
  thead
    tr
      th Name
      th
      th

  tbody
    - @teams.each do |team|
      tr
        td = team.name
        td = link_to "Edit", edit_team_path(team), class: "button tiny"
        td = link_to "Destroy", team, data: {:confirm => "Are you sure?"}, :method => :delete, class: "button tiny alert"

br

= link_to "New Team", new_team_path, class: "button"
' > components/app_component/app/views/app_component/teams/index.html.slim

echo '
h1 Games

table
  thead
    tr
      th Date
      th Location
      th First team
      th Second team
      th
      th
      th

  tbody
    - @games.each do |game|
      tr
        td = game.date
        td = game.location
        - if game.winning_team == 1
          td
            strong = game.first_team.name
          td = game.second_team.name
        - else
          td = game.first_team.name
          td
            strong = game.second_team.name
        td = link_to "Show", game, class: "button tiny"
        td = link_to "Edit", edit_game_path(game), class: "button tiny"
        td = link_to "Destroy", game, data: {:confirm => "Are you sure?"}, :method => :delete, class: "button tiny alert"

br

= link_to "New Game", new_game_path, class: "button"
' > components/app_component/app/views/app_component/games/index.html.slim

echo '
p#notice = notice

p
  strong Date:
  = @game.date
p
  strong Location:
  = @game.location
p
  strong First team:
  = @game.first_team.name
p
  strong Second team:
  = @game.second_team.name
p
  strong Winning team:
  = @game.winning_team
p
  strong First team score:
  = @game.first_team_score
p
  strong Second team score:
  = @game.second_team_score

= link_to "Edit", edit_game_path(@game), class: "button"
''|
= link_to "Back", games_path, class: "button"
' > components/app_component/app/views/app_component/games/show.html.slim

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
h1 Sportsball!
h2 Predicting the outcome of matches since 2015.
' > components/app_component/app/views/app_component/welcome/show.html.slim

echo '
|<!DOCTYPE html>
html
  head
    meta charset="utf-8"
    meta name="viewport" content="width=device-width, initial-scale=1.0"

    title Sportsball App

    = javascript_include_tag "app_component/application"
    = stylesheet_link_tag    "app_component/application", media: "all"

    = csrf_meta_tags

  header
    .contain-to-grid.sticky
      nav.top-bar data-topbar="" role="navigation"
        ul.title-area
          li.name
            h1
              = link_to root_path do
                | Predictor

          li.toggle-topbar.menu-icon
            a href="#"
              span Menu

        section.top-bar-section
          ul.left
            li =link_to "Teams", teams_path
            li =link_to "Games", games_path
            li =link_to "Predictions", new_prediction_path

  main
    .row
      .small-12.columns
        = yield
' > components/app_component/app/views/layouts/app_component/application.html.slim




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

echo '
require "spec_helper"

RSpec.describe AppComponent::PredictionsHelper, :type => :helper do
  it "returns a nice prediction text" do
    Named = Struct.new(:name)
    text = prediction_text(Named.new("A"), Named.new("B"), Named.new("C"))
    expect(text).to eq "In the game between A and B the winner will be C"
  end
end
' > components/app_component/spec/helpers/app_component/predictions_helper_spec.rb

rm components/app_component/spec/helpers/app_component/games_helper_spec.rb
rm components/app_component/spec/helpers/app_component/teams_helper_spec.rb



echo '
require "spec_helper"

RSpec.describe "the prediction process", :type => :feature do
  before :each do
    team1 = create_team name: "UofL"
    team2 = create_team name: "UK"

    create_game first_team: team1, second_team: team2, winning_team: 1
    create_game first_team: team2, second_team: team1, winning_team: 2
    create_game first_team: team2, second_team: team1, winning_team: 2
  end

  it "get a new prediction" do
    visit "/app_component/"

    click_link "Predictions"

    select "UofL", from: "First team"
    select "UK", from: "Second team"
    click_button "What is it going to be"

    expect(page).to have_content "the winner will be UofL"
  end
end
' > components/app_component/spec/features/predictions_spec.rb

echo '
require "spec_helper"

RSpec.describe "games admin", :type => :feature do
  before :each do
    @team1 = create_team name: "UofL"
    @team2 = create_team name: "UK"
  end

  it "allows for the management of games" do
    visit "/app_component/games"

    click_link "New Game"

    fill_in "First team", with: @team1.id
    fill_in "Second team", with: @team2.id
    fill_in "Winning team", with: 1
    fill_in "First team score", with: 2
    fill_in "Second team score", with: 1
    fill_in "Location", with: "Home"

    click_on "Create Game"

    expect(page).to have_content "UofL"
  end
end
' > components/app_component/spec/features/games_spec.rb

echo '
require "spec_helper"

RSpec.describe "teams admin", :type => :feature do
  it "allows for the management of teams" do
    visit "/app_component/teams"

    click_link "New Team"

    fill_in "Name", with: "UofL"
    click_on "Create Team"

    click_link "New Team"

    fill_in "Name", with: "UK"
    click_on "Create Team"

    expect(page).to have_content "UofL"
    expect(page).to have_content "UK"
  end
end
' > components/app_component/spec/features/teams_spec.rb



mv components/app_component/test/dummy components/app_component/spec/
rm -r components/app_component/test
sed -i "s/\.\.\/test\/dummy\/Rakefile/\.\.\/spec\/dummy\/Rakefile/g" components/app_component/Rakefile


rm -r components/app_component/spec/routing
rm -r components/app_component/spec/views
rm -rf components/app_component/app/jobs
rm -rf components/app_component/app/mailers
rm components/app_component/app/assets/stylesheets/scaffold.css
rm components/app_component/app/assets/images/app_component/.keep
rm components/app_component/app/helpers/app_component/application_helper.rb
rm components/app_component/app/helpers/app_component/games_helper.rb
rm components/app_component/app/helpers/app_component/teams_helper.rb
rm components/app_component/app/helpers/app_component/welcome_helper.rb

cd ..

tar -zcvf $CHAPTER-`date +%Y%m%d%H%M%S`.tgz sportsball

