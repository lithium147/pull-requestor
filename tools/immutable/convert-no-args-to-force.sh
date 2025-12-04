#!/usr/bin/env bash

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-E -i '')
esac

f="$1"  # file

sed "${SED_OPTIONS[@]}" 's/^([[:space:]]*)@NoArgsConstructor[[:space:]]*$/\1@NoArgsConstructor(force = true)/' "$f"
