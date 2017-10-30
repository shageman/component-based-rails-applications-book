#!/usr/bin/env bash

set -v
set -x

tar -xzf code_input/$PREV_CHAPTER*.tgz -C code_output

cd code_output


mkdir sportsball/web_container
mv sportsball/* sportsball/web_container
mv sportsball/.* sportsball/web_container
mv sportsball/web_container/components sportsball


sed -i "s/cd \"$( dirname \"$\{BASH_SOURCE\[0\]\}\" )\"/cd \"$( dirname \"$\{BASH_SOURCE\[0\]\}\" )\"/\.\./g" sportsball/web_container/build.sh
sed -i 's/path "components" do/path "\.\.\/components" do/g' sportsball/web_container/Gemfile


echo '#!/bin/bash
trap "exit" ERR

APP_NAME="sportsball"

echo "-----> Deploying to CloudFoundry"
prepare_deploy_directory.sh

cd deploy
cf push $APP_NAME
cd ..
' > sportsball/deploy_to_cloudfoundry.sh

echo '#!/bin/bash
trap "exit" ERR

APP_NAME="stormy-hollows-9630"

echo "-----> Deploying to Heroku"
prepare_deploy_directory.sh

VERSION=`git rev-parse HEAD | perl -pe "chomp"`
echo "-----> Deploying application version $VERSION"

echo "       Creating build tarball...."
DEPLOY_FILENAME="deploy-$VERSION.tgz"
pushd deploy
tar -czf ../$DEPLOY_FILENAME .
popd

echo "       Requesting application specific source endpoint..."
SOURCE_ENDPOINT="$(curl -s -n \
    -X POST "https://api.heroku.com/apps/$APP_NAME/sources" \
    -H "Accept: application/vnd.heroku+json; version=3.streaming-build-output")"

PUT_URL=`echo $SOURCE_ENDPOINT | jsawk "return this.source_blob.put_url"`
echo "       Received blob endpoint: $PUT_URL"
GET_URL=`echo $SOURCE_ENDPOINT | jsawk "return this.source_blob.get_url"`
echo "       Received deploy endpoint: $GET_URL"

echo "       Upload app blob"
curl -s "$PUT_URL" -X PUT -H "Content-Type:" --data-binary @$DEPLOY_FILENAME

echo "       Deploy application"

DEPLOY_RESULT="$(curl -n -X POST "https://api.heroku.com/apps/$APP_NAME/builds"\
    -d "{\"source_blob\":{\"url\":\"$GET_URL\", \"version\": \"$VERSION\"}}" \
    -H "Accept: application/vnd.heroku+json; version=3.streaming-build-output" \
    -H "Content-Type: application/json")"

log_url=`echo "$DEPLOY_RESULT" | jsawk "return this.output_stream_url"`
echo "       Received log endpoint: $log_url"

curl "$log_url"
' > sportsball/deploy_to_heroku.sh

echo '#!/bin/bash
trap "exit" ERR

echo "       Copy deploy files into place"
rm -rf deploy
mkdir deploy
cp -R web_container/ deploy
cp -R components deploy
rm -rf deploy/tmp/*

echo "       Fix components directory reference"
sed -i ''s|"\.\./components|"components|g'' deploy/Gemfile
sed -i ''s|remote: \.\./components|remote: \.\/components|g'' \
    deploy/Gemfile.lock

echo "       Uploading application...."
' > sportsball/prepare_deploy_directory.sh


tar -zcvf $CHAPTER-`date +%Y%m%d%H%M%S`.tgz sportsball
