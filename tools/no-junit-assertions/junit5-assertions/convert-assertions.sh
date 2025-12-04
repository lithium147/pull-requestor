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
# echo "Converting JUnit 5 assertions to AssertJ assertions in files matching pattern : $FILES_PATTERN"
# echo ''
# echo ' 1 - Replacing : assertEquals(0, myList.size()) ................. by : assertThat(myList).isEmpty()'
replace 'assertEquals' 's/assertEquals\([[:space:]]*0,[[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\.size\(\),[[:space:]]*(".*[^\]")\)/assertThat(\1).as(\2).isEmpty()/g'
replace 'assertEquals' 's/assertEquals\([[:space:]]*0,[[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\.size\(\)\)/assertThat(\1).isEmpty()/g'

# echo ' 2 - Replacing : assertEquals(expectedSize, myList.size()) ...... by : assertThat(myList).hasSize(expectedSize)'
replace 'assertEquals' 's/assertEquals\([[:space:]]*([[:digit:]]*),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\.size\(\),[[:space:]]*(".*[^\]")\)/assertThat(\2).as(\3).hasSize(\1)/g'
replace 'assertEquals' 's/assertEquals\([[:space:]]*([[:digit:]]*),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\.size\(\)\)/assertThat(\2).hasSize(\1)/g'

# echo ' 3 - Replacing : assertEquals(expectedDouble, actual, delta) .... by : assertThat(actual).isCloseTo(expectedDouble, within(delta))'
#replace 'assertEquals' 's/assertEquals\(([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*(".*[^\]")\)/assertThat(\2).as(\4).isCloseTo(\1, within(\3))/g'
# must be done before assertEquals("description", expected, actual) -> assertThat(actual).as("description").isEqualTo(expected)
# will only replace triplets without double quote to avoid matching : assertEquals("description", expected, actual)
#replace 'assertEquals' 's/assertEquals\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\)/assertThat(\2).isCloseTo(\1, within(\3))/g'

# echo ' 4 - Replacing : assertEquals(expected, actual) ................. by : assertThat(actual).isEqualTo(expected)'
replace 'assertEquals' 's/assertEquals\(([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*(".*[^\]")\)/assertThat(\2).as(\3).isEqualTo(\1)/g'
replace 'assertEquals' 's/assertEquals\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\)/assertThat(\2).isEqualTo(\1)/g'

# not working in jenkins
#                     |                                |  |                                                                    |
# there are two commas, so which one to match?
# need to be able to match sets of brackets - how to do that?
#        assertEquals(EnumSet.of(FontFormat.DOUBLE_WIDTH, FontFormat.DOUBLE_HEIGHT), ((PrintLine) printCommand).getFontFormats());
#        assertThat(FontFormat.DOUBLE_HEIGHT), ((PrintLine) printCommand).getFontFormats()).isEqualTo(EnumSet.of(FontFormat.DOUBLE_WIDTH);



# echo ' 4B - Replacing : assertNotEquals(expected, actual) ................. by : assertThat(actual).isNotEqualTo(expected)'
replace 'assertNotEquals' 's/assertNotEquals\((".*[^\]"),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\)/assertThat(\2).as(\3).isNotEqualTo(\1)/g'
replace 'assertNotEquals' 's/assertNotEquals\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\)/assertThat(\2).isNotEqualTo(\1)/g'

# echo ' 5 - Replacing : assertArrayEquals(expectedArray, actual) ....... by : assertThat(actual).isEqualTo(expectedArray)'
replace 'assertArrayEquals' 's/assertArrayEquals\(([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*(".*[^\]")\)/assertThat(\2).as(\3).isEqualTo(\1)/g'
replace 'assertArrayEquals' 's/assertArrayEquals\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\)/assertThat(\2).isEqualTo(\1)/g'

# echo ' 6 - Replacing : assertNull(actual) ............................. by : assertThat(actual).isNull()'
replace 'assertNull' 's/assertNull\(([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*(".*[^\]")\)/assertThat(\1).as(\2).isNull()/g'
replace 'assertNull' 's/assertNull\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\)/assertThat(\1).isNull()/g'

# echo ' 7 - Replacing : assertNotNull(actual) .......................... by : assertThat(actual).isNotNull()'
replace 'assertNotNull' 's/assertNotNull\(([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*(".*[^\]")\)/assertThat(\1).as(\2).isNotNull()/g'
replace 'assertNotNull' 's/assertNotNull\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\)/assertThat(\1).isNotNull()/g'

# echo ' 8 - Replacing : assertTrue(logicalCondition) ................... by : assertThat(logicalCondition).isTrue()'
replace 'assertTrue' 's/assertTrue\(([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*(".*[^\]")\)/assertThat(\1).as(\2).isTrue()/g'
replace 'assertTrue' 's/assertTrue\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\)/assertThat(\1).isTrue()/g'

# echo ' 9 - Replacing : assertFalse(logicalCondition) .................. by : assertThat(logicalCondition).isFalse()'
replace 'assertFalse' 's/assertFalse\(([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*(".*[^\]")\)/assertThat(\1).as(\2).isFalse()/g'
replace 'assertFalse' 's/assertFalse\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\)/assertThat(\1).isFalse()/g'

# echo '10 - Replacing : assertSame(expected, actual) ................... by : assertThat(actual).isSameAs(expected)'
replace 'assertSame' 's/assertSame\(([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*(".*[^\]")\)/assertThat(\2).as(\3).isSameAs(\1)/g'
replace 'assertSame' 's/assertSame\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\)/assertThat(\2).isSameAs(\1)/g'

# echo '11 - Replacing : assertNotSame(expected, actual) ................ by : assertThat(actual).isNotSameAs(expected)'
replace 'assertNotSame' 's/assertNotSame\(([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*(".*[^\]")\)/assertThat(\2).as(\3).isNotSameAs(\1)/g'
replace 'assertNotSame' 's/assertNotSame\([[:space:]]*([^",]*|".*[^\]"|.*\(.*\)),[[:space:]]*([^",]*|".*[^\]"|.*\(.*\))\)/assertThat(\2).isNotSameAs(\1)/g'

# echo ''
# echo '12 - Replacing JUnit 5 static imports by AssertJ ones, at this point you will probably need to :'
# echo '12 --- optimize imports with your IDE to remove unused imports'
# echo '12 --- add "import static org.assertj.core.api.Assertions.within;" if you were using JUnit 5 number assertions with deltas'
replaceSingleLine 's/import static org\.junit\.jupiter\.api\.Assertions\.fail;/import static org.assertj.core.api.Assertions.fail;/g'
replaceSingleLine 's/import static org\.junit\.jupiter\.api\.Assertions\.\*;/import static org.assertj.core.api.Assertions.*;/g'
# echo ''

replace 'assertThat' 's/assertThat\((.*)\.getStatus\(\)\)\.isEqualTo\(HttpStatus\.(.*)\)/assertThat(\1.getStatus().toString()).isEqualTo(HttpStatus.\2.toString())/g'
replace 'assertThat' 's/assertThat\((.*)\.status\(\)\)\.isEqualTo\(HttpStatus\.(.*)\)/assertThat(\1.getStatus().toString()).isEqualTo(HttpStatus.\2.toString())/g'

