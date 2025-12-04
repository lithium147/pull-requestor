#!/usr/bin/env bash

# assume all scripts are in the source dir
SCRIPT_PATH=$(dirname "$0")

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-E -i '')
esac

f="$1"  # file
name="$2"
version="$3"

# ${some-artifact.version} -> 1.2.4
sed "${SED_OPTIONS[@]}" 's/\$\{'"${name}"'\.version\}/'"${version}"'/' "$f"

# delete lines with: <some-artifact.version>
sed "${SED_OPTIONS[@]}" "/<${name}\.version>/d" "$f"
