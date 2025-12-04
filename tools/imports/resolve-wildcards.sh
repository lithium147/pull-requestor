#!/usr/bin/env bash

# util path might be one level up
if [ -e $(dirname "$0")/../../util ]; then
  UTIL_PATH=$(dirname "$0")/../../util
else
  UTIL_PATH=$(dirname "$0")/../util
fi

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-E -i '')
esac

compileCmd="$1"
f="$2"  # file

maxIterations=20
iterations=0

grep 'import.*\.\*;' "$f" | while read i
do
  echo "resolving wildcard $i"

  static=0
  if [[ "$i" =~ " static " ]]; then
    static=1
  fi

  # remove the wildcard import
  escaped="${i%.*}\.\*"
  echo "escaped=$escaped"
  sed "${SED_OPTIONS[@]}" "/$escaped/d" "$f"

  echo -n building..
  symbols=($($compileCmd))

  if [ "$symbols" == "" ]; then
    # TODO reverts the whole file, but could keep the previous changes
    echo "no symbols detected, reverting change"
    cp $f.before $f
    exit
  fi

  echo "symbols=${symbols[*]}"
  while [ "$symbols" != "" ]; do
    for s in "${symbols[@]}"; do
      newImport=${i%.*}.$s
      if [[ $static -eq 0 ]]; then
        newImport="${newImport##import }"  # the class
        $UTIL_PATH/add-import.sh "$f" $newImport
      else
        newImport="${newImport##import static }"  # the class
        $UTIL_PATH/add-static-import.sh "$f" $newImport
      fi
      echo "resolved $newImport"
    done

    iterations=$((iterations + 1))
    if [[ $maxIterations -gt 0 ]] && [[ $iterations -ge $maxIterations ]]; then
      echo "reached limit of $maxIterations, aborting"
      cp $f.before $f
      exit
    fi

    echo -n building..
    symbols=($($compileCmd))
    echo "symbols=${symbols[*]}"
  done
  echo "resolved"
done
