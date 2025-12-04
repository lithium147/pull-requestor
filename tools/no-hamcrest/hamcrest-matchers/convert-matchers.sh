#!/bin/bash

f="$1"

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-i -e)
case "$(uname)" in
Darwin*) SED_OPTIONS=(-i "" -e) ;;
esac

# sed -E: Interpret regular expressions as extended (modern) regular expressions rather than basic regular expressions (BRE's).
function replace() {
  sed -E "${SED_OPTIONS[@]}" "$1" "$f"
}

# regular expressions patterns:
# `[^",]*` Match a single character not present in the list `^",`
# ".*[^\]" Match a single character within double quotes, and it can distinguish escaped double quotes
# .*\(.*\) Match a single character within round brackets
#echo ''
#echo "Converting hamcrest assertions to AssertJ assertions in files matching pattern : $FILES_PATTERN"
#echo ''

#echo ' 1 - Replacing : class TypeSafeMatcher ......... by : MatchingConsumer'
replace 's/([[:space:]])extends TypeSafeMatcher</\1extends MatchingConsumer</g'
#echo ' 2 - Replacing : interface TypeSafeMatcher ......... by : Consumer'
replace 's/([[:space:]])TypeSafeMatcher</\1Consumer</g'
#echo ' 3 - Replacing : interface Matcher ......... by : Consumer'
replace 's/([[:space:]])Matcher</\1Consumer</g'
#echo ' 4 - Replacing : Description ......... by : Consumer'
replace 's/([[:space:]])Matcher</\1Consumer</g'


