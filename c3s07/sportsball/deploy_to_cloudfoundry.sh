#!/bin/bash
trap "exit" ERR

APP_NAME="sportsball"

echo "-----> Deploying to CloudFoundry"
prepare_deploy_directory.sh

cd deploy
cf push $APP_NAME
cd ..

