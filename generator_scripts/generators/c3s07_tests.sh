#!/usr/bin/env bash

set -v
set -x

tar -xzf c3s07_code/$CHAPTER*.tgz -C c3s07_code

gem install --source http://geminabox:9292 bundler -v 1.16.1 --no-ri --no-rdoc


cd c3s07_code/sportsball/web_container

./build.sh

exit $?