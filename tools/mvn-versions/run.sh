#!/usr/bin/env bash

CUSTOM_PARAMS=("$@")

# assume all scripts are in the source dir
SCRIPT_PATH=$(dirname "$0")
# util path might be one level up
if [ -e $(dirname "$0")/../../util ]; then
  UTIL_PATH=$(dirname "$0")/../../util
else
  UTIL_PATH=$(dirname "$0")/../util
fi

ROOT_CHANGE_BRANCH="$CHANGE_BRANCH"
for f in pom.xml **/pom.xml; do
  if [ ! -e "$f" ]; then
    continue  # ignore if the glob doesn't match anything
  fi
  echo "found $f"
  pomDir=$(dirname $f)
  echo "running in $pomDir"
  cd "$pomDir" || exit
  # if its the root dir, don't need to include anything extra in the title
  if [ "$pomDir" != '.' ]; then
    export CHANGE_BRANCH="$CHANGE_BRANCH/$pomDir"
  fi

  # if it failed or made a change, then exit
  if ! $SCRIPT_PATH/runOnPom.sh "$@"; then
    echo "changed (or there was an error) $f, exiting"
    exit
  fi
  cd - || exit
  export CHANGE_BRANCH="$ROOT_CHANGE_BRANCH"
done