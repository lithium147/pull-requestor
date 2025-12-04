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
$UTIL_PATH/add-static-import.sh "$f" 'org.assertj.core.api.Assertions.assertThatExceptionOfType'
$UTIL_PATH/add-import.sh "$f" 'org.springframework.test.context.junit.jupiter.SpringExtension'
$UTIL_PATH/add-import.sh "$f" 'org.mockito.junit.jupiter.MockitoExtension'
$UTIL_PATH/add-import.sh "$f" 'org.junit.jupiter.api.extension.ExtendWith'
$UTIL_PATH/add-import.sh "$f" 'org.junit.jupiter.api.Test'  # incase of @org.junit.Test
$UTIL_PATH/add-import.sh "$f" 'org.mockito.junit.jupiter.MockitoSettings'
$UTIL_PATH/add-import.sh "$f" 'org.mockito.quality.Strictness'
# The following require for replacing TemporaryFolder rule
$UTIL_PATH/add-import.sh "$f" 'org.junit.jupiter.api.io.TempDir'
$UTIL_PATH/add-import.sh "$f" 'org.junit.jupiter.api.BeforeEach'
$UTIL_PATH/add-import.sh "$f" 'java.io.File'
$UTIL_PATH/add-import.sh "$f" 'java.io.IOException'
#    $UTIL_PATH/remove-trailing-newline.sh "$f" "$f.before"
echo -n '.'
