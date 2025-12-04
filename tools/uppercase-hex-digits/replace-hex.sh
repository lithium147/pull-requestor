#!/usr/bin/env bash

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-i '')
esac

f=$1  # file

for lc in a b c d e f; do
  uc=${lc^}
  sed "${SED_OPTIONS[@]}" "s/0x$lc/0x$uc/g" "$f"                       # 0xa
  for num in {1..16}; do
    # TODO can break out of loop if no replacement occurred
    sed "${SED_OPTIONS[@]}" "s/0x\([0-9A-Fa-f]\{$num\}\)$lc/0x\1$uc/g" "$f" # 0x0a
    echo -n '.'
  done
done
