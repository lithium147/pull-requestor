#!/usr/bin/env bash

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-i '')
esac

f="$1"
s="$2"
r="$3"

ESCAPED_SEARCH=$(printf '%s\n' "$s" | sed -e 's/[]\/$*.^[+]/\\&/g');
ESCAPED_REPLACE=$(printf '%s\n' "$r" | sed -e 's/[\/&]/\\&/g')

sed -E "${SED_OPTIONS[@]}" 's/'"$ESCAPED_SEARCH"'/'"$ESCAPED_REPLACE"'/g' $f
