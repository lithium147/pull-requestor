#!/usr/bin/env bash

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-i '')
esac

s="$1"

# TODO what if the source is a wildcard?
if [ ! -e "$s" ]; then
  echo "source doesn't exist, nothing to do"
  exit
fi

rm -f "$s"
