#!/usr/bin/env bash

SCRIPT_PATH=$(dirname "$0")
# util path might be one level up
if [ -e $(dirname "$0")/../../util ]; then
  UTIL_PATH=$(dirname "$0")/../../util
else
  UTIL_PATH=$(dirname "$0")/../util
fi

f="$1"

echo -n '.'
if ! grep -Eq "assertj" "$f"; then
  echo -n 'n/a'
  exit  # assertj not found so nothing to do
fi

echo -n '.'
$SCRIPT_PATH/assertj-shorthand/fix-assertions.sh "$f"
echo -n '.'
$SCRIPT_PATH/assertj-shorthand/combine-assertions.sh "$f"
echo -n '.'
$UTIL_PATH/delete-imports.sh "$f" 'org.assertj.core.api' 'AssertionsForClassTypes'
# cannot have both reactor and normal assertThat
if grep 'pl.rzrz.assertj.reactor.Assertions.assertThat' "$f"; then
  $UTIL_PATH/add-static-import.sh "$f" 'org.assertj.core.api.Assertions.assertThat'
fi
$UTIL_PATH/add-static-import.sh "$f" 'org.assertj.core.api.Assertions.catchException'
echo -n '.'

#replace:
#import static org.assertj.core.api.AssertionsForClassTypes...;
# with:
#import static org.assertj.core.api.Assertions...;
