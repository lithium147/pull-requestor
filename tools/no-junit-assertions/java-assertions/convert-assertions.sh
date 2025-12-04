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
/^[[:space:]]*'$1'/{
  :b
  /.*;[[:space:]]*$/!{N;bb
  }
  '$2'
}' "$f"
}

function replaceSingleLine() {
  sed -E "${SED_OPTIONS[@]}" "$1" "$f"
}

#assert (EmailReceiptAvailability.getEmailReceiptAvailabilityLevel()).equals(expectedEmailReceiptAvailabilityLevel);

replace 'assert' 's/^([[:space:]]*)assert[[:space:]][[:space:]]*([^;]*)/\1assertThat(\2).isTrue()/g'
replace 'assert' 's/^([[:space:]]*)assert\([[:space:]]*([^;]*)[[:space:]]*\)[[:space:]]*;/\1assertThat((\2)).isTrue();/g'
