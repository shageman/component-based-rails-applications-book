#!/bin/bash

set -v
set -x
set -e

gem install --source http://geminabox:9292 bundler -v 1.16.1 --no-ri --no-rdoc

tar -xzf code_input/$PREV_CHAPTER*.tgz -C code_output


cd code_output/sportsball

BUNDLE_GEMFILE=`pwd`/Gemfile bundle

rails plugin new components/teams \
    --skip-yarn --skip-git  --skip-action-mailer --skip-action-cable \
    --skip-puma --skip-sprockets --skip-spring --skip-listen \
    --skip-coffee --skip-javascript --skip-turbolinks \
    --skip-test --dummy-path=spec/dummy --full --mountable \
    --skip-gemfile-entry \
    --skip-bundle

sed -i 's/~> //g' components/teams/teams.gemspec

rm -rf components/teams/app/assets
rm -rf components/teams/app/helpers
rm -rf components/teams/app/jobs
rm -rf components/teams/app/mailers
rm -rf components/teams/app/controllers
rm -rf components/teams/app/views
rm -rf components/teams/test
rm -rf components/teams/lib/tasks
rm -rf components/teams/MIT-LICENSE
rm -rf components/teams/README.md

mkdir -p components/teams/app/models/teams
mkdir -p components/teams/spec/models/teams
mkdir -p components/teams/spec/support


mv components/app_component/app/models/app_component/team.rb \
   components/teams/app/models/teams/

mv components/app_component/spec/models/app_component/team_spec.rb\
   components/teams/spec/models/teams/

grep -rl "AppComponent" components/teams/ | \
   xargs sed -i 's/module AppComponent/module Teams/g'


sed -i 's/ Team\./ Teams::Team\./g' components/teams/app/models/teams/team.rb

grep -rl "AppComponent::Team" components/teams/ | \
   xargs sed -i 's/AppComponent::Team/Teams::Team/g'


mkdir -p components/teams/db/migrate

mv components/app_component/db/migrate/*_create_app_component_teams.rb\
   components/teams/db/migrate



sed -i '/s\.homepage/d' components/teams/teams.gemspec
sed -i '/s\.description/d' components/teams/teams.gemspec
sed -i '/s\.license/d' components/teams/teams.gemspec
sed -i 's/TODO: //g' components/teams/teams.gemspec

sed -i 's/"MIT-LICENSE", //g' components/teams/teams.gemspec

sed -i 's/s\.authors\( *\)= \[".*"\]/s\.authors\1= \["Stephan Hagemann"\]/g' components/teams/teams.gemspec
sed -i 's/s\.emails\( *\)= \[".*"\]/s\.emails\1= \["stephan.hagemann@gmail.com"\]/g' components/teams/teams.gemspec

sed -i 's/ s\.add_dependency "rails", "\(.*\)"/ s\.add_dependency "activerecord", "\1"\n  s\.add_development_dependency "rspec-rails"\n  s\.add_development_dependency "shoulda-matchers"\n  s\.add_development_dependency "database_cleaner"/' components/teams/teams.gemspec

sed -i 's/'"'"'/"/g' components/teams/Gemfile
sed -i 's/source "https:\/\/rubygems\.org/source "http:\/\/geminabox:9292\//g' components/teams/Gemfile

sed -i 's/\(.*action_controller.*\)/#\1/g' components/teams/spec/dummy/config/application.rb
sed -i 's/\(.*action_view.*\)/#\1/g' components/teams/spec/dummy/config/application.rb
sed -i 's/\(.*action_mailer.*\)/#\1/g' components/teams/spec/dummy/config/application.rb
sed -i 's/\(.*active_job.*\)/#\1/g' components/teams/spec/dummy/config/application.rb
sed -i 's/\(.*action_cable.*\)/#\1/g' components/teams/spec/dummy/config/application.rb
sed -i 's/\(.*test_unit.*\)/#\1/g' components/teams/spec/dummy/config/application.rb
sed -i 's/\(.*sprockets.*\)/#\1/g' components/teams/spec/dummy/config/application.rb

echo '
source "http://geminabox:9292"

gemspec
' > components/teams/Gemfile

echo '
module Teams
  class Engine < ::Rails::Engine
    isolate_namespace Teams

    initializer :append_migrations do |app|
      unless app.root.to_s.match root.to_s+File::SEPARATOR
        app.config.paths["db/migrate"].concat config.paths["db/migrate"].expanded
      end
    end

    config.generators do |g|
      g.orm             :active_record
      g.test_framework  :rspec
    end
  end
end
' > components/teams/lib/teams/engine.rb

echo '
ENV["RAILS_ENV"] ||= "test"

require File.expand_path("../dummy/config/environment", __FILE__)

require "rspec/rails"
require "shoulda/matchers"
require "database_cleaner"
require "ostruct"

Dir[Teams::Engine.root.join("spec/support/**/*.rb")].each { |f| require f }

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

  config.include Teams::ObjectCreationMethods
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
' > components/teams/spec/spec_helper.rb

