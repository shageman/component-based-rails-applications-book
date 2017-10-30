#!/bin/bash

set -v
set -x
set -e

gem install --source http://geminabox:9292 bundler -v 1.16.1 --no-ri --no-rdoc

tar -xzf code_input/$PREV_CHAPTER*.tgz -C code_output


cd code_output/sportsball

BUNDLE_GEMFILE=`pwd`/Gemfile bundle

rails plugin new components/games \
    --skip-yarn --skip-git  --skip-action-mailer --skip-action-cable \
    --skip-puma --skip-sprockets --skip-spring --skip-listen \
    --skip-coffee --skip-javascript --skip-turbolinks \
    --skip-test --dummy-path=spec/dummy --full --mountable \
    --skip-gemfile-entry \
    --skip-bundle

sed -i 's/~> //g' components/games/games.gemspec

rm -rf components/games/app/assets
rm -rf components/games/app/helpers
rm -rf components/games/app/jobs
rm -rf components/games/app/mailers
rm -rf components/games/app/controllers
rm -rf components/games/app/views
rm -rf components/games/test
rm -rf components/games/lib/tasks
rm -rf components/games/MIT-LICENSE
rm -rf components/games/README.md

mkdir -p components/games/spec/models/games
mkdir -p components/games/spec/support
mkdir -p components/games/db/migrate

mv components/app_component/app/models/app_component/game.rb \
   components/games/app/models/games/

mv components/app_component/spec/models/app_component/game_spec.rb\
   components/games/spec/models/games/

mv components/app_component/db/migrate/*_create_app_component_games.rb\
   components/games/db/migrate

sed -i 's/ Game\./ Games::Game\./g' components/games/app/models/games/game.rb

grep -rl "AppComponent" components/games/ | \
   xargs sed -i 's/module AppComponent/module Games/g'
grep -rl "AppComponent::Game" components/games/ | \
   xargs sed -i 's/AppComponent::Game/Games::Game/g'


sed -i '/s\.homepage/d' components/games/games.gemspec
sed -i '/s\.description/d' components/games/games.gemspec
sed -i '/s\.license/d' components/games/games.gemspec
sed -i 's/TODO: //g' components/games/games.gemspec

sed -i 's/"MIT-LICENSE", //g' components/games/games.gemspec

sed -i 's/s\.authors\( *\)= \[".*"\]/s\.authors\1= \["Stephan Hagemann"\]/g' components/games/games.gemspec
sed -i 's/s\.emails\( *\)= \[".*"\]/s\.emails\1= \["stephan.hagemann@gmail.com"\]/g' components/games/games.gemspec

sed -i 's/s.add_dependency "rails", "\(.*\)"/  s\.add_dependency "activerecord", "\1"\n\n  s\.add_dependency "teams"\n\n  s\.add_development_dependency "rspec-rails"\n  s\.add_development_dependency "shoulda-matchers"\n  s\.add_development_dependency "database_cleaner"/' components/games/games.gemspec

sed -i 's/'"'"'/"/g' components/games/Gemfile
sed -i 's/source "https:\/\/rubygems\.org/source "http:\/\/geminabox:9292\//g' components/games/Gemfile

sed -i 's/\(.*action_controller.*\)/#\1/g' components/games/spec/dummy/config/application.rb
sed -i 's/\(.*action_view.*\)/#\1/g' components/games/spec/dummy/config/application.rb
sed -i 's/\(.*action_mailer.*\)/#\1/g' components/games/spec/dummy/config/application.rb
sed -i 's/\(.*active_job.*\)/#\1/g' components/games/spec/dummy/config/application.rb
sed -i 's/\(.*action_cable.*\)/#\1/g' components/games/spec/dummy/config/application.rb
sed -i 's/\(.*test_unit.*\)/#\1/g' components/games/spec/dummy/config/application.rb
sed -i 's/\(.*sprockets.*\)/#\1/g' components/games/spec/dummy/config/application.rb

#
#echo 'Rails.application.configure do
#  config.cache_classes = false
#  config.eager_load = false
#end ' > components/games/spec/dummy/config/environments/development.rb
#
#echo 'Rails.application.configure do
#  config.cache_classes = true
#  config.eager_load = false
#end ' > components/games/spec/dummy/config/environments/test.rb
#
#echo 'Rails.application.configure do
#  config.cache_classes = true
#  config.eager_load = true
#end ' > components/games/spec/dummy/config/environments/production.rb

echo '
source "http://geminabox:9292"

gemspec

path ".." do
  gem "teams"
end
' > components/games/Gemfile

echo '
module Games
  class Engine < ::Rails::Engine
    isolate_namespace Games

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
' > components/games/lib/games/engine.rb

echo '
ENV["RAILS_ENV"] ||= "test"

require File.expand_path("../dummy/config/environment", __FILE__)

require "rspec/rails"
require "shoulda/matchers"
require "database_cleaner"
require "ostruct"

Dir[Games::Engine.root.join("spec/support/**/*.rb")].each { |f| require f }

