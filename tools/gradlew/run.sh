#!/usr/bin/env bash

# util path might be one level up
if [ -e $(dirname "$0")/../../util ]; then
  UTIL_PATH=$(dirname "$0")/../../util
else
  UTIL_PATH=$(dirname "$0")/../util
fi

jq --version

# how to get the latest gradle version?
# Use the github release name
curl -vs https://api.github.com/repos/gradle/gradle/releases/latest

latestGradleVersion=$(curl -s https://api.github.com/repos/gradle/gradle/releases/latest | jq -r '.name')
echo "updating gradle version to $latestGradleVersion"

function mkSemver() {
  # call any command on semver to validate the version format and add ".0" if required
  $UTIL_PATH/semver.sh get major "$1" &>/dev/null
  if [ $? -ne 0 ]; then
    echo "$1.0"
  else
    echo "$1"
  fi
}

# latest release might be of the previous major version, eg: 6.9.1
# could compare the version with the current version to make sure it is actually newer
currentGradleVersion=$(./gradlew --version | sed -nE '/^Gradle/s/Gradle //p')
echo "current gradle version $currentGradleVersion"

latestGradleSemver=$(mkSemver "$latestGradleVersion")
currentGradleSemver=$(mkSemver "$currentGradleVersion")

comparison=$($UTIL_PATH/semver.sh compare $latestGradleSemver $currentGradleSemver)
if [ $? -ne 0 ]; then
  echo "comparison failed, aborting"
  exit
fi

if [ "$comparison" -lt 0 ]; then
  echo "$latestGradleVersion is an older version than the current version of $currentGradleVersion"
else
  ./gradlew wrapper --gradle-version "$latestGradleVersion"
  # need to run twice to get latest wrapper files
  ./gradlew wrapper --gradle-version "$latestGradleVersion"
fi

