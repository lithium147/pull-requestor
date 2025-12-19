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

#files='**/*.java **/*.feature **/*.xml **/*.sh **/*.groovy **/*.Jenkinsfile **/Jenkinsfile **/*.yml'
# could apply to any text file really
# TODO detect if file is text or binary so can ignore binary files

files=$(cat "$SCRIPT_PATH/files.txt")
source $UTIL_PATH/stdargs.sh

for f in $files; do
  totalProcessed=$((totalProcessed + 1))
  if [ ! -e "$f" ]; then
    echo "$f doesn't exist, ignoring"
    continue
  fi
  echo -n "Processing $f."

  cp "$f" "$f.before"

  $SCRIPT_PATH/perform.sh "$f"
  $UTIL_PATH/remove-trailing-newline.sh "$f" "$f.before"

  diff "$f" "$f.before" >/dev/null
  updated=$?
  totalUpdated=$((totalUpdated + updated))
  if [ $updated -ne 0 ]; then
    if [ -e "$SCRIPT_PATH/updated.sh" ]; then
      $SCRIPT_PATH/updated.sh "$f"
    fi
    echo -n 'updated..'
  fi

  rm "$f.before"
  echo 'done'

  if [[ $maxFilesAffected -gt 0 ]] && [[ $totalUpdated -ge $maxFilesAffected ]]; then
    echo "reached limit of $maxFilesAffected files affected"
    exit
  fi
  if [[ $maxFilesProcessed -gt 0 ]] && [[ $totalProcessed -ge $maxFilesProcessed ]]; then
    echo "reached limit of $maxFilesProcessed files processed"
    exit
  fi
done

echo totalUpdated=$totalUpdated totalProcessed=$totalProcessed

tool=${SCRIPT_PATH##*/}
title="$tool updated $totalUpdated file(s)"
echo $title
