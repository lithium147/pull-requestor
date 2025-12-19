#!/usr/bin/env bash

shopt -s nullglob
shopt -s globstar
setopt extended_glob

SCRIPT_PATH=$(dirname "$0")
# util path might be one level up
if [ -e $(dirname "$0")/../../util ]; then
  UTIL_PATH=$(dirname "$0")/../../util
else
  UTIL_PATH=$(dirname "$0")/../util
fi

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

for f in **/*.java; do
  echo -n "Processing $f "

  cp "$f" "$f.before"

  $SCRIPT_PATH/replace.sh "$f" 'java.util' 'EnumSet' 'Set'
  $SCRIPT_PATH/replace.sh "$f" 'java.util' 'HashSet' 'Set'
  $UTIL_PATH/remove-trailing-newline.sh "$f" "$f.before"

  diff "$f" "$f.before" >/dev/null
  updated=$?
  totalUpdated=$((totalUpdated + updated))
  if [ $updated -ne 0 ]; then
    echo -n 'updated..'
    $UTIL_PATH/add-import.sh "$f" 'java.util.Set'
    $UTIL_PATH/remove-trailing-newline.sh "$f" "$f.before"
  fi

  rm "$f.before"
  echo 'done'

  if [[ $maxFilesAffected -gt 0 ]] && [[ $totalUpdated -ge $maxFilesAffected ]]; then
    echo "reached limit of $maxFilesAffected affected files"
    exit
  fi
done

echo totalUpdated=$totalUpdated
