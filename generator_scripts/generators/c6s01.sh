#!/bin/bash

set -v
set -x
set -e

gem install --source http://geminabox:9292 bundler -v 1.16.1 --no-ri --no-rdoc

tar -xzf code_input/$PREV_CHAPTER*.tgz -C code_output


cd code_output/sportsball

BUNDLE_GEMFILE=`pwd`/Gemfile bundle


rm -rf components/teams_store

mv components/teams components/teams_OLD


############################################################################################################
############################################################################################################
### PUBLISHER
############################################################################################################
############################################################################################################
bundle gem publisher --test=rspec --no-exe --no-coc --no-mit
rm -rf publisher/.git
mv publisher components

mkdir -p components/publisher/spec

echo '
module Publisher
  def add_subscriber(object)
    @subscribers ||= []
    @subscribers << object
  end

  def publish(message, *args)
    return if @subscribers == [] || @subscribers == nil
    @subscribers.each do |subscriber|
      if subscriber.respond_to?(message)
        subscriber.send(message, *args)
      end
    end
  end
end
' > components/publisher/lib/publisher.rb

echo '
require "spec_helper"

describe Publisher do
  class PublisherTestHarness
    include Publisher
  end

  class SomeMessageSubscriber
    attr_accessor :some_message_called, :hello_called
    def some_message
      @some_message_called = true
    end

    def hello
      @hello_called = true
    end
  end

  class HelloSubscriber
    attr_accessor :hello_called
    def hello
      @hello_called = true
    end
  end

  subject do
    PublisherTestHarness.new
  end

  before do
    @subscriber1 = SomeMessageSubscriber.new
    @subscriber2 = HelloSubscriber.new
  end

  it "will do nothing if there are no subscribers" do
    expect {
      subject.publish(:some_message)
    }.not_to raise_exception
  end

  it "will not send a message to a subscriber that does not have the method" do
    subject.add_subscriber(@subscriber2)
    subject.publish(:some_message)
    expect(@subscriber2.hello_called).to eq(nil)
  end

  it "will call the message''s method on the subscriber if it exists" do
    subject.add_subscriber(@subscriber1)
    subject.publish(:some_message)
    expect(@subscriber1.some_message_called).to eq(true)
  end

  it "will send messages to multiple subscribers" do
    subject.add_subscriber(@subscriber1)
    subject.add_subscriber(@subscriber2)
    subject.publish(:hello)
    expect(@subscriber1.hello_called).to eq(true)
    expect(@subscriber1.hello_called).to eq(true)
  end

  it "causes problems to send the wrong number of params" do
    subject.add_subscriber(@subscriber1)
    expect {
      subject.publish(:some_message, "erroneous_parameter")
    }.to raise_exception(ArgumentError)
  end
end
' > components/publisher/spec/publisher_spec.rb

echo '
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "publisher"
' > components/publisher/spec/spec_helper.rb

echo '
# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "publisher"
  spec.version       = "0.0.1"
  spec.authors       = ["Stephan Hagemann"]
  spec.email         = ["stephan.hagemann@gmail.com"]

  spec.summary       = %q{Simple pub/sub implementation}

  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = ""
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
' > components/publisher/publisher.gemspec

echo '
#!/bin/bash

exit_code=0

echo "
********************************************************************************
*** Running publisher gem specs
********************************************************************************"

bundle install | grep Installing
bundle exec rspec spec
((exit_code+=$?))

exit $exit_code
' > components/publisher/test.sh

chmod +x components/publisher/test.sh


############################################################################################################
############################################################################################################
### PREDICTOR
############################################################################################################
############################################################################################################

echo '
module Predictor
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
      if game_predictable?(first_team, second_team)
        team1 = @teams_lookup[first_team.id][:team]
        team2 = @teams_lookup[second_team.id][:team]
        winner = higher_mean_team(first_team, second_team) ? team1 : team2
        ::Predictor::Prediction.new(team1, team2, winner)
      else
        ::Predictor::PredictionError.new(team1, team2, "Two teams needed for prediction")
      end
    end

    def game_predictable?(first_team, second_team)
      first_team != second_team
    end

    private

    def higher_mean_team(first_team, second_team)
      @teams_lookup[first_team.id][:rating].first.mean >
          @teams_lookup[second_team.id][:rating].first.mean
    end
  end
end
' > components/predictor/lib/predictor/predictor.rb

echo '
module Predictor
  class PredictionError < Prediction
    attr_reader :message

    def initialize(first_team, second_team, message)
      super(first_team, second_team, nil)
      @message = message
    end
  end
end
' > components/predictor/lib/predictor/prediction_error.rb

echo '
require "saulabs/trueskill"

module Predictor
  require "predictor/predictor"
  require "predictor/prediction"
  require "predictor/prediction_error"
end
' > components/predictor/lib/predictor.rb

echo '
require "spec_helper"

RSpec.describe Predictor::Predictor do
  before do
    @team1 = OpenStruct.new(id: 6)
    @team2 = OpenStruct.new(id: 7)

    @predictor = Predictor::Predictor.new([@team1, @team2])
  end

  it "predicts teams that have won in the past to win in the future" do
    game = OpenStruct.new(
        first_team_id: @team1.id, second_team_id: @team2.id, winning_team: 1)
    @predictor.learn([game])

    prediction = @predictor.predict(@team2, @team1)
    expect(prediction.winner).to eq @team1

    prediction = @predictor.predict(@team1, @team2)
    expect(prediction.winner).to eq @team1
  end

  it "changes predictions based on games learned" do
    game1 = OpenStruct.new(
        first_team_id: @team1.id, second_team_id: @team2.id, winning_team: 1)
    game2 = OpenStruct.new(
        first_team_id: @team1.id, second_team_id: @team2.id, winning_team: 2)
    game3 = OpenStruct.new(
        first_team_id: @team1.id, second_team_id: @team2.id, winning_team: 2)
    @predictor.learn([game1, game2, game3])

    prediction = @predictor.predict(@team1, @team2)
    expect(prediction.winner).to eq @team2
  end

  it "will only predict games between two teams" do
    expect(@predictor.game_predictable?(@team1, @team2)).to eq true
    expect(@predictor.game_predictable?(@team1, @team1)).to eq false
  end

  it "throws an error when predicting an impossible game" do
    prediction = @predictor.predict(@team1, @team1)
    expect(prediction).to be_a(::Predictor::PredictionError)
  end

  it "behaves funny when teams are equally strong" do
    prediction = @predictor.predict(@team1, @team2)
    expect(prediction.first_team).to eq @team1
    expect(prediction.second_team).to eq @team2
    expect(prediction.winner).to eq @team2

    prediction = @predictor.predict(@team2, @team1)
    expect(prediction.first_team).to eq @team2
    expect(prediction.second_team).to eq @team1
    expect(prediction.winner).to eq @team1
  end
