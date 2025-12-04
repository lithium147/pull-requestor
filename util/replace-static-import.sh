#!/usr/bin/env bash

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-i)
case "$(uname)" in
Darwin*) SED_OPTIONS=(-i '') ;;
esac

f=$1
s=$2  # src - wildcards allowed
d=$3  # dst - no wildcards allowed

# static imports are for a method or all methods (*)

grep -q "import static ${d};" "$f"
if [ $? -eq 0 ]; then
  exit  # dst import already exists
fi

dStar="${d%.*}\.\*"
grep -q "import static ${dStar};" "$f"
if [ $? -eq 0 ]; then
  exit  # dst.* import already exists
fi

m="${d##*.}"  # the method
grep -Eq "([^0-9A-Za-z_]|^)${m}([^0-9A-Za-z_]|$)" "$f"
if [ $? -ne 0 ]; then
  exit  # method not used, so don't do replacement
fi

echo -n "replacing static import.."

sm="${s##*.}"  # src method - is it a wildcard?
if [ "$sm" == '*' ]; then
  # TODO escape the wildcard
  sed -E "${SED_OPTIONS[@]}" "s/import static ${s};/import static ${d};/g" "$f"
else
  sed -E "${SED_OPTIONS[@]}" "s/import static ${s};/import static ${d};/g" "$f"
fi
