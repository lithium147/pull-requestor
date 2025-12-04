#!/usr/bin/env bash

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i.bak)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-E -i '.bak')
esac

f="$1"  # file

function replaceMultiline() {
  sed "${SED_OPTIONS[@]}" '
/^\/\*/{
  :b
  /^\/\*.*(COPYRIGHT|Copyright|copyright).*\*\/$/!{N;bb
  }
  '"$1"'
}' "$2"

  # zero means true in bash if statements
  local changed=0
  if diff "$2" "$2.bak" &> /dev/null; then
    changed=1 # not changed
  fi
  rm "$2.bak"

  return $changed
}

if replaceMultiline "s/.*//" "$f"; then
  # remove the empty line left by the replacement
  sed "${SED_OPTIONS[@]}" '1d' "$f"
  rm -f "$f.bak"
fi
