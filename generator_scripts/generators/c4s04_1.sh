#!/bin/bash

set -v
set -x
set -e

gem install --source http://geminabox:9292 bundler -v 1.16.1 --no-ri --no-rdoc

tar -xzf code_input/$PREV_CHAPTER*.tgz -C code_output


cd code_output/sportsball

BUNDLE_GEMFILE=`pwd`/Gemfile bundle

rails plugin new components/games_admin --full --mountable --skip-bundle \
    --skip-git --skip-test-unit --skip-gemfile-entry \
    --dummy-path=spec/dummy

sed -i 's/~> //g' components/games_admin/games_admin.gemspec

mkdir -p components/games_admin/app/views/games_admin
mkdir -p components/games_admin/spec/controllers/games_admin
mkdir -p components/games_admin/spec/features

mv components/app_component/app/controllers/app_component/games_controller.rb \
   components/games_admin/app/controllers/games_admin/
mv components/app_component/app/views/app_component/games\
   components/games_admin/app/views/games_admin/games

mv components/app_component/spec/controllers/app_component/games_controller_spec.rb\
   components/games_admin/spec/controllers/games_admin/
mv components/app_component/spec/features/games_spec.rb\
   components/games_admin/spec/features

sed -i 's/ Game\./ AppComponent::Game\./g' components/games_admin/app/controllers/games_admin/games_controller.rb

grep -rl "module AppComponent" components/games_admin/ | \
   xargs sed -i 's/module AppComponent/module GamesAdmin/g'
grep -rl "AppComponent::GamesController" components/games_admin/ | \
   xargs sed -i 's/AppComponent::GamesController/GamesAdmin::GamesController/g'
grep -rl "AppComponent::Engine" components/games_admin/ | \
   xargs sed -i 's/AppComponent::Engine/GamesAdmin::Engine/g'
grep -rl "app_component/" components/games_admin/ | \
   xargs sed -i 's;app_component/;games_admin/;g'
#grep -rl "app_component\." components/games_admin/ | \
#   xargs sed -i 's;app_component\.;games_admin\.;g'

rm -rf components/games_admin/app/assets
rm -rf components/games_admin/app/helpers
rm -rf components/games_admin/app/jobs
rm -rf components/games_admin/app/mailers
rm -rf components/games_admin/app/models
rm -rf components/games_admin/test
rm -rf components/games_admin/lib/tasks
rm -rf components/games_admin/MIT-LICENSE

sed -i '/s\.homepage/d' components/games_admin/games_admin.gemspec
sed -i '/s\.description/d' components/games_admin/games_admin.gemspec
sed -i '/s\.license/d' components/games_admin/games_admin.gemspec
sed -i 's/TODO: //g' components/games_admin/games_admin.gemspec

sed -i 's/"MIT-LICENSE", //g' components/games_admin/games_admin.gemspec


sed -i 's/s\.authors\( *\)= \[".*"\]/s\.authors\1= \["Stephan Hagemann"\]/g' components/games_admin/games_admin.gemspec
sed -i 's/s\.emails\( *\)= \[".*"\]/s\.emails\1= \["stephan.hagemann@gmail.com"\]/g' components/games_admin/games_admin.gemspec


sed -i '/s.add_dependency "rails", ".*"/a\  s.add_dependency "slim-rails", "3.1.3"\n  s.add_dependency "jquery-rails", "4.3.1"\n\n  s.add_dependency "app_component"\n\n  s.add_development_dependency "rspec-rails"\n  s.add_development_dependency "shoulda-matchers"\n  s.add_development_dependency "database_cleaner"\n  s.add_development_dependency "capybara"\n  s.add_development_dependency "rails-controller-testing"\n' components/games_admin/games_admin.gemspec

echo '
source "http://geminabox:9292"

gemspec

path ".." do
  gem "app_component"
end

gem "trueskill", git: "https://github.com/benjaminleesmith/trueskill", ref: "e404f45af5b3fb86982881ce064a9c764cc6a901"
' > components/games_admin/Gemfile


echo '
module GamesAdmin
  class Engine < ::Rails::Engine
    isolate_namespace GamesAdmin

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
' > components/games_admin/lib/games_admin/engine.rb

