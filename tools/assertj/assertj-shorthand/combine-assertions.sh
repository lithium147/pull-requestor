#!/bin/bash

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i)
case "$(uname)" in
Darwin*) SED_OPTIONS=(-E -i "") ;;
esac

f="$1"

# Join repeated assertions:
#            assertThat(context).hasSingleBean(SecurityUtilAutoConfiguration.class);
#            assertThat(context).hasSingleBean(SecurityUtilConfiguration.class);

# join an assert onto a previous multi-expect assert
# by doing this, any number of asserts could be joined just by looping till there are no more joins
# XXX but doesn't join two multi-expect asserts
# also doesn't move the first expect onto its own line, perhaps could have another fix for that.
function fixRepeatedAsserts() {
  sed "${SED_OPTIONS[@]}" '
/^[[:space:]]*assertThat\([^)]+\)\./{
:b
N
s/^([[:space:]]*)(assertThat\([^()]+\))([[:space:]]*\.[^;]*);[[:space:]]*\2\.([^;]*);/\1\2\3\
\1        .\4;/;bb
}' "$f"
}

# matched brackets - ensure left and right brackets are matched
#mb='[^",()]+|".*[^\]"|([^(]*\(([^(]*\([^)]*\)[^)]*|[^)]*)*\)[^)]*)+'
mb='([^()]*(\(([^()]*\([^()]*\)[^()]*|[^()]*)*\))*[^()]*)+'
# an assert that spans multiple lines should have a line break after the initial assert
# works ok, but shows how mixed up the formatting is
# what about reformatting the assert as follows:
# - merged the assert back to one line
# - break assert on each top level "."
# won't be nice for assert with long value lists
# but these should probably be extracted as variables
function multipleExpectsStartOnNewLine() {
  sed "${SED_OPTIONS[@]}" '
s/^([[:space:]]*)(assertThat\('"$mb"'\))[[:space:]]*(\.[^;]*)$/\1\2\
\1        \6/
' "$f"
}

fixRepeatedAsserts
multipleExpectsStartOnNewLine
