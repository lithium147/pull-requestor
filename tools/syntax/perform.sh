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

hashBefore='0'
hashAfter='1'
# repeat until file is not changed
while [ "$hashBefore" != "$hashAfter" ]; do
  hashBefore=$(md5sum "$f")
  echo -n '.x2.'
  $SCRIPT_PATH/no-same-line-annotations.sh "$f"
  hashAfter=$(md5sum "$f")
done

echo -n '.'
