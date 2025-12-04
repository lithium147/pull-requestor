#!/usr/bin/env bash

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-E -i '')
esac

f="$1"  # file

# TODO what about protected/public?
# Ignore:
# - fields already final
# - static fields
# - fields assigned a value
# - methods
# ensure the statement ends in a semicolon so its not a method
sed "${SED_OPTIONS[@]}" '/(final|static|[={])/!{s/^([[:space:]]*)private(.*);$/\1private final\2;/}' "$f"