echo '
require "games_admin/engine"

module GamesAdmin
end
' > components/games_admin/lib/games_admin.rb





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

require "app_component/test_helpers"

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

  config.include AppComponent::ObjectCreationMethods
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
' > components/games_admin/spec/spec_helper.rb


echo '
#!/bin/bash

exit_code=0

echo "
********************************************************************************
*** Running games admin engine specs
********************************************************************************"

export BUNDLE_GEMFILE=`pwd`/Gemfile
bundle install | grep Installing
bundle exec rake db:create db:migrate
RAILS_ENV=test bundle exec rake db:create
RAILS_ENV=test bundle exec rake db:migrate
bundle exec rspec spec
((exit_code+=$?))

exit $exit_code

' > components/games_admin/test.sh

chmod +x components/games_admin/test.sh

echo '
require_relative "../../spec/support/object_creation_methods.rb"

' > components/app_component/lib/app_component/test_helpers.rb

echo '
module AppComponent::ObjectCreationMethods
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
end
' > components/app_component/spec/support/object_creation_methods.rb


echo '
--color
--require spec_helper
' > components/games_admin/.rspec

echo '
GamesAdmin::Engine.routes.draw do
  resources :games
end
' > components/games_admin/config/routes.rb



sed -i '/resources :games/d' components/app_component/config/routes.rb


echo '
require "spec_helper"

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
    fill_in "First team score", with: 2
    fill_in "Second team score", with: 1
    fill_in "Location", with: "Home"

    click_on "Create Game"

    expect(page).to have_content "UofL"
  end
end
' > components/games_admin/spec/features/games_spec.rb

echo '
require "slim-rails"
require "jquery-rails"

require "app_component"

module GamesAdmin
  require "games_admin/engine"

  def self.nav_entry
    {name: "Games", link: -> {::GamesAdmin::Engine.routes.url_helpers.games_path}}
  end
end
' > components/games_admin/lib/games_admin.rb

echo '
require "spec_helper"

RSpec.describe "nav entry" do
  it "points at the list of games" do
    entry = GamesAdmin.nav_entry
    expect(entry[:name]).to eq "Games"
    expect(entry[:link].call).to eq "/games_admin/games"
  end
end
' > components/games_admin/spec/nav_entry_spec.rb

echo '
Rails.application.config.main_nav =
    [
        GamesAdmin.nav_entry
    ]
' > components/games_admin/spec/dummy/config/initializers/global_navigation.rb

sed -i '/path "components" do/a\  gem "games_admin"' Gemfile
sed -i 's/  mount AppComponent::Engine, at: "\/"/  mount AppComponent::Engine, at: "\/app_component"/' config/routes.rb
sed -i '/mount AppComponent/a\  mount GamesAdmin::Engine, at: "\/games_admin"\n  root to: "app_component/welcome#show"' config/routes.rb

rm -rf components/games_admin/app/views/layouts

echo '
module GamesAdmin
  class ApplicationController < ActionController::Base
    layout "app_component/application"
  end
end
' > components/games_admin/app/controllers/games_admin/application_controller.rb

sed -i 's/link_to root_path do/link_to "\/" do/g' components/app_component/app/views/layouts/app_component/application.html.slim

sed -i 's/link_to "Teams",.*/link_to "Teams", "\/app_component\/teams"/g' components/app_component/app/views/layouts/app_component/application.html.slim
sed -i 's/link_to "Games",.*/link_to "Games", "\/games_admin\/games"/g' components/app_component/app/views/layouts/app_component/application.html.slim
sed -i 's/link_to "Predictions",.*/link_to "Predictions", "\/app_component\/prediction\/new"/g' components/app_component/app/views/layouts/app_component/application.html.slim

sed -i 's/config\.include ObjectCreationMethods/config\.include AppComponent::ObjectCreationMethods/g' components/app_component/spec/spec_helper.rb


cd components/games_admin
BUNDLE_GEMFILE=`pwd`/Gemfile bundle package
cd ../..


cd ..

tar -zcvf $CHAPTER-`date +%Y%m%d%H%M%S`.tgz sportsball