end
' > components/predictor/spec/predictor_spec.rb



############################################################################################################
############################################################################################################
### TEAMS
############################################################################################################
############################################################################################################
bundle gem teams --test=rspec --no-exe --no-coc --no-mit
rm -rf teams/.git
mv teams components

mkdir -p components/teams/spec

echo '
module Teams
  class Team
    include ActiveModel::Conversion
    include ActiveModel::Validations
    include ActiveModel::Naming

    attr_reader :id, :name

    def initialize(id=nil, name=nil)
      @id = id
      @name = name
    end

    def persisted?
      @id != nil
    end

    def ==(other)
      other.is_a?(Teams::Team) && @id == other.id
    end

    def new_record?
      !persisted?
    end
  end
end
' > components/teams/lib/teams/team.rb

echo '
require "active_model"

module Teams
  require "teams/team"
end
' > components/teams/lib/teams.rb

echo '
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "teams"
' > components/teams/spec/spec_helper.rb

echo '
require "spec_helper"

RSpec.describe Teams::Team do
  it "can be initialized without values" do
    nil_team = Teams::Team.new
    expect(nil_team.id).to eq(nil)
    expect(nil_team.name).to eq(nil)
  end

  it "takes an id and a name" do
    team = Teams::Team.new(3, "seven")
    expect(team.id).to eq(3)
    expect(team.name).to eq("seven")
  end

  it "is persisted iff an id is set" do
    nil_team = Teams::Team.new
    expect(nil_team.persisted?).to eq(false)

    team = Teams::Team.new(3, "seven")
    expect(team.persisted?).to eq(true)
  end
end
' > components/teams/spec/teams_spec.rb

echo '
#coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "teams/version"

Gem::Specification.new do |spec|
  spec.name          = "teams"
  spec.version       = Teams::VERSION
  spec.authors       = ["Stephan Hagemann"]
  spec.email         = ["stephan.hagemann@gmail.com"]

  spec.summary       = %q{Teams Class}
  spec.description   = %q{Teams Class}

  # Prevent pushing this gem to RubyGems.org by setting allowed_push_host, or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = ""
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activemodel", "5.1.4"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
' > components/teams/teams.gemspec

echo '
#!/bin/bash

exit_code=0

echo "
********************************************************************************
*** Running teams gem specs
********************************************************************************"

bundle install | grep Installing
bundle exec rspec spec
((exit_code+=$?))

exit $exit_code
' > components/teams/test.sh

chmod +x components/teams/test.sh


############################################################################################################
############################################################################################################
### PREDICT GAME
############################################################################################################
############################################################################################################
bundle gem predict_game --test=rspec --no-exe --no-coc --no-mit
rm -rf predict_game/.git
mv predict_game components

mkdir -p components/predict_game/spec

echo '
module PredictGame
  class PredictGame
    include Publisher

    def initialize(teams, games)
      @predictor = ::Predictor::Predictor.new(teams)
      @predictor.learn(games)
    end

    def perform(team1_id, team2_id)
      if @predictor.game_predictable?(team1_id, team2_id)
        publish(
            :prediction_succeeded,
            @predictor.predict(team1_id, team2_id))
      else
        publish(
            :prediction_failed,
            @predictor.predict(team1_id, team2_id),
            "Prediction can not be performed with a team against itself")
      end
    end
  end
end' > components/predict_game/lib/predict_game/predict_game.rb

echo '
require "predictor"
require "publisher"

module PredictGame
  require "predict_game/predict_game"
end
' > components/predict_game/lib/predict_game.rb

echo '
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
' > components/predict_game/spec/predict_game_spec.rb

echo '
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "predict_game"
' > components/predict_game/spec/spec_helper.rb

echo '
# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "predict_game"
  spec.version       = "0.0.1"
  spec.authors       = ["Stephan Hagemann"]
  spec.email         = ["stephan.hagemann@gmail.com"]

  spec.summary       = %q{Predict Game Use Case}

  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = ""
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "predictor"
  spec.add_dependency "publisher"
  spec.add_dependency "teams_store"
  spec.add_dependency "games"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
' > components/predict_game/predict_game.gemspec

echo '
source "https://rubygems.org"

# Specify your gem''s dependencies in predict_game.gemspec
gemspec

path ".." do
  gem "predictor"
  gem "publisher"
  gem "teams_store"
  gem "games"
end' > components/predict_game/Gemfile

echo '
#!/bin/bash

exit_code=0

echo "
********************************************************************************
*** Running predict_game engine specs
********************************************************************************"

bundle install | grep Installing
bundle exec rspec spec
((exit_code+=$?))

exit $exit_code
' > components/predict_game/test.sh

chmod +x components/predict_game/test.sh


############################################################################################################
############################################################################################################
### TEAMS_STORE_MEM
############################################################################################################
############################################################################################################
bundle gem teams_store_mem --test=rspec --no-exe --no-coc --no-mit
rm -rf teams_store_mem/.git
mv teams_store_mem components

mv components/teams_store_mem/lib/teams_store_mem components/teams_store_mem/lib/teams_store

