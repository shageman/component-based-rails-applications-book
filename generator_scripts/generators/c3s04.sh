#!/usr/bin/env bash

set -v
set -x

tar -xzf code_input/$PREV_CHAPTER*.tgz -C code_output

cd code_output/sportsball

gem install --source http://geminabox:9292 bundler -v 1.16.1 --no-ri --no-rdoc

sed -i 's/sqlite3/pg/g' components/app_component/app_component.gemspec

sed -i 's/"sqlite3".*/"pg", "0.20.0"/g' Gemfile

echo '
development: &DEVELOPMENT
  adapter: postgresql
  database: sportsball_development
  host: concourse-db
  username: concourse_user
  password: concourse_pass
  pool: 5
  timeout: 5000

test: &TEST
  <<: *DEVELOPMENT
  database: sportsball_test
  min_messages: warning

production:
  adapter: postgresql
  database: sportsball_production
' > config/database.yml

echo '
development: &DEVELOPMENT
  adapter: postgresql
  database: sportsball_app_component_development
  host: concourse-db
  username: concourse_user
  password: concourse_pass
  pool: 5
  timeout: 5000

test: &TEST
  <<: *DEVELOPMENT
  database: sportsball_app_component_test
  min_messages: warning
' > components/app_component/spec/dummy/config/database.yml


cd components/app_component
BUNDLE_GEMFILE=`pwd`/Gemfile bundle

cd ../..
BUNDLE_GEMFILE=`pwd`/Gemfile bundle

cd ..

tar -zcvf $CHAPTER-`date +%Y%m%d%H%M%S`.tgz sportsball