require "teams/test_helpers"

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
  config.include Games::ObjectCreationMethods
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
' > components/games/spec/spec_helper.rb

echo '
--color
--require spec_helper
' > components/games/.rspec

cd components/games
BUNDLE_GEMFILE=`pwd`/Gemfile bundle
BUNDLE_GEMFILE=`pwd`/Gemfile bundle exec rails g migration MoveGameFromAppComponentToGames
cd ../..

echo '
class MoveGameFromAppComponentToGames < ActiveRecord::Migration[5.0]
  def change
    rename_table :app_component_games, :games_games
  end
end
' > `find . -iname '*move_game_from_app_component_to_games.rb'`

echo '
#!/bin/bash

exit_code=0

echo "
********************************************************************************
*** Running games engine specs
********************************************************************************"

export BUNDLE_GEMFILE=`pwd`/Gemfile
bundle install | grep Installing
bundle exec rake db:create db:migrate
RAILS_ENV=test bundle exec rake db:create
RAILS_ENV=test bundle exec rake db:migrate
bundle exec rspec spec
((exit_code+=$?))

exit $exit_code

' > components/games/test.sh

chmod +x components/games/test.sh


echo '
require_relative "../../spec/support/object_creation_methods.rb"

' > components/games/lib/games/test_helpers.rb

echo '
module Games::ObjectCreationMethods
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


#APPCOMPONENT

rm components/app_component/spec/support/object_creation_methods.rb
rm components/app_component/lib/app_component/test_helpers.rb
rm -rf components/app_component/db
rm -rf components/app_component/spec/
rm -rf components/app_component/test.sh

sed -i '/  require "teams"/d' components/app_component/lib/app_component.rb
sed -i '/  s\.add_dependency "teams"/d' components/app_component/app_component.gemspec
sed -i '/path "\.\." do/d' components/app_component/Gemfile
sed -i '/gem "teams"/d' components/app_component/Gemfile
sed -i '/^end$/d' components/app_component/Gemfile


grep -rl "AppComponent::Game" . | \
   xargs sed -i 's/AppComponent::Game/Games::Game/g'



sed -i '/path "\.\." do/a\  gem "games"' components/prediction_ui/Gemfile
sed -i '/s.add_dependency "rails".*/a\  s\.add_dependency "games"' components/prediction_ui/prediction_ui.gemspec
sed -i 's/require "app_component\/test_helpers"/require "games\/test_helpers"/' components/prediction_ui/spec/spec_helper.rb
sed -i 's/config\.include AppComponent::ObjectCreationMethods/config\.include Games::ObjectCreationMethods/' components/prediction_ui/spec/spec_helper.rb
sed -i '/module PredictionUi/a\  require "games"' components/prediction_ui/lib/prediction_ui.rb



sed -i '/path "\.\." do/a\  gem "games"' components/games_admin/Gemfile
sed -i '/s.add_dependency "rails".*/a\  s\.add_dependency "games"' components/games_admin/games_admin.gemspec
sed -i 's/require "app_component\/test_helpers"/require "games\/test_helpers"/' components/games_admin/spec/spec_helper.rb
sed -i 's/config\.include AppComponent::ObjectCreationMethods/config\.include Games::ObjectCreationMethods/' components/games_admin/spec/spec_helper.rb
sed -i '/module GamesAdmin/a\  require "games"' components/games_admin/lib/games_admin.rb


cd components/games
cat Gemfile
cat games.gemspec
BUNDLE_GEMFILE=`pwd`/Gemfile bundle package
cd ../..


cd ..

tar -zcvf $CHAPTER-`date +%Y%m%d%H%M%S`.tgz sportsball

