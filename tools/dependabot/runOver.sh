#!/usr/bin/env bash
shopt -s globstar

# these are provided by jenkins
#export GITHUB_ORGANISATION=Customer-API-Platform
#export PROJECT=ContactService.ReceiptService

SCRIPT_PATH=$(dirname "$0")

# this requires the code to be checked out
# alternatively: could run a search command with github api

packageFileName=$1
packageType=$2

echo
echo "updating $packageType libraries"
# TODO this causes it to run twice on the root file
for f in $packageFileName **/$packageFileName; do
  if [ ! -e "$f" ]; then
    continue
  fi
  PACKAGE_ROOT=$(dirname "$f")
  echo "running dependabot for $packageType on $PACKAGE_ROOT"
  $SCRIPT_PATH/run.sh $packageType ${GITHUB_ORGANISATION}/${PROJECT} $PACKAGE_ROOT || true
done
