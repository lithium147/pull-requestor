#!/usr/bin/env bash

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-E -i '')
esac

f=$1  # file
p=$2  # package
c=$3  # class
i=$4  # interface (to be used instead of class)

# set-asides
# exclude class name in quotes, eg:
# .hasMessageContaining("Cannot construct instance of `java.util.Map`");
# could match something between two strings, eg: "aaa" qwerty Map "bbb"
# including the package reduces the chance of this
sed "${SED_OPTIONS[@]}" 's/("[^"]*)'"$p.$c"'([^"]*")/\1'"$p"'.SomethingThatWontBeFound\2/g' "$f"

sed "${SED_OPTIONS[@]}" "s/new $c</new SomethingThatWontBeFound</g" "$f"
sed "${SED_OPTIONS[@]}" "s/new $c\(/new SomethingThatWontBeFound(/g" "$f"
sed "${SED_OPTIONS[@]}" "s/([^0-9A-Za-z_\$£])$c::/\1SomethingThatWontBeFound::/g" "$f"
sed "${SED_OPTIONS[@]}" "s/([^0-9A-Za-z_\$£])$c\./\1SomethingThatWontBeFound./g" "$f"
sed "${SED_OPTIONS[@]}" "s/extends $c</extends SomethingThatWontBeFound</g" "$f"

# replace class with interface
sed "${SED_OPTIONS[@]}" "/import $p.$c;/n;s/([^0-9A-Za-z_\$£])$c([^0-9A-Za-z_\$£])/\1$i\2/g" "$f"

# revert the set-asides
sed "${SED_OPTIONS[@]}" "s/SomethingThatWontBeFound/$c/g" "$f"
