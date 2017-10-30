#!/bin/bash

set -x

tar -xzf code_input/$PREV_CHAPTER*.tgz -C code_output


cd code_output/sportsball


rm -rf components/app_component/app/controllers
rm -rf components/app_component/app/models


RnAll() {
  for f in "$1"/* ; do
    [ -d "$f" ] || continue
    ( RnAll "$f" "$2" "$3" )
    [ "`basename $f`" \== "$2" ] && mv "$f" "`dirname $f`/$3"
  done
}
RnAll . app_component web_ui

grep -rl --exclude-dir=tmp --exclude-dir=migrate --exclude-dir=sprockets --exclude=*.log --exclude=*.sqlite3 "AppComponent" . | xargs sed -i 's/AppComponent/WebUi/g'

grep -rl --exclude-dir=tmp --exclude-dir=migrate --exclude-dir=sprockets --exclude=*.log --exclude=*.sqlite3 "app_component" . | xargs sed -i 's;app_component;web_ui;g'

mv components/web_ui/app/assets/config/app_component_manifest.js components/web_ui/app/assets/config/web_ui_manifest.js
mv components/web_ui/lib/app_component.rb components/web_ui/lib/web_ui.rb
mv components/web_ui/app_component.gemspec components/web_ui/web_ui.gemspec


cd ..

tar -zcvf $CHAPTER-`date +%Y%m%d%H%M%S`.tgz sportsball

