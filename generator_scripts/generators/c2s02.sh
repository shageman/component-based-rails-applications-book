#!/bin/bash

set -v
set -x
set -e

gem install --source http://geminabox:9292 bundler -v 1.16.1 --no-ri --no-rdoc

tar -xzf code_input/$PREV_CHAPTER*.tgz -C code_output


cd code_output/sportsball/components/app_component

BUNDLE_GEMFILE=`pwd`/Gemfile bundle

bundle exec rails g scaffold team name:string

bundle exec rails g scaffold game date:datetime location:string \
                      first_team_id:integer second_team_id:integer \
                      winning_team:integer \
                      first_team_score:integer second_team_score:integer

cd ../..

sed -i '/isolate_namespace AppComponent/a\\n    initializer :append_migrations do |app|\n      unless app.root.to_s.match root.to_s+File::SEPARATOR\n        app.config.paths["db/migrate"].concat config.paths["db/migrate"].expanded\n      end\n    end' components/app_component/lib/app_component/engine.rb


cd ..
tar -zcvf $CHAPTER-`date +%Y%m%d%H%M%S`.tgz sportsball
