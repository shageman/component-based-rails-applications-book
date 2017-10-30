#!/bin/bash

set -v
set -x
set -e

gem install --source http://geminabox:9292 bundler -v 1.16.1 --no-ri --no-rdoc

tar -xzf code_input/$PREV_CHAPTER*.tgz -C code_output


cd code_output/sportsball

bundle gem predictor --test=rspec --no-exe --no-coc --no-mit

rm -rf predictor/.git

rm -rf predictor/bin

rm -rf predictor/.gitignore
rm -rf predictor/.travis.yml
rm -rf predictor/CODE_OF_CONDUCT.md

rm -rf predictor/lib/predictor/version.rb

mv predictor components

sed -i 's/~> //g' components/predictor/predictor.gemspec

mv components/app_component/app/models/app_component/predictor.rb components/predictor/lib/predictor/predictor.rb
mv components/app_component/app/models/app_component/prediction.rb components/predictor/lib/predictor/prediction.rb

mkdir -p components/predictor/spec
mv components/app_component/spec/models/app_component/predictor_spec.rb components/predictor/spec/predictor_spec.rb

sed -i 's/module AppComponent/module Predictor/g' components/predictor/lib/predictor/predictor.rb
sed -i 's/AppComponent::/::Predictor::/g' components/predictor/lib/predictor/predictor.rb

sed -i 's/module AppComponent/module Predictor/g' components/predictor/lib/predictor/prediction.rb

echo '
require "saulabs/trueskill"

module Predictor
  require "predictor/predictor"
  require "predictor/prediction"
end
' > components/predictor/lib/predictor.rb

echo '
# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "predictor"
  spec.version       = "0.1.0"
  spec.authors       = ["Stephan Hagemann"]
  spec.email         = ["stephan.hagemann@gmail.com"]

  spec.summary       = %q{Prediction Core}

  spec.files = Dir["{lib}/**/*", "Rakefile", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "trueskill"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
' > components/predictor/predictor.gemspec

echo '
source "http://geminabox:9292/"

# Specify your gems dependencies in predictor.gemspec
gemspec

gem "trueskill", git: "https://github.com/benjaminleesmith/trueskill", ref: "e404f45af5b3fb86982881ce064a9c764cc6a901"
' > components/predictor/Gemfile

echo '
require "bundler/setup"
require "predictor"
require "ostruct"
' > components/predictor/spec/spec_helper.rb

echo '
require_relative "spec_helper.rb"

RSpec.describe Predictor::Predictor do
  before do
    @team1 = OpenStruct.new(id: 6)
    @team2 = OpenStruct.new(id: 7)

    @predictor = Predictor::Predictor.new([@team1, @team2])
  end

  it "predicts teams that have won in the past to win in the future" do
    game = OpenStruct.new(
        first_team_id: @team1.id, second_team_id: @team2.id, winning_team: 1)
    @predictor.learn([game])

    prediction = @predictor.predict(@team2, @team1)
    expect(prediction.winner).to eq @team1

    prediction = @predictor.predict(@team1, @team2)
    expect(prediction.winner).to eq @team1
  end

  it "changes predictions based on games learned" do
    game1 = OpenStruct.new(
        first_team_id: @team1.id, second_team_id: @team2.id, winning_team: 1)
    game2 = OpenStruct.new(
        first_team_id: @team1.id, second_team_id: @team2.id, winning_team: 2)
    game3 = OpenStruct.new(
        first_team_id: @team1.id, second_team_id: @team2.id, winning_team: 2)
    @predictor.learn([game1, game2, game3])

    prediction = @predictor.predict(@team1, @team2)
    expect(prediction.winner).to eq @team2
  end

  it "behaves funny when teams are equally strong" do
    prediction = @predictor.predict(@team1, @team2)
    expect(prediction.first_team).to eq @team1
    expect(prediction.second_team).to eq @team2
    expect(prediction.winner).to eq @team2

    prediction = @predictor.predict(@team2, @team1)
    expect(prediction.first_team).to eq @team2
    expect(prediction.second_team).to eq @team1
    expect(prediction.winner).to eq @team1
  end
end
' > components/predictor/spec/predictor_spec.rb

echo '
#!/bin/bash

exit_code=0

echo "
********************************************************************************
*** Running predictor gem specs
********************************************************************************"

export BUNDLE_GEMFILE=`pwd`/Gemfile
bundle install | grep Installing
bundle exec rspec spec
((exit_code+=$?))

exit $exit_code
' > components/predictor/test.sh

chmod +x components/predictor/test.sh

echo '
--color
--require spec_helper
' > components/predictor/.rspec

sed -i 's/Predictor\./::Predictor::Predictor./g' components/app_component/app/controllers/app_component/predictions_controller.rb

sed -i 's/AppComponent::Prediction$/::Predictor::Prediction/g' components/app_component/spec/controllers/app_component/predictions_controller_spec.rb

sed -i '/s.add_dependency "jquery-rails", "4.3.1"\n/a\  s.add_dependency "predictor"\n' components/app_component/app_component.gemspec

sed -i '/gemspec/a\\npath "\.\." do\n  gem "predictor"\nend\n' components/app_component/Gemfile

sed -i '/gem ''trueskill'',/d' components/app_component/app_component.gemspec

sed -i '/require "saulabs\/trueskill"/d' components/app_component/app_component.gemspec

sed -i '/module AppComponent/a\  require "predictor"' components/app_component/lib/app_component.rb


cd components/predictor
BUNDLE_GEMFILE=`pwd`/Gemfile bundle package
cd ../..


cd ..

tar -zcvf $CHAPTER-`date +%Y%m%d%H%M%S`.tgz sportsball

