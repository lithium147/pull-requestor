#!/usr/bin/env bash

shopt -s nullglob
shopt -s globstar
setopt extended_glob

SCRIPT_PATH=$(dirname "$0")
UTIL_PATH=$(dirname "$0")/../../util

totalUpdated=0

echo 'Migrating hamcrest matchers'

$SCRIPT_PATH/copy-consumer-classes.sh "$f"

for f in **/*Matcher.java **/*Matchers.java; do
  echo -n "Processing $f "

  # make sure its a hamcrest Matcher
  grep -Eq "TypeSafeMatcher" "$f"
  if [ $? -ne 0 ]; then
    echo "n/a"
    continue
  fi

  cp "$f" "$f.before"

  $SCRIPT_PATH/convert-matchers.sh "$f"
  $UTIL_PATH/remove-trailing-newline.sh "$f" "$f.before"

  diff "$f" "$f.before" >/dev/null
  updated=$?
  totalUpdated=$((totalUpdated + updated))
  if [ $updated -ne 0 ]; then
    echo -n 'updated..'
    $UTIL_PATH/replace-import.sh "$f" 'org.hamcrest.Matcher' 'java.util.function.Consumer'
    $UTIL_PATH/replace-import.sh "$f" 'org.hamcrest.TypeSafeMatcher' 'com.hsbc.contact.MatchingConsumer'
    $UTIL_PATH/replace-import.sh "$f" 'org.hamcrest.Description' 'com.hsbc.contact.Description'
    $UTIL_PATH/add-import.sh "$f" 'java.util.function.Consumer'
    $UTIL_PATH/delete-imports.sh "$f" 'org.hamcrest' '*'
    $UTIL_PATH/remove-trailing-newline.sh "$f" "$f.before"
  fi

  rm "$f.before"
  echo 'done'
done

echo totalUpdated=$totalUpdated