mkdir -p components/teams_store_mem/spec/models/teams
mkdir -p components/teams_store_mem/spec/support

rm components/teams_store_mem/teams_store_mem.gemspec
rm components/teams_store_mem/lib/teams_store_mem.rb
rm components/teams_store_mem/spec/teams_store_mem_spec.rb

echo '
module TeamsStore
  module Db
    def self.reset
      $teams_db = {}
    end

    def self.get
      $teams_db
    end
  end
end
' > components/teams_store_mem/lib/teams_store/db.rb

echo '
module TeamsStore
  class TeamRepository
    def get_all
      TeamsStore::Db.get.values
    end

    def get(key)
      id = key.to_i
      TeamsStore::Db.get[id]
    end

    def create(team)
      return team if [nil, ""].include? team.name

      id = TeamsStore::Db.get.keys.max && TeamsStore::Db.get.keys.max + 1 || 1
      TeamsStore::Db.get[id] = Teams::Team.new(id, team.name)
    end

    def update(key, name)
      id = key.to_i
      return false if [nil, ""].include? name

      TeamsStore::Db.get[id] = Teams::Team.new(id, name)
      true
    end

    def delete(key)
      id = key.to_i

      TeamsStore::Db.get.delete(id)
      id
    end
  end
end
' > components/teams_store_mem/lib/teams_store/team_repository.rb

echo '
require_relative "../../spec/support/object_creation_methods.rb"
' > components/teams_store_mem/lib/teams_store/test_helpers.rb

echo '
require "teams"

require_relative "teams_store/db"
require_relative "teams_store/team_repository"

TeamsStore::Db.reset
' > components/teams_store_mem/lib/teams_store.rb

echo '
require "spec_helper"

RSpec.describe TeamsStore::TeamRepository do
  describe "create" do
    it "creates a persisted record" do
      team = subject.create(Teams::Team.new(nil, "testTeam"))
      expect(team).to be_a(Teams::Team)
      expect(team.id).to_not eq(nil)
      expect(team.name).to eq("testTeam")

      stored_team = TeamsStore::Db.get[team.id]
      expect(stored_team.id).to eq(team.id)
      expect(stored_team.name).to eq("testTeam")
    end

    it "can''t create a persisted record if the model is invalid" do
      team = subject.create(Teams::Team.new(nil, ""))
      expect(team).to be_a(Teams::Team)
      expect(team.id).to eq(nil)
      expect(team.name).to eq("")

      team = subject.create(Teams::Team.new(nil, nil))
      expect(team).to be_a(Teams::Team)
      expect(team.id).to eq(nil)
      expect(team.name).to eq(nil)

      stored_team = TeamsStore::Db.get[team.id]
      expect(stored_team).to eq(nil)
    end
  end

  describe "update" do
    it "creates a persisted record" do
      team = subject.create(Teams::Team.new(nil, "testTeam"))

      updated_team = subject.update(team.id, "newName")
      expect(updated_team).to eq(true)

      stored_team = TeamsStore::Db.get[team.id]
      expect(stored_team.id).to eq(team.id)
      expect(stored_team.name).to eq("newName")

      updated_team = subject.update(team.id, "")
      expect(updated_team).to eq(false)

      updated_team = subject.update(team.id, nil)
      expect(updated_team).to eq(false)

      stored_team = TeamsStore::Db.get[team.id]
      expect(stored_team.id).to eq(team.id)
      expect(stored_team.name).to eq("newName")
    end

    it "handles string ids" do
      team = subject.create(Teams::Team.new(nil, "testTeam"))

      updated_team = subject.update(team.id.to_s, "newName")
      expect(updated_team).to eq(true)

      stored_team = TeamsStore::Db.get[team.id]
      expect(stored_team.id).to eq(team.id)
      expect(stored_team.name).to eq("newName")
    end
  end

  describe "delete" do
    it "deletes the persisted record" do
      team = subject.create(Teams::Team.new(nil, "testTeam"))

      updated_team = subject.delete(team.id)
      expect(updated_team).to eq(team.id)

      stored_team = TeamsStore::Db.get[team.id]
      expect(stored_team).to eq(nil)
    end

    it "handles string ids" do
      team = subject.create(Teams::Team.new(nil, "testTeam"))

      updated_team = subject.delete(team.id.to_s)
      expect(updated_team).to eq(team.id)

      stored_team = TeamsStore::Db.get[team.id]
      expect(stored_team).to eq(nil)
    end
  end

  describe "get" do
    it "retrieves previously persisted record" do
      team = subject.create(Teams::Team.new(nil, "testTeam"))

      retrieved_team = subject.get(team.id)
      expect(retrieved_team).to be_a(Teams::Team)
      expect(retrieved_team.id).to_not eq(nil)
      expect(retrieved_team.name).to eq("testTeam")
    end

    it "handles string ids" do
      team = subject.create(Teams::Team.new(nil, "testTeam"))

      retrieved_team = subject.get(team.id.to_s)
      expect(retrieved_team).to be_a(Teams::Team)
      expect(retrieved_team.id).to_not eq(nil)
      expect(retrieved_team.name).to eq("testTeam")
    end
  end

  describe "get_all" do
    it "retrieves all previously persisted record" do
      subject.create(Teams::Team.new(nil, "testTeam1"))
      subject.create(Teams::Team.new(nil, "testTeam2"))

      retrieved_teams = subject.get_all
      expect(retrieved_teams.size).to eq(2)

      expect(retrieved_teams[0]).to be_a(Teams::Team)
      expect(retrieved_teams[0].id).to_not eq(nil)
      expect(retrieved_teams[0].name).to eq("testTeam1")

      expect(retrieved_teams[1]).to be_a(Teams::Team)
      expect(retrieved_teams[1].id).to_not eq(nil)
      expect(retrieved_teams[1].name).to eq("testTeam2")
    end
  end
end
' > components/teams_store_mem/spec/models/teams/team_repository_spec.rb

