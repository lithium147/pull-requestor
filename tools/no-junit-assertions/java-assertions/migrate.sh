#!/usr/bin/env bash

SCRIPT_PATH=$(dirname "$0")
# util path might be two or three levels up
if [ -e $(dirname "$0")/../../../util ]; then
  UTIL_PATH=$(dirname "$0")/../../../util
else
  UTIL_PATH=$(dirname "$0")/../../util
fi

f="$1"

# make sure its using junit4 assertions
grep -Eq "assert" "$f"
if [ $? -ne 0 ]; then
  exit
fi

echo -n 'java'

cp "$f" "$f.before-each"

$SCRIPT_PATH/convert-assertions.sh "$f"
$UTIL_PATH/remove-trailing-newline.sh "$f" "$f.before-each"

diff "$f" "$f.before-each" >/dev/null
updated=$?
if [ $updated -ne 0 ]; then
  echo -n 'updated..'
  $UTIL_PATH/add-static-import.sh "$f" 'org.assertj.core.api.Assertions.assertThat'
  $UTIL_PATH/remove-trailing-newline.sh "$f" "$f.before-each"
fi

rm "$f.before-each"
