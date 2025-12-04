#!/usr/bin/env bash

shopt -s nullglob
shopt -s globstar
setopt extended_glob

SCRIPT_PATH=$(dirname "$0")
UTIL_PATH=$(dirname "$0")/../../util

totalUpdated=0

echo 'Migrating hamcrest assertions'

for f in **/*Test.java **/*Tests.java; do
  echo -n "Processing $f "

  # make sure its using hamcrest assertions
  grep -Eq "import (static )?org\.hamcrest" "$f"
  if [ $? -ne 0 ]; then
    echo "n/a"
    continue
  fi

  cp "$f" "$f.before"

  $UTIL_PATH/use-static-reference.sh "$f" 'org.hamcrest' 'MatcherAssert' 'assertThat'
  $UTIL_PATH/use-static-reference.sh "$f" 'org.hamcrest' 'Matchers' 'equalTo'
#  $UTIL_PATH/use-static-reference.sh "$f" 'org.hamcrest' 'Matchers'
  $UTIL_PATH/use-static-reference.sh "$f" 'org.hamcrest' 'CoreMatchers'
  $UTIL_PATH/use-static-reference.sh "$f" 'org.hamcrest.collection' 'IsIterableContainingInOrder'
  $UTIL_PATH/use-static-reference.sh "$f" 'org.hamcrest.collection' 'IsMapContaining'

  $SCRIPT_PATH/convert-assertions.sh "$f"
  $UTIL_PATH/replace-static-import.sh "$f" 'org.hamcrest.MatcherAssert.assertThat' 'org.assertj.core.api.Assertions.assertThat'

  $UTIL_PATH/remove-trailing-newline.sh "$f" "$f.before"

  diff "$f" "$f.before" >/dev/null
  updated=$?
  totalUpdated=$((totalUpdated + updated))
  if [ $updated -ne 0 ]; then
    echo -n 'updated..'
    # these two require the hamcrest-matcher replacement
    $UTIL_PATH/replace-static-import.sh "$f" 'org.hamcrest.Matchers.allOf' 'com.hsbc.MatchingConsumer.allOf'
    $UTIL_PATH/replace-static-import.sh "$f" 'org.hamcrest.Matchers.*' 'com.hsbc.MatchingConsumer.allOf'

# this one was not removed
#import static org.hamcrest.collection.IsIterableContainingInOrder.contains;

    $UTIL_PATH/delete-imports.sh "$f" 'org.hamcrest' '*'
    $UTIL_PATH/delete-imports.sh "$f" 'org.hamcrest.collection' '*'
    $UTIL_PATH/add-static-import.sh "$f" 'org.assertj.core.api.Assertions.assertThat'
    $UTIL_PATH/remove-trailing-newline.sh "$f" "$f.before"
  fi

  rm "$f.before"
  echo 'done'
done

echo totalUpdated=$totalUpdated
