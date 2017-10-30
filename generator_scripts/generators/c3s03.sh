#!/bin/bash

set -v
set -x
set -e

gem install --source http://geminabox:9292 bundler -v 1.16.1 --no-ri --no-rdoc

tar -xzf code_input/$PREV_CHAPTER*.tgz -C code_output


cd code_output/sportsball

sed -i '/s.add_development_dependency "sqlite3"/a\\n  s.add_dependency "jquery-rails", "4.3.1"\n' components/app_component/app_component.gemspec

mkdir -p components/app_component/vendor/assets/javascripts/app_component
mkdir -p components/app_component/vendor/assets/stylesheets/app_component

mv ../../generator_scripts_repo/generator_scripts/assets/foundation-6.4.2/css/foundation.min.css components/app_component/vendor/assets/stylesheets/app_component/
mv ../../generator_scripts_repo/generator_scripts/assets/foundation-6.4.2/js/vendor/foundation.min.js components/app_component/vendor/assets/javascripts/app_component

cp ../../generator_scripts_repo/generator_scripts/assets/logo.png components/app_component/app/assets/images/app_component/logo.png


echo '
//= require jquery
//= require app_component/foundation.min.js
//= require jquery_ujs

$(document).ready(function(){
    $(document).foundation();
});
' > components/app_component/app/assets/javascripts/app_component/application.js


echo '
/*
 *= require app_component/foundation.min
 *= require_self
 */
' > components/app_component/app/assets/stylesheets/app_component/application.css

mkdir components/app_component/config/initializers

echo '
Rails.application.config.assets.precompile += %w( app_component/logo.png )
' > components/app_component/config/initializers/assets.rb

#TODO: this should now be done via sprockets manifest http://eileencodes.com/posts/the-sprockets-4-manifest/

sed -i '1s;^;require "jquery-rails";'  components/app_component/lib/app_component.rb

sed -i '/= link_to root_path do/a\\n                = image_tag "app_component/logo.png", width: "25px"\n' components/app_component/app/views/layouts/app_component/application.html.slim


cd ..

tar -zcvf $CHAPTER-`date +%Y%m%d%H%M%S`.tgz sportsball

