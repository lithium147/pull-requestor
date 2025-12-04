#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

SCRIPT_PATH=$(dirname "$0")
# util path might be one level up
if [ -e $(dirname "$0")/../../util ]; then
  UTIL_PATH=$(dirname "$0")/../../util
else
  UTIL_PATH=$(dirname "$0")/../util
fi

# setup rules for releases and snapshots
totalUpdated=0

for f in pom.xml; do
  # TODO what about multi-module projects?
  echo -n "Processing $f "

  cp "$f" "$f.before"

  # TODO determine latest version of dependency
  echo -n '.'
  $UTIL_PATH/add-dependency.sh "$f" org.junit.jupiter junit-jupiter-engine 5.9.1 test
  echo -n '.'
  $UTIL_PATH/add-dependency.sh "$f" org.junit.platform junit-platform-launcher 1.9.1 test
  echo -n '.'
  $UTIL_PATH/add-dependency.sh "$f" org.junit.vintage junit-vintage-engine 5.9.1 test
  echo -n '.'

  if ! diff "$f" "$f.before" >/dev/null; then
    echo -n 'updated..'
    totalUpdated=$((totalUpdated + 1))
  else
    echo -n 'no-change..'
  fi

  rm "$f.before"
  echo 'done'
done
