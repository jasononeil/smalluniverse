#!/bin/sh

set -e
set -o nounset
set -o pipefail
set -o xtrace

# TODO: run unit tests etc? Or do we assume that'll happen in a CI pipeline once we're serious?

# Compile
yarn build

# Check the Dockerfile builds
docker build . --tag mealplanner

# Ensure the directories exist
ssh do "mkdir -p /var/www/mealplanner"
ssh do "mkdir -p /var/www/mealplanner/app-content"

# Deploy to my VPS
rsync -a Dockerfile do:/var/www/mealplanner/
rsync -a ./build do:/var/www/mealplanner/

# Build, stop and restart docker
ssh do "cd /var/www/mealplanner ; docker build . --tag mealplanner"
ssh do 'cd /var/www/mealplanner ; docker stop `docker ps -q --filter="ancestor=mealplanner"`'
ssh do "cd /var/www/mealplanner ; docker run -p 4723:4723 --volume /var/www/mealplanner/app-content/:/app/app-content  --rm --detach mealplanner"