echo '
module TeamsStore::ObjectCreationMethods
  def new_team(overrides = {})
    Teams::Team.new(nil, overrides[:name] || "Some name #{counter}")
  end

  def create_team(overrides = {})
    TeamsStore::TeamRepository.new.create(new_team(overrides))
  end

  private

  def counter
    @counter ||= 0
    @counter += 1
  end
end
' > components/teams_store_mem/spec/support/object_creation_methods.rb

echo '
ENV["RAILS_ENV"] ||= "test"

require "active_model"

require File.expand_path("../../lib/teams_store.rb", __FILE__)

require "rspec"

Dir[File.expand_path("../support/**/*.rb", __FILE__)].each {|f| require f}

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.disable_monkey_patching!
  config.warnings = false
  config.profile_examples = nil
  config.order = :random
  Kernel.srand config.seed

  config.before :each do
    TeamsStore::Db.reset
  end

  config.include TeamsStore::ObjectCreationMethods
end
' > components/teams_store_mem/spec/spec_helper.rb

echo '
$:.push File.expand_path("../lib", __FILE__)

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "teams_store"
  s.version     = "0.0.1"
  s.authors     = ["Your name"]
  s.email       = ["Your email"]
  s.summary     = "Summary of TeamsStore."
  s.description = "Description of TeamsStore."

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "teams"

  s.add_development_dependency "rspec"
end
' > components/teams_store_mem/teams_store.gemspec

echo '
source "https://rubygems.org"

path ".." do
  gem "teams"
end

gemspec
' > components/teams_store_mem/Gemfile

echo '
#!/bin/bash

exit_code=0

echo "
********************************************************************************
*** Running teams_store MEM engine specs
********************************************************************************"

bundle install | grep Installing
bundle exec rspec spec
((exit_code+=$?))

exit $exit_code
' > components/teams_store_mem/test.sh

chmod +x components/teams_store_mem/test.sh


############################################################################################################
############################################################################################################
### TEAMS_STORE_DB
############################################################################################################
############################################################################################################
rails plugin new teams_store --full --mountable --skip-bundle \
    --skip-git --skip-test-unit --dummy-path=spec/dummy --skip-gemfile-entry

mv teams_store components/teams_store_db

mkdir -p components/teams_store_db/db/migrate
mkdir -p components/teams_store_db/spec/models/teams_store
mkdir -p components/teams_store_db/spec/support

rm -rf components/teams_store_db/app/assets
rm -rf components/teams_store_db/app/controllers
rm -rf components/teams_store_db/app/helpers
rm -rf components/teams_store_db/app/jobs
rm -rf components/teams_store_db/app/mailers
rm -rf components/teams_store_db/app/views
rm -rf components/teams_store_db/config
rm -rf components/teams_store_db/test
rm -rf components/teams_store_db/spec/dummy/config/initializers/assets.rb

