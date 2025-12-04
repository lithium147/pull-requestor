#!/bin/bash

f="$1"

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-i -e)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-i "" -e)
esac

# sed -E: Interpret regular expressions as extended (modern) regular expressions rather than basic regular expressions (BRE's).
function replace() {
  sed -E "${SED_OPTIONS[@]}" '
/'$1'\(/{
  :b
  /.*;[[:space:]]*$/!{N;bb
  }
  '$2'
}' "$f"
}

function replaceSingleLine() {
  sed -E "${SED_OPTIONS[@]}" "$1" "$f"
}

# regular expressions patterns:
# `[^",]*` Match a single character not present in the list `^",`
# ".*[^\]" Match a single character within double quotes, and it can distinguish escaped double quotes
# .*\(.*\) Match a single character within round brackets
# echo ''
# echo "Converting JUnit assertions to AssertJ assertions in files matching pattern : $FILES_PATTERN"
# echo ''
# echo ' 1 - Replacing : assertEquals(0, myList.size()) ................. by : assertThat(myList).isEmpty()'
replace 'assertEquals' 's/assertEquals\((".*[^\]"),[[:space:]]*0,[[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\.size\(\)\)/assertThat(\2).as(\1).isEmpty()/g'
replace 'assertEquals' 's/assertEquals\([[:space:]]*0,[[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\.size\(\)\)/assertThat(\1).isEmpty()/g'

# echo ' 2 - Replacing : assertEquals(expectedSize, myList.size()) ...... by : assertThat(myList).hasSize(expectedSize)'
replace 'assertEquals' 's/assertEquals\((".*[^\]"),[[:space:]]*([[:digit:]]*),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\.size\(\)\)/assertThat(\3).as(\1).hasSize(\2)/g'
replace 'assertEquals' 's/assertEquals\([[:space:]]*([[:digit:]]*),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\.size\(\)\)/assertThat(\2).hasSize(\1)/g'

# echo ' 3 - Replacing : assertEquals(expectedDouble, actual, delta) .... by : assertThat(actual).isCloseTo(expectedDouble, within(delta))'
# TODO not working in multiline
#replaceSingleLine 's/assertEquals\(([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\)/assertThat(\3).as(\1).isCloseTo(\2, within(\4))/g'
# must be done before assertEquals("description", expected, actual) -> assertThat(actual).as("description").isEqualTo(expected)
# will only replace triplets without double quote to avoid matching : assertEquals("description", expected, actual)
#replaceSingleLine 's/assertEquals\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\)/assertThat(\2).isCloseTo(\1, within(\3))/g'

# echo ' 4 - Replacing : assertEquals(expected, actual) ................. by : assertThat(actual).isEqualTo(expected)'
# as match doesn't handle complex values for expected/actual
replace 'assertEquals' 's/assertEquals\((".*[^\]"),[[:space:]]*([^",]*|[^",]*".*[^\]"[^",]*|.*\(.*\)),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\)/assertThat(\3).as(\1).isEqualTo(\2)/g'
replace 'assertEquals' 's/assertEquals\([[:space:]]*([^",]*|[^",]*".*[^\]"[^",]*|.*\(.*\)),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\)/assertThat(\2).isEqualTo(\1)/g'

# echo ' 5 - Replacing : assertArrayEquals(expectedArray, actual) ....... by : assertThat(actual).isEqualTo(expectedArray)'
replace 'assertArrayEquals' 's/assertArrayEquals\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\)/assertThat(\3).as(\1).isEqualTo(\2)/g'
replace 'assertArrayEquals' 's/assertArrayEquals\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\)/assertThat(\2).isEqualTo(\1)/g'

# echo ' 6 - Replacing : assertNull(actual) ............................. by : assertThat(actual).isNull()'
replace 'assertNull' 's/assertNull\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\)/assertThat(\2).as(\1).isNull()/g'
replace 'assertNull' 's/assertNull\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\)/assertThat(\1).isNull()/g'

# echo ' 7 - Replacing : assertNotNull(actual) .......................... by : assertThat(actual).isNotNull()'
replace 'assertNotNull' 's/assertNotNull\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\)/assertThat(\2).as(\1).isNotNull()/g'
replace 'assertNotNull' 's/assertNotNull\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\)/assertThat(\1).isNotNull()/g'

# echo ' 8 - Replacing : assertTrue(logicalCondition) ................... by : assertThat(logicalCondition).isTrue()'
# support two levels of matching brackets - repeated
replace 'assertTrue' 's/assertTrue\((String.format\([^)]*\)),[[:space:]]*([^",()]+|".*[^\]"|([^(]*\(([^(]*\([^)]*\)[^)]*|[^)]*)*\)[^)]*)+)\)/assertThat(\2).as(\1).isTrue()/'
replace 'assertTrue' 's/assertTrue\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\)/assertThat(\2).as(\1).isTrue()/g'
replace 'assertTrue' 's/assertTrue\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\)/assertThat(\1).isTrue()/g'

# echo ' 9 - Replacing : assertFalse(logicalCondition) .................. by : assertThat(logicalCondition).isFalse()'
replace 'assertFalse' 's/assertFalse\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\)/assertThat(\2).as(\1).isFalse()/g'
replace 'assertFalse' 's/assertFalse\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\)/assertThat(\1).isFalse()/g'

# echo '10 - Replacing : assertSame(expected, actual) ................... by : assertThat(actual).isSameAs(expected)'
replace 'assertSame' 's/assertSame\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\)/assertThat(\3).as(\1).isSameAs(\2)/g'
replace 'assertSame' 's/assertSame\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\)/assertThat(\2).isSameAs(\1)/g'

# echo '11 - Replacing : assertNotSame(expected, actual) ................ by : assertThat(actual).isNotSameAs(expected)'
replace 'assertNotSame' 's/assertNotSame\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\)/assertThat(\3).as(\1).isNotSameAs(\2)/g'
replace 'assertNotSame' 's/assertNotSame\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\)/assertThat(\2).isNotSameAs(\1)/g'


