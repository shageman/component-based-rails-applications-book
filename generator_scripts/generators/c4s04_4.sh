#!/bin/bash

set -v
set -x
set -e

gem install --source http://geminabox:9292 bundler -v 1.16.1 --no-ri --no-rdoc

tar -xzf code_input/$PREV_CHAPTER*.tgz -C code_output


cd code_output/sportsball

BUNDLE_GEMFILE=`pwd`/Gemfile bundle

rails plugin new components/welcome_ui --full --mountable --skip-bundle \
    --skip-git --skip-test-unit --skip-gemfile-entry \
    --dummy-path=spec/dummy

sed -i 's/~> //g' components/welcome_ui/welcome_ui.gemspec

mkdir -p components/welcome_ui/app/views/welcome_ui
mkdir -p components/welcome_ui/spec/controllers/welcome_ui
mkdir -p components/welcome_ui/spec/features
mkdir -p components/welcome_ui/spec/helpers

mv components/app_component/app/controllers/app_component/welcome_controller.rb \
   components/welcome_ui/app/controllers/welcome_ui/
mv components/app_component/app/views/app_component/welcome\
   components/welcome_ui/app/views/welcome_ui/welcome

mv components/app_component/spec/controllers/app_component/welcome_controller_spec.rb\
   components/welcome_ui/spec/controllers/welcome_ui/

grep -rl "module AppComponent" components/welcome_ui/ | \
   xargs sed -i 's/module AppComponent/module WelcomeUi/g'
grep -rl "AppComponent::WelcomeController" components/welcome_ui/ | \
   xargs sed -i 's/AppComponent::WelcomeController/WelcomeUi::WelcomeController/g'
grep -rl "AppComponent::Engine" components/welcome_ui/ | \
   xargs sed -i 's/AppComponent::Engine/WelcomeUi::Engine/g'
grep -rl "app_component/" components/welcome_ui/ | \
   xargs sed -i 's;app_component/;welcome_ui/;g'

rm -rf components/welcome_ui/app/assets
rm -rf components/welcome_ui/app/helpers
rm -rf components/welcome_ui/app/jobs
rm -rf components/welcome_ui/app/mailers
rm -rf components/welcome_ui/app/models
rm -rf components/welcome_ui/test
rm -rf components/welcome_ui/lib/tasks
rm -rf components/welcome_ui/MIT-LICENSE

sed -i '/s\.homepage/d' components/welcome_ui/welcome_ui.gemspec
sed -i '/s\.description/d' components/welcome_ui/welcome_ui.gemspec
sed -i '/s\.license/d' components/welcome_ui/welcome_ui.gemspec
sed -i 's/TODO: //g' components/welcome_ui/welcome_ui.gemspec

sed -i 's/"MIT-LICENSE", //g' components/welcome_ui/welcome_ui.gemspec


sed -i 's/s\.authors\( *\)= \[".*"\]/s\.authors\1= \["Stephan Hagemann"\]/g' components/welcome_ui/welcome_ui.gemspec
sed -i 's/s\.emails\( *\)= \[".*"\]/s\.emails\1= \["stephan.hagemann@gmail.com"\]/g' components/welcome_ui/welcome_ui.gemspec


sed -i '/s.add_dependency "rails", ".*"/a\  s.add_dependency "slim-rails", "3.1.3"\n  s.add_dependency "jquery-rails", "4.3.1"\n\n  s.add_dependency "app_component"\n\n  s.add_development_dependency "rspec-rails"\n  s.add_development_dependency "rails-controller-testing"\n' components/welcome_ui/welcome_ui.gemspec

echo '
source "http://geminabox:9292"

gemspec

path ".." do
  gem "app_component"
end

gem "trueskill", git: "https://github.com/benjaminleesmith/trueskill", ref: "e404f45af5b3fb86982881ce064a9c764cc6a901"
' > components/welcome_ui/Gemfile


echo '
module WelcomeUi
  class Engine < ::Rails::Engine
    isolate_namespace WelcomeUi

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
' > components/welcome_ui/lib/welcome_ui/engine.rb

echo '
require "welcome_ui/engine"

module WelcomeUi
end
' > components/welcome_ui/lib/welcome_ui.rb





echo '
ENV["RAILS_ENV"] ||= "test"

require File.expand_path("../dummy/config/environment", __FILE__)

require "rspec/rails"

require "rails-controller-testing"
Rails::Controller::Testing.install

Dir[WelcomeUi::Engine.root.join("spec/support/**/*.rb")].each { |f| require f }

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

  [:controller, :view, :request].each do |type|
    config.include ::Rails::Controller::Testing::TestProcess, :type => type
    config.include ::Rails::Controller::Testing::TemplateAssertions, :type => type
    config.include ::Rails::Controller::Testing::Integration, :type => type
  end
end
' > components/welcome_ui/spec/spec_helper.rb


echo '
#!/bin/bash

exit_code=0

echo "
********************************************************************************
*** Running welcome ui engine specs
********************************************************************************"

export BUNDLE_GEMFILE=`pwd`/Gemfile
bundle install | grep Installing
bundle exec rake db:create db:migrate
RAILS_ENV=test bundle exec rake db:create
RAILS_ENV=test bundle exec rake db:migrate
bundle exec rspec spec
((exit_code+=$?))

exit $exit_code

' > components/welcome_ui/test.sh

chmod +x components/welcome_ui/test.sh


echo '
--color
--require spec_helper
' > components/welcome_ui/.rspec

echo '
WelcomeUi::Engine.routes.draw do
  resource :welcome, only: [:show], controller: "/welcome_ui/welcome"
  root to: "/welcome_ui/welcome#show"
end
' > components/welcome_ui/config/routes.rb


sed -i '/  resource :welcome, only: \[:show\]/d' components/app_component/config/routes.rb
sed -i '/  root to: "welcome#show"/d' components/app_component/config/routes.rb

sed -i '/path "components" do/a\  gem "welcome_ui"' Gemfile

sed -i '/Rails\.application\.routes.draw do/a\  mount WelcomeUi::Engine, at: "\/welcome_ui"' config/routes.rb
sed -i 's/root to: "app_component\/welcome#show"/root to: "welcome_ui\/welcome#show"/' config/routes.rb

rm -rf components/welcome_ui/app/views/layouts

echo '
module WelcomeUi
  class ApplicationController < ActionController::Base
    layout "app_component/application"
  end
end
' > components/welcome_ui/app/controllers/welcome_ui/application_controller.rb


cd ..

tar -zcvf $CHAPTER-`date +%Y%m%d%H%M%S`.tgz sportsball