mv components/teams_OLD/db/migrate/* components/teams_store_db/db/migrate

echo '
module TeamsStore
  class Engine < ::Rails::Engine
    isolate_namespace TeamsStore

    initializer :append_migrations do |app|
      unless app.root.to_s.match root.to_s+File::SEPARATOR
        app.config.paths["db/migrate"].concat config.paths["db/migrate"].expanded
      end
    end

    config.generators do |g|
      g.orm             :active_record
      g.template_engine :slim
      g.test_framework  :rspec
    end
  end
end
' > components/teams_store_db/lib/teams_store/engine.rb

echo '
require_relative "../../spec/support/object_creation_methods.rb"
' > components/teams_store_db/lib/teams_store/test_helpers.rb

echo '
require "teams"

module TeamsStore
  require "teams_store/engine"

  module Db
    def self.reset
    end
  end
end
' > components/teams_store_db/lib/teams_store.rb

echo '
module TeamsStore
  class TeamRepository
    def get_all
      TeamRecord.all.map do |team_record|
        team_from_record(team_record)
      end
    end

    def get(id)
      team_record = TeamRecord.find_by_id(id)
      team_from_record(team_record)
    end

    def create(team)
      team_record = TeamRecord.create(name: team.name)
      team_from_record(team_record)
    end

    def update(id, name)
      TeamRecord.find_by_id(id).update(name: name)
    end

    def delete(id)
      TeamRecord.delete(id)
    end

    private

    class TeamRecord < ActiveRecord::Base
      self.table_name = "teams_teams"

      validates :name, presence: true
    end
    private_constant(:TeamRecord)

    def team_from_record(team_record)
      Teams::Team.new(team_record.id, team_record.name)
    end
  end
end
' > components/teams_store_db/app/models/teams_store/team_repository.rb

echo '
require "spec_helper"

RSpec.describe TeamsStore::TeamRepository do
  class TeamRecordTester < ActiveRecord::Base
    self.table_name = "teams_teams"
  end

  describe "create" do
    it "creates a persisted record" do
      team = subject.create(Teams::Team.new(nil, "testTeam"))
      expect(team).to be_a(Teams::Team)
      expect(team.id).to_not eq(nil)
      expect(team.name).to eq("testTeam")

      stored_team = TeamRecordTester.find_by_id(team.id)
      expect(stored_team.id).to eq(team.id)
      expect(stored_team.name).to eq("testTeam")
    end
  end

  describe "update" do
    it "creates a persisted record" do
      team = subject.create(Teams::Team.new(nil, "testTeam"))

      updated_team = subject.update(team.id, "newName")
      expect(updated_team).to eq(true)

      stored_team = TeamRecordTester.find_by_id(team.id)
      expect(stored_team.id).to eq(team.id)
      expect(stored_team.name).to eq("newName")

      updated_team = subject.update(team.id, "")
      expect(updated_team).to eq(false)

      stored_team = TeamRecordTester.find_by_id(team.id)
      expect(stored_team.id).to eq(team.id)
      expect(stored_team.name).to eq("newName")
    end
  end

  describe "delete" do
    it "deletes the persisted record" do
      team = subject.create(Teams::Team.new(nil, "testTeam"))

      updated_team = subject.delete(team.id)
      expect(updated_team).to eq(team.id)

      stored_team = TeamRecordTester.find_by_id(team.id)
      expect(stored_team).to eq(nil)
    end
  end

  describe "get" do
    it "retrieves previously persisted record" do
      team = subject.create(Teams::Team.new(nil, "testTeam"))

      retrieved_team = subject.get(team.id)
      expect(retrieved_team).to be_a(Teams::Team)
      expect(retrieved_team.id).to_not eq(nil)
      expect(retrieved_team.name).to eq("testTeam")
    end
  end

  describe "get_all" do
    it "retrieves all previously persisted record" do
      subject.create(Teams::Team.new(nil, "testTeam1"))
      subject.create(Teams::Team.new(nil, "testTeam2"))

      retrieved_teams = subject.get_all
      expect(retrieved_teams.size).to eq(2)

      expect(retrieved_teams[0]).to be_a(Teams::Team)
      expect(retrieved_teams[0].id).to_not eq(nil)
      expect(retrieved_teams[0].name).to eq("testTeam1")

      expect(retrieved_teams[1]).to be_a(Teams::Team)
      expect(retrieved_teams[1].id).to_not eq(nil)
      expect(retrieved_teams[1].name).to eq("testTeam2")
    end
  end
end
' > components/teams_store_db/spec/models/teams_store/team_repository_spec.rb

echo '
module TeamsStore::ObjectCreationMethods
  def new_team(overrides = {})
    Teams::Team.new(nil, overrides[:name] || "Some name #{counter}")
  end

  def create_team(overrides = {})
    TeamsStore::TeamRepository.new.create(new_team(overrides))
  end

  private

  def counter
    @counter ||= 0
    @counter += 1
  end
end
' > components/teams_store_db/spec/support/object_creation_methods.rb

echo '
ENV["RAILS_ENV"] ||= "test"

require File.expand_path("../dummy/config/environment", __FILE__)

require "rspec/rails"
require "shoulda/matchers"
require "database_cleaner"

Dir[TeamsStore::Engine.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

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

  config.include TeamsStore::ObjectCreationMethods
end
' > components/teams_store_db/spec/spec_helper.rb

echo '
source "https://rubygems.org"

path ".." do
  gem "teams"
end

gemspec
' > components/teams_store_db/Gemfile

echo '
$:.push File.expand_path("../lib", __FILE__)

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "teams_store"
  s.version     = "0.0.1"
  s.authors     = ["Your name"]
  s.email       = ["Your email"]
  s.summary     = "Summary of TeamsStore."
  s.description = "Description of TeamsStore."

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "activerecord", "5.1.4"
  s.add_dependency "teams"

  s.add_development_dependency "rails", "5.1.4"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "shoulda-matchers"
  s.add_development_dependency "database_cleaner"
end
' > components/teams_store_db/teams_store.gemspec

echo '
require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)
require "teams_store"

module Dummy
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
' > components/teams_store_db/spec/dummy/config/application.rb

echo '
#!/bin/bash

exit_code=0

echo "
********************************************************************************
*** Running teams_store DB engine specs
********************************************************************************"

bundle install | grep Installing
bundle exec rake db:create db:migrate
RAILS_ENV=test bundle exec rake db:create
RAILS_ENV=test bundle exec rake db:migrate
bundle exec rspec spec
((exit_code+=$?))

exit $exit_code
' > components/teams_store_db/test.sh

chmod +x components/teams_store_db/test.sh


############################################################################################################
############################################################################################################
### GAMES
############################################################################################################
############################################################################################################

echo '
module Games
  class Game < ActiveRecord::Base
    validates :date, :location, :first_team_id, :second_team_id, :winning_team,
              :first_team_score, :second_team_score, presence: true
  end
end
' > components/games/app/models/games/game.rb

echo 'RSpec.describe Games::Game do
  it { should validate_presence_of(:date) }
  it { should validate_presence_of(:location) }
  it { should validate_presence_of(:first_team_id) }
  it { should validate_presence_of(:second_team_id) }
  it { should validate_presence_of(:winning_team) }
  it { should validate_presence_of(:first_team_score) }
  it { should validate_presence_of(:second_team_score) }
end
' > components/games/spec/models/games/game_spec.rb

echo '
module Games::ObjectCreationMethods
  def new_game(overrides = {})
    defaults = {
        first_team_id: -> { create_team.id },
        second_team_id: -> { create_team.id },
        winning_team: 2,
        first_team_score: 2,
        second_team_score: 3,
        location: "Somewhere",
        date: Date.today
    }

    Games::Game.new { |game| apply(game, defaults, overrides) }
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
end
' > components/games/spec/support/object_creation_methods.rb

############################################################################################################
############################################################################################################
### GAMES_ADMIN
############################################################################################################
############################################################################################################

echo '
RSpec.describe "games admin", :type => :feature do
  before :each do
    @team1 = create_team name: "UofL"
    @team2 = create_team name: "UK"
  end

  it "allows for the management of games" do
    visit "/games_admin/games"

    click_link "New Game"

    fill_in "First team", with: @team1.id
    fill_in "Second team", with: @team2.id
    fill_in "Winning team", with: 1
    fill_in "First team score", with: 3141592
    fill_in "Second team score", with: 1
    fill_in "Location", with: "Home"

    click_on "Create Game"

    expect(page).to have_content "3141592"
    expect(page).to have_content "Game was successfully created"
  end
end
' > components/games_admin/spec/features/games_spec.rb

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
            strong = game.first_team_id
          td = game.second_team_id
        - else
          td = game.first_team_id
          td
            strong = game.second_team_id
        td = link_to "Show", game, class: "button tiny"
        td = link_to "Edit", edit_game_path(game), class: "button tiny"
        td = link_to "Destroy", game, data: {:confirm => "Are you sure?"}, :method => :delete, class: "button tiny alert"

br

= link_to "New Game", new_game_path, class: "button"
' > components/games_admin/app/views/games_admin/games/index.html.slim

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
  = @game.first_team_id
p
  strong Second team:
  = @game.second_team_id
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
' > components/games_admin/app/views/games_admin/games/show.html.slim

echo '
ENV["RAILS_ENV"] ||= "test"

require File.expand_path("../dummy/config/environment", __FILE__)

require "rspec/rails"
require "shoulda/matchers"
require "database_cleaner"
require "capybara/rails"
require "capybara/rspec"

require "rails-controller-testing"
Rails::Controller::Testing.install

Dir[GamesAdmin::Engine.root.join("spec/support/**/*.rb")].each { |f| require f }