echo '
--color
--require spec_helper
' > components/teams/.rspec

cd components/teams
BUNDLE_GEMFILE=`pwd`/Gemfile bundle
BUNDLE_GEMFILE=`pwd`/Gemfile bundle exec rails g migration MoveTeamFromAppComponentToTeams
cd ../..

echo '
class MoveTeamFromAppComponentToTeams < ActiveRecord::Migration[5.0]
  def change
    rename_table :app_component_teams, :teams_teams
  end
end
' > `find . -iname '*move_team_from_app_component_to_teams.rb'`

echo '
#!/bin/bash

exit_code=0

echo "
********************************************************************************
*** Running teams engine specs
********************************************************************************"

export BUNDLE_GEMFILE=`pwd`/Gemfile
bundle install | grep Installing
bundle exec rake db:create db:migrate
RAILS_ENV=test bundle exec rake db:create
RAILS_ENV=test bundle exec rake db:migrate
bundle exec rspec spec
((exit_code+=$?))

exit $exit_code

' > components/teams/test.sh

chmod +x components/teams/test.sh


echo '
require_relative "../../spec/support/object_creation_methods.rb"

' > components/teams/lib/teams/test_helpers.rb

echo '
module Teams::ObjectCreationMethods
  def new_team(overrides = {})
    defaults = {
        name: "Some name #{counter}"
    }
    AppComponent::Team.new { |team| apply(team, defaults, overrides) }
  end

  def create_team(overrides = {})
    new_team(overrides).tap(&:save!)
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
' > components/teams/spec/support/object_creation_methods.rb


#APPCOMPONENT

echo '
module AppComponent::ObjectCreationMethods
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
module AppComponent
  class Game < ApplicationRecord
    validates :date, :location, :first_team, :second_team, :winning_team,
              :first_team_score, :second_team_score, presence: true
    belongs_to :first_team, class_name: "::Teams::Team"
    belongs_to :second_team, class_name: "::Teams::Team"
  end
end
' > components/app_component/app/models/app_component/game.rb

sed -i '/module AppComponent/a\  require "teams"' components/app_component/lib/app_component.rb
sed -i '/s.add_dependency "rails".*/a\  s\.add_dependency "teams"' components/app_component/app_component.gemspec
sed -i '/gemspec/a\path "\.\." do\n  gem "teams"\nend' components/app_component/Gemfile
sed -i '/Dir\[AppComponent::Engine/a\\nrequire "teams\/test_helpers"\n' components/app_component/spec/spec_helper.rb
sed -i '/config\.include AppComponent::ObjectCreationMethods/a\config\.include Teams::ObjectCreationMethods' components/app_component/spec/spec_helper.rb


grep -rl "AppComponent::Team" . | \
   xargs sed -i 's/AppComponent::Team/Teams::Team/g'



sed -i '/path "\.\." do/a\  gem "teams"' components/prediction_ui/Gemfile
sed -i '/s.add_dependency "rails".*/a\  s\.add_dependency "teams"' components/prediction_ui/prediction_ui.gemspec
sed -i '/require "app_component\/test_helpers"/a\require "teams\/test_helpers"' components/prediction_ui/spec/spec_helper.rb
sed -i '/config\.include AppComponent::ObjectCreationMethods/a\config\.include Teams::ObjectCreationMethods' components/prediction_ui/spec/spec_helper.rb
sed -i '/module PredictionUi/a\  require "teams"' components/app_component/lib/app_component.rb



sed -i '/path "\.\." do/a\  gem "teams"' components/games_admin/Gemfile
sed -i '/s.add_dependency "rails".*/a\  s\.add_dependency "teams"' components/games_admin/games_admin.gemspec
sed -i '/require "app_component\/test_helpers"/a\require "teams\/test_helpers"' components/games_admin/spec/spec_helper.rb
sed -i '/config\.include AppComponent::ObjectCreationMethods/a\config\.include Teams::ObjectCreationMethods' components/games_admin/spec/spec_helper.rb
sed -i '/module GamesAdmin/a\  require "teams"' components/games_admin/lib/games_admin.rb



sed -i '/path "\.\." do/a\  gem "teams"' components/teams_admin/Gemfile
sed -i '/s.add_dependency "rails".*/a\  s\.add_dependency "teams"' components/teams_admin/teams_admin.gemspec
sed -i 's/require "app_component\/test_helpers"/require "teams\/test_helpers"/' components/teams_admin/spec/spec_helper.rb
sed -i 's/config\.include AppComponent::ObjectCreationMethods/config\.include Teams::ObjectCreationMethods/' components/teams_admin/spec/spec_helper.rb
sed -i '/module TeamsAdmin/a\  require "teams"' components/teams_admin/lib/teams_admin.rb


cd components/teams
cat Gemfile
cat teams.gemspec
BUNDLE_GEMFILE=`pwd`/Gemfile bundle package
cd ../..


cd ..

tar -zcvf $CHAPTER-`date +%Y%m%d%H%M%S`.tgz sportsball

