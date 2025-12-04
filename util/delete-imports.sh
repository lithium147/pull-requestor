#!/usr/bin/env bash

f="$1"
p="$2"  # package
c="$3"  # class or * for all classes in package
s="$4"  # static only

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-i '')
esac

if [ "$c" == "*" ]; then
  if [ "$s" != "" ]; then
    sed -E "${SED_OPTIONS[@]}" "/import[[:space:]]+static[[:space:]]+${p}\.[A-Z*]/d" "$f"
  else
    sed -E "${SED_OPTIONS[@]}" "/import([[:space:]]+static)?[[:space:]]+${p}\.[A-Z*]/d" "$f"
  fi
else
  if [ "$s" != "" ]; then
    sed -E "${SED_OPTIONS[@]}" "/import[[:space:]]+static[[:space:]]+${p}\.${c}/d" "$f"
  else
    sed -E "${SED_OPTIONS[@]}" "/import([[:space:]]+static)?[[:space:]]+${p}\.${c}/d" "$f"
  fi
fi

