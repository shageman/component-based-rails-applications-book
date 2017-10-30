#!/usr/bin/env bash

set -v
set -x


exit 1

tar -xzf code_input/$PREV_CHAPTER*.tgz -C code_output

cd code_output/sportsball

gem install --source http://geminabox:9292 bundler -v 1.16.1 --no-ri --no-rdoc

cd ~/Documents/business/Component-based\ Rails/rails514_ruby242/c2s11/sportsball
sed -i 's/5.0.2/5.0.1/g' Gemfile

cd components/app_component
sed -i 's/5.0.2/5.0.1/g' app_component.gemspec
cd ../..

./build.sh

rm Gemfile.lock
rm components/app_component/Gemfile.lock

./build.sh


cd ~/Documents/business/Component-based\ Rails/rails514_ruby242/c2s11/sportsball_version_gem

echo '
source "https://rubygems.org"

path "components" do
  gem "app_component"
  gem "rails_version"
end

gem "trueskill", git: "https://github.com/benjaminleesmith/trueskill", ref: "e404f45af5b3fb86982881ce064a9c764cc6a901"

gem "sqlite3", "1.3.13"
gem "puma", "3.8.2"
gem "sass-rails", "5.0.6"
gem "uglifier", "3.2.0"
gem "coffee-rails", "4.2.1"
gem "turbolinks", "5.0.1"
gem "jbuilder", "2.6.3"

group :development, :test do
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  gem "selenium-webdriver"
  gem "rspec-rails"
  gem "capybara", "~> 2.13.0"
end

group :development do
  gem "web-console", ">= 3.3.0"
  gem "listen", ">= 3.0.5", "< 3.2"
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
end

gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
' > Gemfile


echo '
$:.push File.expand_path("../lib", __FILE__)

# Maintain your gems version:
require "app_component/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "app_component"
  s.version     = AppComponent::VERSION
  s.authors     = ["Stephan Hagemann"]
  s.email       = ["stephan.hagemann@gmail.com"]
  s.homepage    = ""
  s.summary     = "Summary of AppComponent."
  s.description = "Description of AppComponent."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails_version"
  s.add_dependency "slim-rails", "3.1.1"
  s.add_dependency "jquery-rails", "4.2.2"
  s.add_dependency "trueskill"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "shoulda-matchers"
  s.add_development_dependency "database_cleaner"
  s.add_development_dependency "capybara"
  s.add_development_dependency "rails-controller-testing"
end
' > components/app_component/app_component.gemspec

echo '
source "https://rubygems.org"

gemspec

gem "rails_version", path: "../rails_version"

gem "trueskill", git: "https://github.com/benjaminleesmith/trueskill", ref: "e404f45af5b3fb86982881ce064a9c764cc6a901"
' > components/app_component/Gemfile

mkdir components/rails_version

echo '
$:.push File.expand_path("../lib", __FILE__)

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rails_version"
  s.version     = "0.0.1"
  s.authors     = ["The CBRA Book"]
  s.summary     = "CBRA component"

  s.files = []
  s.test_files = []

  s.add_dependency "rails", "5.1.0"
end
' > components/rails_version/rails_version.gemspec

rm ~/Documents/business/Component-based\ Rails/rails514_ruby242/c2s11/sportsball_version_gem/Gemfile.lock
rm ~/Documents/business/Component-based\ Rails/rails514_ruby242/c2s11/sportsball_version_gem/components/app_component/Gemfile.lock

./build.sh

cd ..

tar -zcvf $CHAPTER-`date +%Y%m%d%H%M%S`.tgz sportsball
