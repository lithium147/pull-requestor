#!/usr/bin/env bash

SCRIPT_PATH=$(dirname "$0")
# util path might be one level up
if [ -e $(dirname "$0")/../../util ]; then
  UTIL_PATH=$(dirname "$0")/../../util
else
  UTIL_PATH=$(dirname "$0")/../util
fi

f="$1"

if [ -e build.gradle ]; then
  compileCmd="$SCRIPT_PATH/compile-gradle.sh"
else
  compileCmd="$SCRIPT_PATH/compile-maven.sh"
fi

if [[ "$f" =~ '/main/' ]]; then
  type='main'
else
  type='test'
fi

echo -n '.'
$SCRIPT_PATH/resolve-wildcards.sh "$compileCmd $type" "$f"
echo -n '.'
$SCRIPT_PATH/sort-imports.sh "$f"
echo -n '.'
$SCRIPT_PATH/organise-imports.sh "$f"
echo -n '.'
