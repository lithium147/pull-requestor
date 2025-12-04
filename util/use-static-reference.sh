#!/usr/bin/env bash

f="$1"
p="$2"  # package
c="$3"  # class
m="$4"  # method that can be used as a static reference - leave empty for any method

# import org.hamcrest.MatcherAssert;
# import org.hamcrest.*;
# import org.hamcrest.Matchers.hasEntry;
grep -Eq "import[[:space:]]*${p}[[:space:]]*.[[:space:]]*(${c}|\*)[[:space:]]*;" "$f"
if [ $? -ne 0 ]; then
  exit  # import not found so it must be used statically
fi

echo -n non-static..

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-i '')
esac

# TODO multi line match
# TODO have to repeat replacement since there can be overlaps
# how to exclude the first char from the match?
if [ "$m" = '' ]; then
  sed -E "${SED_OPTIONS[@]}" "s/([^0-9A-Za-z_])${c}[[:space:]]*\.[[:space:]]*([0-9A-Za-z_]*)[[:space:]]*\(/\1\2(/g" "$f"
  sed -E "${SED_OPTIONS[@]}" "s/([^0-9A-Za-z_])${c}[[:space:]]*\.[[:space:]]*([0-9A-Za-z_]*)[[:space:]]*\(/\1\2(/g" "$f"
else
  sed -E "${SED_OPTIONS[@]}" "s/([^0-9A-Za-z_])${c}[[:space:]]*\.[[:space:]]*${m}[[:space:]]*\(/\1${m}(/g" "$f"
  sed -E "${SED_OPTIONS[@]}" "s/([^0-9A-Za-z_])${c}[[:space:]]*\.[[:space:]]*${m}[[:space:]]*\(/\1${m}(/g" "$f"
fi
