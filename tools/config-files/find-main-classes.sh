#!/usr/bin/env bash

shopt -s nullglob
shopt -s globstar
# setopt extended_glob

function extractPackageAndClass() {
  local f=$1
  ff="${f%.*}"      # remove .java
  c="${ff##*/}"     # remove path to leave class name
  p="${ff%/*}"      # remove file name to leave path
  p="${p##*java/}"  # remove src/main/java
  p="${p//\//.}"    # convert path to package

  echo "$p $c"
}

for f in **/*.java; do
  if grep -Eq 'public static void main\(' "$f"; then
    extractPackageAndClass "$f"
  fi
done
