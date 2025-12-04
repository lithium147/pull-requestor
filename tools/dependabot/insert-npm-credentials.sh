#!/usr/bin/env bash

DEPENDABOT_SCRIPT="$1"
CREDENTIALS_FILE="$2"

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-i '')
esac

echo "adding credentials from $CREDENTIALS_FILE into $DEPENDABOT_SCRIPT"

sed -E "${SED_OPTIONS[@]}" '
/^[[:space:]]*credentials[[:space:]]*=[[:space:]]*\[$/{
  :b
  /^[[:space:]]*credentials[[:space:]]*=[[:space:]]*\[.*\][[:space:]]*$/!{N;bb
  }
  r '"$CREDENTIALS_FILE"'
}' "$DEPENDABOT_SCRIPT"
