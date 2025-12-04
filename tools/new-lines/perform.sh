#!/usr/bin/env bash

SCRIPT_PATH=$(dirname "$0")
# util path might be one level up
if [ -e $(dirname "$0")/../../util ]; then
  UTIL_PATH=$(dirname "$0")/../../util
else
  UTIL_PATH=$(dirname "$0")/../util
fi

f="$1"

$SCRIPT_PATH/replace.sh "$f"
