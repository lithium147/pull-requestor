#!/usr/bin/env bash

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-E -i '')
esac

f=$1  # file

# match beginning of line to ensure nested interfaces are not included
if ! grep -E -q '^(public )?interface[[:space:]].*{' "$f"; then
  echo -n "not interface.."
  exit
fi

# abstract methods
sed "${SED_OPTIONS[@]}" 's/([[:space:]]*)public[[:space:]](.*;)/\1\2/' "$f"
# non-abstract methods (static, default, private)
# excluding interface or class definitions
# TODO might break nested classes
sed "${SED_OPTIONS[@]}" '/interface|class/!s/([[:space:]]*)public[[:space:]](.*\{)/\1\2/' "$f"
