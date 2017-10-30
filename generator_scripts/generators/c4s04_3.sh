#!/bin/bash

set -v
set -x
set -e

gem install --source http://geminabox:9292 bundler -v 1.16.1 --no-ri --no-rdoc

tar -xzf code_input/$PREV_CHAPTER*.tgz -C code_output


cd code_output/sportsball

BUNDLE_GEMFILE=`pwd`/Gemfile bundle

rails plugin new components/prediction_ui --full --mountable --skip-bundle \
    --skip-git --skip-test-unit --skip-gemfile-entry \
    --dummy-path=spec/dummy

sed -i 's/~> //g' components/prediction_ui/prediction_ui.gemspec

mkdir -p components/prediction_ui/app/views/prediction_ui
mkdir -p components/prediction_ui/spec/controllers/prediction_ui
mkdir -p components/prediction_ui/spec/features
mkdir -p components/prediction_ui/spec/helpers

mv components/app_component/app/controllers/app_component/predictions_controller.rb \
   components/prediction_ui/app/controllers/prediction_ui/
mv components/app_component/app/views/app_component/predictions\
   components/prediction_ui/app/views/prediction_ui/predictions
mv components/app_component/app/helpers/app_component/predictions_helper.rb\
   components/prediction_ui/app/helpers/prediction_ui/

mv components/app_component/spec/controllers/app_component/predictions_controller_spec.rb\
   components/prediction_ui/spec/controllers/prediction_ui/
mv components/app_component/spec/features/predictions_spec.rb\
   components/prediction_ui/spec/features
mv components/app_component/spec/helpers/app_component/predictions_helper_spec.rb\
   components/prediction_ui/spec/helpers

grep -rl "module AppComponent" components/prediction_ui/ | \
   xargs sed -i 's/module AppComponent/module PredictionUi/g'
grep -rl "AppComponent::PredictionsController" components/prediction_ui/ | \
   xargs sed -i 's/AppComponent::PredictionsController/PredictionUi::PredictionsController/g'
grep -rl "AppComponent::PredictionsHelper" components/prediction_ui/ | \
   xargs sed -i 's/AppComponent::PredictionsHelper/PredictionUi::PredictionsHelper/g'
grep -rl "AppComponent::Engine" components/prediction_ui/ | \
   xargs sed -i 's/AppComponent::Engine/PredictionUi::Engine/g'
grep -rl "app_component/" components/prediction_ui/ | \
   xargs sed -i 's;app_component/;prediction_ui/;g'

rm -rf components/app_component/app/helpers
rm -rf components/app_component/spec/helpers

rm -rf components/prediction_ui/app/assets
rm -rf components/prediction_ui/app/jobs
rm -rf components/prediction_ui/app/mailers
rm -rf components/prediction_ui/app/models
rm -rf components/prediction_ui/test
rm -rf components/prediction_ui/lib/tasks
rm -rf components/prediction_ui/MIT-LICENSE

sed -i '/s\.homepage/d' components/prediction_ui/prediction_ui.gemspec
sed -i '/s\.description/d' components/prediction_ui/prediction_ui.gemspec
sed -i '/s\.license/d' components/prediction_ui/prediction_ui.gemspec
sed -i 's/TODO: //g' components/prediction_ui/prediction_ui.gemspec

sed -i 's/"MIT-LICENSE", //g' components/prediction_ui/prediction_ui.gemspec


sed -i 's/s\.authors\( *\)= \[".*"\]/s\.authors\1= \["Stephan Hagemann"\]/g' components/prediction_ui/prediction_ui.gemspec
sed -i 's/s\.emails\( *\)= \[".*"\]/s\.emails\1= \["stephan.hagemann@gmail.com"\]/g' components/prediction_ui/prediction_ui.gemspec


sed -i '/s.add_dependency "rails", ".*"/a\  s.add_dependency "slim-rails", "3.1.3"\n  s.add_dependency "jquery-rails", "4.3.1"\n\n  s.add_dependency "app_component"\n  s.add_dependency "predictor"\n\n  s.add_development_dependency "rspec-rails"\n  s.add_development_dependency "shoulda-matchers"\n  s.add_development_dependency "database_cleaner"\n  s.add_development_dependency "capybara"\n  s.add_development_dependency "rails-controller-testing"\n' components/prediction_ui/prediction_ui.gemspec

echo '
source "http://geminabox:9292"

gemspec

path ".." do
  gem "app_component"
  gem "predictor"
end

gem "trueskill", git: "https://github.com/benjaminleesmith/trueskill", ref: "e404f45af5b3fb86982881ce064a9c764cc6a901"
' > components/prediction_ui/Gemfile



