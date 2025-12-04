#!/usr/bin/env bash

shopt -s nullglob
shopt -s globstar
setopt extended_glob

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

for f in **/*.java; do
  echo -n "Processing $f "

  cp "$f" "$f.before"

  $SCRIPT_PATH/replace.sh "$f" 'java.util' 'HashMap' 'Map'
  $SCRIPT_PATH/replace.sh "$f" 'java.util' 'LinkedHashMap' 'Map'
  $UTIL_PATH/remove-trailing-newline.sh "$f" "$f.before"

  diff "$f" "$f.before" >/dev/null
  updated=$?
  totalUpdated=$((totalUpdated + updated))
  if [ $updated -ne 0 ]; then
    echo -n 'updated..'
    $UTIL_PATH/add-import.sh "$f" 'java.util.Map'
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