require "teams_store/test_helpers"
require "games/test_helpers"

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
    TeamsStore::Db.reset
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  [:controller, :view, :request].each do |type|
    config.include ::Rails::Controller::Testing::TestProcess, :type => type
    config.include ::Rails::Controller::Testing::TemplateAssertions, :type => type
    config.include ::Rails::Controller::Testing::Integration, :type => type
  end

  config.include TeamsStore::ObjectCreationMethods
  config.include Games::ObjectCreationMethods
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
' > components/games_admin/spec/spec_helper.rb

############################################################################################################
############################################################################################################
### TEAMS_ADMIN
############################################################################################################
############################################################################################################

echo '
require_dependency "teams_admin/application_controller"

module TeamsAdmin
  class TeamsController < ApplicationController
    before_action :ensure_dependencies
    before_action :set_team, only: [:show, :edit, :update, :destroy]

    def index
      @teams = @team_repository.get_all
    end

    def new
      @team = Teams::Team.new
    end

    def edit
    end

    def create
      team = Teams::Team.new(team_params[:id], team_params[:name])
      @team = @team_repository.create(team)

      if @team.persisted?
        redirect_to teams_teams_url, notice: "Team was successfully created."
      else
        render :new
      end
    end

    def update
      if @team_repository.update(@team.id, team_params[:name])
        redirect_to teams_teams_url, notice: "Team was successfully updated."
      else
        render :edit
      end
    end

    def destroy
      @team_repository.delete(@team.id)
      redirect_to teams_teams_url, notice: "Team was successfully destroyed."
    end

    private
    def set_team
      @team = @team_repository.get(params[:id])
    end

    def team_params
      params.require(:teams_team).permit(:name)
    end

    def ensure_dependencies
      @team_repository = TeamsStore::TeamRepository.new
    end
  end
end
' > components/teams_admin/app/controllers/teams_admin/teams_controller.rb

echo '
RSpec.describe TeamsAdmin::TeamsController, :type => :controller do
  routes { TeamsAdmin::Engine.routes }

  let(:valid_attributes) { new_team(name: "Our team").as_json }
  let(:invalid_attributes) { new_team(name: "").as_json }
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
      expect(assigns(:team)).to be_a_new Teams::Team
    end

    describe "view" do
      render_views

      it "renders new team form" do
        get :new, params: {}, session: valid_session

        assert_select "form[action=?][method=?]", teams_teams_path, "post" do
          assert_select "input#teams_team_name"
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

        assert_select "form[action=?][method=?]", teams_team_path(team), "post" do
          assert_select "input#teams_team_name"
        end
      end
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Teams::Team" do
        previous_count = TeamsStore::TeamRepository.new.get_all.count
        post :create, params: {:teams_team => valid_attributes}, session: valid_session
        expect(TeamsStore::TeamRepository.new.get_all.count - 1).
            to eq (previous_count)
      end

      it "assigns a newly created team as @team" do
        post :create, params: {:teams_team => valid_attributes}, session: valid_session
        expect(assigns(:team)).to be_a Teams::Team
        expect(assigns(:team)).to be_persisted
      end

      it "redirects to the index" do
        post :create, params: {:teams_team => valid_attributes}, session: valid_session
        expect(response).to redirect_to teams_teams_path
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved team as @team" do
        post :create, params: {:teams_team => invalid_attributes}, session: valid_session
        expect(assigns(:team)).to be_a_new Teams::Team
      end

      it "re-renders the new template" do
        post :create, params: {:teams_team => invalid_attributes}, session: valid_session
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
        existing_team = create_team
        put :update, params: {:id => existing_team.to_param, :teams_team => new_attributes}, session: valid_session
        team = TeamsStore::TeamRepository.new.get(existing_team.id)
        expect(team.name).to eq("new team name")
      end

      it "assigns the requested team as @team" do
        team = create_team
        put :update, params: {:id => team.to_param, :teams_team => valid_attributes}, session: valid_session
        expect(assigns(:team)).to eq team
      end

      it "redirects to the index" do
        team = create_team
        put :update, params: {:id => team.to_param, :teams_team => valid_attributes}, session: valid_session
        expect(response).to redirect_to teams_teams_path
      end
    end

    describe "with invalid params" do
      it "assigns the team as @team" do
        team = create_team
        put :update, params: {:id => team.to_param, :teams_team => invalid_attributes}, session: valid_session
        expect(assigns(:team)).to eq team
      end

      it "re-renders the edit template" do
        team = create_team
        put :update, params: {:id => team.to_param, :teams_team => invalid_attributes}, session: valid_session
        expect(response).to render_template "edit"
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested team" do
      team = create_team
      previous_count = TeamsStore::TeamRepository.new.get_all.count
      delete :destroy, params: {:id => team.to_param}, session: valid_session
      expect(TeamsStore::TeamRepository.new.get_all.count + 1).
          to eq (previous_count)
    end

    it "redirects to the teams list" do
      team = create_team
      delete :destroy, params: {:id => team.to_param}, session: valid_session
      expect(response).to redirect_to teams_teams_url
    end
  end
end
' > components/teams_admin/spec/controllers/teams_admin/teams_controller_spec.rb


