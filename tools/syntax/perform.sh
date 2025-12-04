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
$SCRIPT_PATH/replace-parenthesis.sh "$f"
echo -n '.'
$SCRIPT_PATH/remove-public-in-interface.sh "$f"
echo -n '.'
