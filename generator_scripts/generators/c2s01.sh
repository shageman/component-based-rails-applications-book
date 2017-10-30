#!/bin/bash

set -v
set -x
set -e

gem sources -c
gem sources -a http://geminabox:9292

gem install --source http://geminabox:9292 bundler -v 1.16.1 --no-ri --no-rdoc
gem install --source http://geminabox:9292 rails -v 5.1.4 --no-ri --no-rdoc


cd code_output

rails new sportsball --skip-bundle
cd sportsball

sed -i 's/'"'"'/"/g' Gemfile
sed -i 's/source "https:\/\/rubygems\.org/source "http:\/\/geminabox:9292\//g' Gemfile

rm -r app
rm -rf .git

BUNDLE_GEMFILE=`pwd`/Gemfile bundle package

mkdir components

BUNDLE_GEMFILE=`pwd`/Gemfile bundle exec rails plugin new components/app_component --full --mountable -skip-bundle

sed -i 's/#.*//g' components/app_component/Gemfile
sed -i 's/'"'"'/"/g' components/app_component/Gemfile
sed -i 's/source "https:\/\/rubygems\.org/source "http:\/\/geminabox:9292\//g' components/app_component/Gemfile

sed -i '/s\.homepage/d' components/app_component/app_component.gemspec
sed -i '/s\.description/d' components/app_component/app_component.gemspec
sed -i '/s\.license/d' components/app_component/app_component.gemspec
sed -i 's/TODO: //g' components/app_component/app_component.gemspec

sed -i 's/"MIT-LICENSE", //g' components/app_component/app_component.gemspec
rm components/app_component/MIT-LICENSE

sed -i 's/s\.authors\( *\)= \[".*"\]/s\.authors\1= \["Stephan Hagemann"\]/g' components/app_component/app_component.gemspec
sed -i 's/s\.emails\( *\)= \[".*"\]/s\.emails\1= \["stephan.hagemann@gmail.com"\]/g' components/app_component/app_component.gemspec


cd components/app_component

BUNDLE_GEMFILE=`pwd`/Gemfile bundle package
BUNDLE_GEMFILE=`pwd`/Gemfile bundle exec rails g controller welcome index

cd ../..

sed -i "s/.*get 'welcome\/index'/  root to: 'welcome#index'/" components/app_component/config/routes.rb
sed -i '/Rails\.application\.routes\.draw do/a\  mount AppComponent::Engine, at: "\/"' config/routes.rb



cd ..
tar -zcvf $CHAPTER-`date +%Y%m%d%H%M%S`.tgz sportsball

