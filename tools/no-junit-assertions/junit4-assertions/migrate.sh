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
grep -Eq "import (static )?org.junit.[A-Z*]" "$f"
if [ $? -ne 0 ]; then
  exit
fi

echo -n 'junit4'

cp "$f" "$f.before-each"

echo -n .
$UTIL_PATH/use-static-reference.sh "$f" 'org.junit' 'Assert'
echo -n .
$SCRIPT_PATH/convert-assertions.sh "$f"
echo -n .
$UTIL_PATH/remove-trailing-newline.sh "$f" "$f.before-each"

diff "$f" "$f.before-each" >/dev/null
updated=$?
if [ $updated -ne 0 ]; then
  echo -n 'updated..'
  $UTIL_PATH/replace-static-import.sh "$f" 'org.junit.Assert.fail' 'org.assertj.core.api.Assertions.fail'
  echo -n .
  $UTIL_PATH/replace-static-import.sh "$f" 'org.junit.Assert.assertEquals' 'org.assertj.core.api.Assertions.assertThat'
  echo -n .
#replace 's/import static org\.junit\.Assert\.\*;/import static org.assertj.core.api.Assertions.*;/g'

  $UTIL_PATH/delete-imports.sh "$f" 'org.junit' '*' 'static'
  echo -n .
  $UTIL_PATH/add-static-import.sh "$f" 'org.assertj.core.api.Assertions.assertThat'
  echo -n .
  $UTIL_PATH/add-static-import.sh "$f" 'org.assertj.core.api.Assertions.fail'
  echo -n .

  $UTIL_PATH/remove-trailing-newline.sh "$f" "$f.before-each"
fi

rm "$f.before-each"
