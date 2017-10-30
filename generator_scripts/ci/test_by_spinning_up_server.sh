#!/usr/bin/env bash

set -v
set -x
set -e

gem install --source http://geminabox:9292 bundler -v 1.16.1 --no-ri --no-rdoc

tar -xzf app_code/$CHAPTER*.tgz -C app_code


cd app_code/sportsball

BUNDLE_GEMFILE=`pwd`/Gemfile bundle --local

BUNDLE_GEMFILE=`pwd`/Gemfile bundle exec rails s &

sleep 10

curl localhost:3000
exit $?