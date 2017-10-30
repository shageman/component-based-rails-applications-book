#!/usr/bin/env bash

set -v
set -x

tar -xzf app_code/$CHAPTER*.tgz -C app_code

cd app_code/sportsball

gem install --source http://geminabox:9292 bundler -v 1.16.1 --no-ri --no-rdoc

./build.sh

exit $?