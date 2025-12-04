#!/usr/bin/env bash

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-i)
case "$(uname)" in
Darwin*) SED_OPTIONS=(-i '') ;;
esac

f=$1
s=$2  # src - no wildcards allowed
d=$3  # dst - no wildcards allowed

# class import is for a class or all classes in a package (*)

grep -q "import ${d};" "$f"
if [ $? -eq 0 ]; then
  exit  # dst import already exists
fi

dStar="${d%.*}\.\*"
grep -q "import ${dStar};" "$f"
if [ $? -eq 0 ]; then
  exit  # dst.* import already exists
fi

c="${d##*.}"  # the class
grep -Eq "([^0-9A-Za-z_]|^)${c}([^0-9A-Za-z_]|$)" "$f"
if [ $? -ne 0 ]; then
  exit  # class not used, so don't do replacement
fi

echo -n "replacing import.."

sed -E "${SED_OPTIONS[@]}" "s/import ${s};/import ${d};/g" "$f"

#SCRIPT_PATH=$(dirname "$0")
#$JAVA_HOME/bin/java -jar $SCRIPT_PATH/google-java-format-all-deps.jar --fix-imports-only --skip-sorting-imports -i "$f"
