#!/usr/bin/env bash

shopt -s nullglob
shopt -s globstar
setopt extended_glob

SCRIPT_PATH=$(dirname "$0")
# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i)
case "$(uname)" in
Darwin*) SED_OPTIONS=(-E -i "") ;;
esac

a="$1"

mkdir -p .run

while read -r p c; do
  f=.run/$c.run.xml
  if [ -e "$f" ]; then
    # TODO if --recreate is specified then overwrite existing
    # but --recreate is not passed down
    echo "ignoring existing config: $f"
    continue
  fi
  cp -v $SCRIPT_PATH/java-app/.run/Application.run.xml "$f"

  # <option name="MAIN_CLASS_NAME" value="com.hsbc.host.raven.foxvatrade.Application" />
  sed "${SED_OPTIONS[@]}" 's/<option name="MAIN_CLASS_NAME" value="[^"]*" \/>/<option name="MAIN_CLASS_NAME" value="'$p.$c'" \/>/' "$f"
  # <module name="fo-xva-trade-service" />
  sed "${SED_OPTIONS[@]}" 's/<module name="[^"]*" \/>/<module name="'$a'" \/>/' "$f"
  # <configuration default="false" name="Application" type="Application" factoryName="Application" nameIsGenerated="true">
  sed "${SED_OPTIONS[@]}" 's/<configuration (.*) name="[^"]*" (.*)>/<configuration \1 name="'$c'" \2>/' "$f"
done < <($SCRIPT_PATH/find-main-classes.sh)

# TODO create runners for features
#while read -r p c; do

#done < <($SCRIPT_PATH/find-feature-runners.sh)

# junit tests to run from target dir
cp -v "$SCRIPT_PATH/java-app/.run/Template JUnit.run.xml" .run/
sed "${SED_OPTIONS[@]}" 's/<module name="[^"]*" \/>/<module name="'$a'" \/>/' ".run/Template JUnit.run.xml"
