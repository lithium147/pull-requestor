#!/usr/bin/env bash

SCRIPT_PATH=$(dirname "$0")
# util path might be two or three levels up
if [ -e $(dirname "$0")/../../../util ]; then
  UTIL_PATH=$(dirname "$0")/../../../util
else
  UTIL_PATH=$(dirname "$0")/../../util
fi

f="$1"

# make sure its using junit5 assertions
grep -Eq "import (static )?org.junit.jupiter.api.Assertions" "$f"
if [ $? -ne 0 ]; then
  exit
fi

echo -n 'junit5'

cp "$f" "$f.before-each"

$UTIL_PATH/use-static-reference.sh "$f" 'org.junit.jupiter.api' 'Assertions'

$SCRIPT_PATH/convert-extra-assertions.sh "$f"
$SCRIPT_PATH/convert-assertions.sh "$f"
$UTIL_PATH/replace-static-import.sh "$f" 'org.junit.jupiter.api.Assertions.assertDoesNotThrow' 'org.assertj.core.api.Assertions.catchThrowable'
$UTIL_PATH/replace-static-import.sh "$f" 'org.junit.jupiter.api.Assertions.assertThrows' 'org.assertj.core.api.Assertions.catchThrowable'
$UTIL_PATH/replace-static-import.sh "$f" 'org.junit.jupiter.api.Assertions.assertThrows' 'org.assertj.core.api.Assertions.catchThrowableOfType'
#$UTIL_PATH/replace-static-import.sh "$f" 'org.junit.jupiter.api.Assertions.fail' 'org.assertj.core.api.Assertions.fail'
$UTIL_PATH/remove-trailing-newline.sh "$f" "$f.before-each"

diff "$f" "$f.before-each" >/dev/null
updated=$?
if [ $updated -ne 0 ]; then
  echo -n 'updated..'
  $UTIL_PATH/delete-imports.sh "$f" 'org.junit.jupiter.api' '*' 'static'
  $UTIL_PATH/delete-imports.sh "$f" 'org.junit.jupiter.api' 'Assertions'
  $UTIL_PATH/add-static-import.sh "$f" 'org.assertj.core.api.Assertions.assertThat'
  $UTIL_PATH/add-static-import.sh "$f" 'org.assertj.core.api.Assertions.catchThrowable'
  $UTIL_PATH/add-static-import.sh "$f" 'org.assertj.core.api.Assertions.catchThrowableOfType'
  $UTIL_PATH/add-static-import.sh "$f" 'org.assertj.core.api.Assertions.fail'

  $UTIL_PATH/remove-trailing-newline.sh "$f" "$f.before-each"
fi

rm "$f.before-each"
