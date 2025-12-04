#!/usr/bin/env bash

# seems like these deps are no longer required
# but still used in risk-source - requires more investigation
exit

shopt -s nullglob
shopt -s globstar
# setopt extended_glob

SCRIPT_PATH=$(dirname "$0")
UTIL_PATH=$(dirname "$0")/../util

maxFilesAffected=0
if [ "$1" = "--maxFilesAffected" ]; then
  if [ "$#" -lt 2 ] || [ "$2" = "" ]; then
    echo "'--maxFilesAffected' requires a value, eg: --maxFilesAffected 100"
  fi
  maxFilesAffected=$2

  shift
  shift
fi

totalUpdated=0

for f in pom.xml; do
  # TODO what about multi-module projects?
  echo -n "Processing $f "

  cp "$f" "$f.before"

  # TODO determine latest version of dependency
  $UTIL_PATH/add-dependency.sh "$f" org.junit.jupiter junit-jupiter-engine 5.9.1 test
# these were required for intellij, but that seems no longer the case
#  $UTIL_PATH/add-dependency.sh "$f" org.junit.platform junit-platform-launcher 1.9.1 test
#  $UTIL_PATH/add-dependency.sh "$f" org.junit.vintage junit-vintage-engine 5.9.1 test

  diff "$f" "$f.before" >/dev/null
  updated=$?
  totalUpdated=$((totalUpdated + updated))
  if [ $updated -ne 0 ]; then
    echo -n 'updated..'
  fi

  rm "$f.before"
  echo 'done'

  if [[ $maxFilesAffected -gt 0 ]] && [[ $totalUpdated -ge $maxFilesAffected ]]; then
    echo "reached limit of $maxFilesAffected affected files"
    exit
  fi
done

echo totalUpdated=$totalUpdated
