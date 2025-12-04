#!/usr/bin/env bash

SCRIPT_PATH=$(dirname "$0")
TEMP_PATH="$(mktemp -d /tmp/pr-dependabot-script.XXXXXX)"

cd $TEMP_PATH
git clone https://github.com/dependabot/dependabot-script.git
$SCRIPT_PATH/insert-npm-credentials.sh dependabot-script/generic-update-script.rb "$SCRIPT_PATH/npm-contact-credentials.rb"

docker build --tag dependabot-script dependabot-script/
