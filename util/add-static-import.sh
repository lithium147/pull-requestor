#!/usr/bin/env bash

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-i)
case "$(uname)" in
Darwin*) SED_OPTIONS=(-i '') ;;
esac

f=$1
i=$2

grep -q "import static ${i};" "$f"
if [ $? -eq 0 ]; then
  exit  # import already exists
fi

iStar="${i%.*}\.\*"
grep -q "import static ${iStar};" "$f"
if [ $? -eq 0 ]; then
  exit  # import star already exists
fi

m="${i##*.}"  # the method
grep -Eq "([^0-9A-Za-z_]|^)${m}([^0-9A-Za-z_]|$)" "$f"
if [ $? -ne 0 ]; then
  exit  # method not used, so don't add import
fi

echo -n "add static import.."
# just add import after package for now

sed -E "${SED_OPTIONS[@]}" '/^package .*;/a\
\
import static '"${i}"';
' "$f"
