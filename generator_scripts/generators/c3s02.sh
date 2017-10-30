#!/bin/bash

set -v
set -x
set -e

gem install --source http://geminabox:9292 bundler -v 1.16.1 --no-ri --no-rdoc

tar -xzf code_input/$PREV_CHAPTER*.tgz -C code_output


cd code_output/sportsball

sed -i '/group :development, :test do/a\\n  gem "rspec-rails"' Gemfile

rm -r test
mkdir -p spec/features

echo '
#!/bin/bash

exit_code=0

echo "
********************************************************************************
*** Running app component engine specs
********************************************************************************"

export BUNDLE_GEMFILE=`pwd`/Gemfile
bundle
bundle exec rake db:create db:migrate
RAILS_ENV=test bundle exec rake db:create
RAILS_ENV=test bundle exec rake db:migrate
bundle exec rspec spec
((exit_code+=$?))

unset BUNDLE_GEMFILE

exit $exit_code
' > components/app_component/test.sh

echo '
#!/bin/bash

exit_code=0

echo "
********************************************************************************
*** Running container app specs
********************************************************************************"

export BUNDLE_GEMFILE=`pwd`/Gemfile
bundle
bundle exec rake db:drop
bundle exec rake environment db:create db:migrate
RAILS_ENV=test bundle exec rake db:create
RAILS_ENV=test bundle exec rake db:migrate
bundle exec rspec spec
((exit_code+=$?))

unset BUNDLE_GEMFILE

exit $exit_code
' > test.sh

echo '
#!/bin/bash

result=0

cd "$( dirname "${BASH_SOURCE[0]}" )"

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

echo '
--color
--require spec_helper
' > .rspec

echo '
require "spec_helper"

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
    AppComponent::Team.create! name: "UofL"
    AppComponent::Team.create! name: "UK"

    visit "/"
    click_link "Predictions"
    click_button "What is it going to be"
  end
end' > spec/features/app_spec.rb

echo '
Rails.application.routes.draw do
  mount AppComponent::Engine, at: "/"
end
' > config/routes.rb

echo '
ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"

require "rspec/rails"
require "capybara/rails"
require "capybara/rspec"

Dir[AppComponent::Engine.root.join("spec/support/**/*.rb")].each {|f| require f}

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
end
' > spec/spec_helper.rb

chmod +x components/app_component/test.sh
chmod +x test.sh
chmod +x build.sh


cd ..

tar -zcvf $CHAPTER-`date +%Y%m%d%H%M%S`.tgz sportsball

