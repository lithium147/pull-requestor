#!/usr/bin/env bash

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-i '')
esac

SCRIPT_PATH=$(dirname "$0")

f="$1"
s="$2"
r="$3"

function replaceMultiline() {
  tag="$1"
  sed "${SED_OPTIONS[@]}" '
/<'"$tag"'>$/{
  :b
  /.*<'"$tag"'>.*<\/'"$tag"'>$/!{N;bb
  }
  '"$2"'
}' "$3"
}

replaceMultiline 'distributionManagement' "s/.*//;r $SCRIPT_PATH/dist-management-leg.txt" "$f"

# sed -E -z 's/profiles:\n[[:space:]]*active: \$\{spring.profiles.active\}/aaa/' src/main/resources/bootstrap.yml
