#!/bin/bash
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

