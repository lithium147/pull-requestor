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
# ignore binary and windows files
fileType=$(file -i "$f")
if [[ "$fileType" =~ "dos" ]]; then
  exit
fi
if [[ ! "$fileType" =~ "text" ]]; then
  exit
fi

$SCRIPT_PATH/replace.sh "$f"
echo -n '.'
