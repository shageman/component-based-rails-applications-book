#!/usr/bin/env bash

set -v
set -x

gem install --source http://geminabox:9292 bundler -v 1.16.1 --no-ri --no-rdoc

tar -xzf c3s01_code/$CHAPTER*.tgz -C c3s01_code

cd c3s01_code/sportsball/components/app_component
BUNDLE_GEMFILE=`pwd`/Gemfile bundle
BUNDLE_GEMFILE=`pwd`/Gemfile RAILS_ENV=test bundle exec rake db:create
BUNDLE_GEMFILE=`pwd`/Gemfile RAILS_ENV=test bundle exec rake db:migrate
BUNDLE_GEMFILE=`pwd`/Gemfile bundle exec rspec spec

exit $?