echo '
TeamsAdmin::Engine.routes.draw do
  resources :teams, as: "teams_teams"
end
' > components/teams_admin/config/routes.rb

echo '
h1 Editing team

== render "form"

= link_to "Back", teams_teams_path, class: "button"

' > components/teams_admin/app/views/teams_admin/teams/edit.html.slim

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
        td = link_to "Edit", edit_teams_team_path(team), class: "button tiny"
        td = link_to "Destroy", team, data: {:confirm => "Are you sure?"}, :method => :delete, class: "button tiny alert"

br

= link_to "New Team", new_teams_team_path, class: "button"
' > components/teams_admin/app/views/teams_admin/teams/index.html.slim

echo '
h1 New team

== render "form"

= link_to "Back", teams_teams_path, class: "button"
' > components/teams_admin/app/views/teams_admin/teams/new.html.slim

echo '
require "slim-rails"
require "jquery-rails"

require "web_ui"
require "teams_store"

module TeamsAdmin
  require "teams_admin/engine"

  def self.nav_entry
    {name: "Teams", link: -> {::TeamsAdmin::Engine.routes.url_helpers.teams_teams_path}}
  end
end
' > components/teams_admin/lib/teams_admin.rb

echo '
ENV["RAILS_ENV"] ||= "test"

require File.expand_path("../dummy/config/environment", __FILE__)

require "rspec/rails"
require "shoulda/matchers"
require "database_cleaner"
require "capybara/rails"
require "capybara/rspec"

require "rails-controller-testing"
Rails::Controller::Testing.install

Dir[TeamsAdmin::Engine.root.join("spec/support/**/*.rb")].each { |f| require f }

require "teams_store/test_helpers"

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
    TeamsStore::Db.reset
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  [:controller, :view, :request].each do |type|
    config.include ::Rails::Controller::Testing::TestProcess, :type => type
    config.include ::Rails::Controller::Testing::TemplateAssertions, :type => type
    config.include ::Rails::Controller::Testing::Integration, :type => type
  end

  config.include TeamsStore::ObjectCreationMethods
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
' > components/teams_admin/spec/spec_helper.rb

############################################################################################################
############################################################################################################
### PREDICTION_UI
############################################################################################################
############################################################################################################


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
  it "returns a nice prediction text" do
    Named = Struct.new(:name)
    text = prediction_text(Named.new("A"), Named.new("B"), Named.new("C"))
    expect(text).to eq "In the game between A and B the winner will be C"
  end

  it "returns a winner not determined if given no winner" do
    Named = Struct.new(:name)
    text = prediction_text(Named.new("A"), Named.new("B"), nil)
    expect(text).to eq "Winner not determined"
  end
end
' > components/prediction_ui/spec/helpers/predictions_helper_spec.rb

echo '
h1 Prediction

- if message.present?
  .error_message = message

.prediction_text
  = prediction_text(prediction.first_team, prediction.second_team, prediction.winner)

.actions
  = link_to "Try again!", new_prediction_path, class: "button"
' > components/prediction_ui/app/views/prediction_ui/predictions/create.html.slim

echo '
module PredictionUi
  class PredictionsController < ApplicationController
    def new
      @teams = TeamsStore::TeamRepository.new.get_all
    end

    def create
      game_predictor = PredictGame::PredictGame.new(
          TeamsStore::TeamRepository.new.get_all,
          Games::Game.all)
      game_predictor.add_subscriber(PredictionResponse.new(self))
      game_predictor.perform(
          TeamsStore::TeamRepository.new.get(params["first_team"]["id"]),
          TeamsStore::TeamRepository.new.get(params["second_team"]["id"]))
    end

    class PredictionResponse < SimpleDelegator
      def prediction_succeeded(prediction)
        render locals: {prediction: prediction, message: nil}
      end

      def prediction_failed(prediction, error_message)
        render locals: {prediction: prediction, message: error_message}
      end
    end
  end
end
' > components/prediction_ui/app/controllers/prediction_ui/predictions_controller.rb

echo '
RSpec.describe PredictionUi::PredictionsController, :type => :controller do
  routes { PredictionUi::Engine.routes }

  before do
    @team1 = create_team
    @team2 = create_team
  end

  describe "GET new" do
    it "assigns all teams as @teams" do
      get :new, params: {}, flash: {}
      expect(assigns(:teams)).to eq([@team1, @team2])
    end
  end

  describe "POST create" do
    it "renders the prediction when the prediction succeeds"

    it "renders an error when the prediction failed"
  end
end
' > components/prediction_ui/spec/controllers/prediction_ui/predictions_controller_spec.rb

echo '
RSpec.describe "the prediction process", :type => :feature do
  before :each do
    team1 = create_team name: "UofL"
    team2 = create_team name: "UK"

    create_game first_team_id: team1.id, second_team_id: team2.id, winning_team: 1
    create_game first_team_id: team2.id, second_team_id: team1.id, winning_team: 2
    create_game first_team_id: team2.id, second_team_id: team1.id, winning_team: 2
  end

  it "get a new prediction" do
    visit "/prediction_ui/prediction/new"

    click_link "Predictions"

    select "UofL", from: "First team"
    select "UK", from: "Second team"
    click_button "What is it going to be"

    expect(page).to have_content "the winner will be UofL"
  end
end
' > components/prediction_ui/spec/features/predictions_spec.rb

echo '
$:.push File.expand_path("../lib", __FILE__)

# Maintain your gems version:
require "prediction_ui/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "prediction_ui"
  s.version     = PredictionUi::VERSION
  s.authors     = ["Stephan Hagemann"]
  s.email       = ["stephan.hagemann@gmail.com"]
  s.homepage    = ""
  s.summary     = "Summary of PredictionUi."
  s.description = "Description of PredictionUi."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "5.1.4"
  s.add_dependency "slim-rails", "3.1.3"
  s.add_dependency "jquery-rails", "4.3.1"

  s.add_dependency "web_ui"
  s.add_dependency "predictor"
  s.add_dependency "teams_store"
  s.add_dependency "games"
  s.add_dependency "predict_game"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "shoulda-matchers"
  s.add_development_dependency "database_cleaner"
  s.add_development_dependency "capybara"
  s.add_development_dependency "rails-controller-testing"
