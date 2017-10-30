#!/bin/bash

set -v
set -x
set -e

gem install --source http://geminabox:9292 bundler -v 1.16.1 --no-ri --no-rdoc

tar -xzf code_input/$PREV_CHAPTER*.tgz -C code_output


cd code_output/sportsball

BUNDLE_GEMFILE=`pwd`/Gemfile bundle

rails plugin new components/teams_admin --full --mountable --skip-bundle \
    --skip-git --skip-test-unit --skip-gemfile-entry \
    --dummy-path=spec/dummy

sed -i 's/~> //g' components/teams_admin/teams_admin.gemspec

mkdir -p components/teams_admin/app/views/teams_admin
mkdir -p components/teams_admin/spec/controllers/teams_admin
mkdir -p components/teams_admin/spec/features

mv components/app_component/app/controllers/app_component/teams_controller.rb \
   components/teams_admin/app/controllers/teams_admin/
mv components/app_component/app/views/app_component/teams\
   components/teams_admin/app/views/teams_admin/teams

sed -i 's/ Team\./ AppComponent::Team\./g' components/teams_admin/app/controllers/teams_admin/teams_controller.rb

mv components/app_component/spec/controllers/app_component/teams_controller_spec.rb\
   components/teams_admin/spec/controllers/teams_admin/
mv components/app_component/spec/features/teams_spec.rb\
   components/teams_admin/spec/features

grep -rl "module AppComponent" components/teams_admin/ | \
   xargs sed -i 's/module AppComponent/module TeamsAdmin/g'
grep -rl "AppComponent::TeamsController" components/teams_admin/ | \
   xargs sed -i 's/AppComponent::TeamsController/TeamsAdmin::TeamsController/g'
grep -rl "AppComponent::Engine" components/teams_admin/ | \
   xargs sed -i 's/AppComponent::Engine/TeamsAdmin::Engine/g'
grep -rl "app_component/" components/teams_admin/ | \
   xargs sed -i 's;app_component/;teams_admin/;g'
#grep -rl "app_component\." components/teams_admin/ | \
#   xargs sed -i 's;app_component\.;teams_admin\.;g'

rm -rf components/teams_admin/app/assets
rm -rf components/teams_admin/app/helpers
rm -rf components/teams_admin/app/jobs
rm -rf components/teams_admin/app/mailers
rm -rf components/teams_admin/app/models
rm -rf components/teams_admin/test
rm -rf components/teams_admin/lib/tasks
rm -rf components/teams_admin/MIT-LICENSE

sed -i '/s\.homepage/d' components/teams_admin/teams_admin.gemspec
sed -i '/s\.description/d' components/teams_admin/teams_admin.gemspec
sed -i '/s\.license/d' components/teams_admin/teams_admin.gemspec
sed -i 's/TODO: //g' components/teams_admin/teams_admin.gemspec

sed -i 's/"MIT-LICENSE", //g' components/teams_admin/teams_admin.gemspec


sed -i 's/s\.authors\( *\)= \[".*"\]/s\.authors\1= \["Stephan Hagemann"\]/g' components/teams_admin/teams_admin.gemspec
sed -i 's/s\.emails\( *\)= \[".*"\]/s\.emails\1= \["stephan.hagemann@gmail.com"\]/g' components/teams_admin/teams_admin.gemspec


sed -i '/s.add_dependency "rails", ".*"/a\  s.add_dependency "slim-rails", "3.1.3"\n  s.add_dependency "jquery-rails", "4.3.1"\n\n  s.add_dependency "app_component"\n\n  s.add_development_dependency "rspec-rails"\n  s.add_development_dependency "shoulda-matchers"\n  s.add_development_dependency "database_cleaner"\n  s.add_development_dependency "capybara"\n  s.add_development_dependency "rails-controller-testing"\n' components/teams_admin/teams_admin.gemspec

echo '
source "http://geminabox:9292"

gemspec

path ".." do
  gem "app_component"
end

gem "trueskill", git: "https://github.com/benjaminleesmith/trueskill", ref: "e404f45af5b3fb86982881ce064a9c764cc6a901"
' > components/teams_admin/Gemfile

echo '
module TeamsAdmin
  class Engine < ::Rails::Engine
    isolate_namespace TeamsAdmin

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
' > components/teams_admin/lib/teams_admin/engine.rb

echo '
require "teams_admin/engine"

module TeamsAdmin
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
' > components/teams_admin/spec/spec_helper.rb


echo '
#!/bin/bash

exit_code=0

echo "
********************************************************************************
*** Running teams admin engine specs
********************************************************************************"

export BUNDLE_GEMFILE=`pwd`/Gemfile
bundle install | grep Installing
bundle exec rake db:create db:migrate
RAILS_ENV=test bundle exec rake db:create
RAILS_ENV=test bundle exec rake db:migrate
bundle exec rspec spec
((exit_code+=$?))

exit $exit_code

' > components/teams_admin/test.sh

chmod +x components/teams_admin/test.sh


echo '
--color
--require spec_helper
' > components/teams_admin/.rspec

echo '
TeamsAdmin::Engine.routes.draw do
  resources :teams
end
' > components/teams_admin/config/routes.rb




sed -i '/resources :teams/d' components/app_component/config/routes.rb


echo '
RSpec.describe "teams admin", :type => :feature do
  it "allows for the management of teams" do
    visit "/teams_admin/teams"

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
' > components/teams_admin/spec/features/teams_spec.rb

echo '
require "slim-rails"
require "jquery-rails"

require "app_component"

module TeamsAdmin
  require "teams_admin/engine"

  def self.nav_entry
    {name: "Teams", link: -> {::TeamsAdmin::Engine.routes.url_helpers.teams_path}}
  end
end
' > components/teams_admin/lib/teams_admin.rb

echo '
RSpec.describe "nav entry" do
  it "points at the list of teams" do
    entry = TeamsAdmin.nav_entry
    expect(entry[:name]).to eq "Teams"
    expect(entry[:link].call).to eq "/teams_admin/teams"
  end
end
' > components/teams_admin/spec/nav_entry_spec.rb

echo '
Rails.application.config.main_nav =
    [
        TeamsAdmin.nav_entry
    ]
' > components/teams_admin/spec/dummy/config/initializers/global_navigation.rb


sed -i '/path "components" do/a\  gem "teams_admin"' Gemfile

sed -i '/mount AppComponent/a\  mount TeamsAdmin::Engine, at: "\/teams_admin"' config/routes.rb

rm -rf components/teams_admin/app/views/layouts

echo '
module TeamsAdmin
  class ApplicationController < ActionController::Base
    layout "app_component/application"
  end
end
' > components/teams_admin/app/controllers/teams_admin/application_controller.rb

sed -i 's/link_to "Teams",.*/link_to "Teams", "\/teams_admin\/teams"/g' components/app_component/app/views/layouts/app_component/application.html.slim


cd components/teams_admin
BUNDLE_GEMFILE=`pwd`/Gemfile bundle package
cd ../..


cd ..

tar -zcvf $CHAPTER-`date +%Y%m%d%H%M%S`.tgz sportsball