echo '
module PredictionUi
  class Engine < ::Rails::Engine
    isolate_namespace PredictionUi

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
' > components/prediction_ui/lib/prediction_ui/engine.rb





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
' > components/prediction_ui/spec/spec_helper.rb


echo '
#!/bin/bash

exit_code=0

echo "
********************************************************************************
*** Running prediction ui engine specs
********************************************************************************"

export BUNDLE_GEMFILE=`pwd`/Gemfile
bundle install | grep Installing
bundle exec rake db:create db:migrate
RAILS_ENV=test bundle exec rake db:create
RAILS_ENV=test bundle exec rake db:migrate
bundle exec rspec spec
((exit_code+=$?))

exit $exit_code

' > components/prediction_ui/test.sh

chmod +x components/prediction_ui/test.sh


echo '
--color
--require spec_helper
' > components/prediction_ui/.rspec

echo '
PredictionUi::Engine.routes.draw do
  resource :prediction, only: [:new, :create]
end
' > components/prediction_ui/config/routes.rb

echo '
Rails.application.config.main_nav =
    [
        PredictionUi.nav_entry
    ]
' > components/prediction_ui/spec/dummy/config/initializers/global_navigation.rb



sed -i '/  resource :prediction, only: \[:new, :create\]/d' components/app_component/config/routes.rb


echo '
RSpec.describe "the prediction process", :type => :feature do
  before :each do
    team1 = create_team name: "UofL"
    team2 = create_team name: "UK"

    create_game first_team: team1, second_team: team2, winning_team: 1
    create_game first_team: team2, second_team: team1, winning_team: 2
    create_game first_team: team2, second_team: team1, winning_team: 2
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




sed -i '/path "components" do/a\  gem "prediction_ui"' Gemfile
sed -i 's/mount AppComponent::Engine, at: "\/app_component"/mount PredictionUi::Engine, at: "\/prediction_ui"/' config/routes.rb


rm -rf components/prediction_ui/app/views/layouts

echo '
module PredictionUi
  class ApplicationController < ActionController::Base
    layout "app_component/application"
  end
end
' > components/prediction_ui/app/controllers/prediction_ui/application_controller.rb

echo '
require "slim-rails"
require "jquery-rails"

require "predictor"
require "app_component"

module PredictionUi
  require "prediction_ui/engine"

  def self.nav_entry
    {name: "Predictions", link: -> {::PredictionUi::Engine.routes.url_helpers.new_prediction_path}}
  end
end
' > components/prediction_ui/lib/prediction_ui.rb

echo '
RSpec.describe "nav entry" do
  it "points at the list of games" do
    entry = PredictionUi.nav_entry
    expect(entry[:name]).to eq "Predictions"
    expect(entry[:link].call).to eq "/prediction_ui/prediction/new"
  end
end
' > components/prediction_ui/spec/nav_entry_spec.rb

echo '
Rails.application.config.main_nav =
    [
        PredictionUi.nav_entry
    ]
' > components/prediction_ui/spec/dummy/config/initializers/global_navigation.rb


sed -i '/^.*li =link_to.*$/d' components/app_component/app/views/layouts/app_component/application.html.slim

sed -i '/          ul\.left/a\            - Rails\.application\.config\.main_nav\.each do |nav_entry|\n              li =link_to nav_entry\[:name\], nav_entry\[:link\]\.call' components/app_component/app/views/layouts/app_component/application.html.slim

echo '
Rails.application.config.main_nav =
    [
        TeamsAdmin.nav_entry,
        GamesAdmin.nav_entry,
        PredictionUi.nav_entry
    ]
' > config/initializers/global_navigation.rb

sed -i '/  require "predictor"/d' components/app_component/lib/app_component.rb

sed -i '/gem "trueskill", git: "https:\/\/github\.com\/benjaminleesmith\/trueskill", ref: "e404f45af5b3fb86982881ce064a9c764cc6a901"/d' components/app_component/Gemfile

sed -i '/path "\.\." do/d' components/app_component/Gemfile
sed -i '/  gem "predictor"/d' components/app_component/Gemfile
sed -i '/end/d' components/app_component/Gemfile

sed -i '/  s.add_dependency "trueskill"/d' components/app_component/app_component.gemspec

sed -i '/require "saulabs\/trueskill"/d' components/app_component/lib/app_component.rb


cd components/prediction_ui
BUNDLE_GEMFILE=`pwd`/Gemfile bundle package
cd ../..


cd ..

tar -zcvf $CHAPTER-`date +%Y%m%d%H%M%S`.tgz sportsball