end
' > components/prediction_ui/prediction_ui.gemspec

echo '
source "https://rubygems.org"

gemspec

path ".." do
  gem "web_ui"
  gem "teams_store"
  gem "games"
  gem "predict_game"
end

gem "trueskill", git: "https://github.com/benjaminleesmith/trueskill", ref: "e404f45af5b3fb86982881ce064a9c764cc6a901"
' > components/prediction_ui/Gemfile

echo '
require "slim-rails"
require "jquery-rails"

require "predictor"
require "web_ui"
require "teams_store"
require "games"
require "predict_game"

module PredictionUi
  require "prediction_ui/engine"

  def self.nav_entry
    {name: "Predictions", link: -> {::PredictionUi::Engine.routes.url_helpers.new_prediction_path}}
  end
end
' > components/prediction_ui/lib/prediction_ui.rb

echo '
ENV["RAILS_ENV"] ||= "test"

require File.expand_path("../dummy/config/environment", __FILE__)

require "rspec/rails"
require "shoulda/matchers"
require "database_cleaner"
require "capybara/rails"
require "capybara/rspec"

require "rails-controller-testing"
Rails::Controller::Testing.install

Dir[PredictionUi::Engine.root.join("spec/support/**/*.rb")].each { |f| require f }

require "games/test_helpers"
require "teams_store/test_helpers"

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
    TeamsStore::Db.reset
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  [:controller, :view, :request].each do |type|
    config.include ::Rails::Controller::Testing::TestProcess, :type => type
    config.include ::Rails::Controller::Testing::TemplateAssertions, :type => type
    config.include ::Rails::Controller::Testing::Integration, :type => type
  end

  config.include Games::ObjectCreationMethods
  config.include TeamsStore::ObjectCreationMethods
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
' > components/prediction_ui/spec/spec_helper.rb

############################################################################################################
############################################################################################################
### REST
############################################################################################################
############################################################################################################


grep -rl "teams/test_helpers" . | \
   xargs sed -i 's;teams/test_helpers;teams_store/test_helpers;g'
grep -rl "Teams::ObjectCreationMethods" . | \
   xargs sed -i 's;Teams::ObjectCreationMethods;TeamsStore::ObjectCreationMethods;g'

grep -rl "teams" components/games/games.gemspec | xargs sed -i 's;teams;teams_store;g'
grep -rl "teams" components/games/Gemfile | xargs sed -i 's;teams;teams_store;g'

grep -rl "teams" components/games_admin/games_admin.gemspec | xargs sed -i 's;teams;teams_store;g'
grep -rl "teams" components/games_admin/Gemfile | xargs sed -i 's;teams;teams_store;g'
grep -rl "teams" components/games_admin/lib/games_admin.rb | xargs sed -i 's;teams;teams_store;g'

grep -rl "teams" components/teams_admin/teams_admin.gemspec | xargs sed -i 's;"teams";"teams_store";g'
grep -rl "teams" components/teams_admin/Gemfile | xargs sed -i 's;"teams";"teams_store";g'
grep -rl "teams" components/teams_admin/lib/teams_admin.rb | xargs sed -i 's;"teams";"teams_store";g'

echo '
RSpec.describe "the app", :type => :feature do
  it "hooks up to /" do
    visit "/"
    within "main h1" do
      expect(page).to have_content "Sportsball"
    end
  end

  it "has teams" do
    visit "/"
    click_link "Teams"
    within "main h1" do
      expect(page).to have_content "Teams"
    end
  end

  it "has games" do
    visit "/"
    click_link "Games"
    within "main h1" do
      expect(page).to have_content "Games"
    end
  end

  it "can predict" do
    TeamsStore::TeamRepository.new.create Teams::Team.new(nil, "UofL")
    TeamsStore::TeamRepository.new.create Teams::Team.new(nil, "UK")

    visit "/"
    click_link "Predictions"
    click_button "What is it going to be"
  end
end
' > spec/features/app_spec.rb

echo '#!/bin/bash

result=0

echo "### TESTING EVERYTHING WITH TEAMS DB"

rm components/teams_store
ln -s teams_store_db components/teams_store

for test_script in $(find . -name test.sh | sort); do
  pushd `dirname $test_script` > /dev/null
  ./test.sh
  ((result+=$?))
  popd > /dev/null
done

echo "### TESTING EVERYTHING WITH TEAMS IN MEM"

rm components/teams_store
ln -s teams_store_mem components/teams_store

for test_script in $(find . -name test.sh | sort); do
  pushd `dirname $test_script` > /dev/null
  ./test.sh
  ((result+=$?))
  popd > /dev/null
done

if [ $result -eq 0 ]; then
	echo "SUCCESS"
else
	echo "FAILURE"
fi

exit $result
' > build.sh

#cd components/publisher/ && ./test.sh ; cd ../..
#cd components/predictor/ && ./test.sh ; cd ../..
#cd components/welcome_ui/ && ./test.sh ; cd ../..
#cd components/teams_store_db/ && ./test.sh ; cd ../..
#cd components/teams_store_mem/ && ./test.sh ; cd ../..
###cd components/web_ui/ && ./test.sh ; cd ../..
#cd components/teams/ && ./test.sh ; cd ../..
#cd components/games/ && ./test.sh ; cd ../..
#cd components/predict_game/ && ./test.sh ; cd ../..
#cd components/teams_admin/ && ./test.sh ; cd ../..
#cd components/games_admin/ && ./test.sh ; cd ../..
#cd components/prediction_ui/ && ./test.sh ; cd ../..

rm -rf components/teams_OLD


cd ..

tar -zcvf $CHAPTER-`date +%Y%m%d%H%M%S`.tgz sportsball
