#!/usr/bin/env bash

shopt -s nullglob
shopt -s globstar
setopt extended_glob

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i.bak)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-E -i '.bak')
esac

SCRIPT_PATH=$(dirname "$0")

function appendMultiline() {
  local tag="$1"
  # insert \1 and an extra indent level at beginning of each line so the indentation is preserved
  local newContent=$(cat "$2")
  newContent="${newContent//\//\\/}"
  newContent="\1    ${newContent//$'\n'/\\$'\n'\\1    }"
  local file="$3"
#  echo "$newContent"
  sed "${SED_OPTIONS[@]}" '
/<dependencyManagement>/,/<\/dependencyManagement>/be
/<pluginManagement>/,/<\/pluginManagement>/be
/<profiles>/,/<\/profiles>/be
/<plugins>/,/<\/plugins>/be
s/^([[:space:]]*)<\/'"$tag"'>.*/'"$newContent"'\n\0/
:e
' "$file"
  rm "${file}.bak"
}

if [ -e requirements.txt ]; then
    echo "python" > $SCRIPT_PATH/labels.txt
    # Copy groovy files for now
    cp -rfv $SCRIPT_PATH/groovy/. .
elif [ -e pom.xml ]; then
  if grep "<artifactId>gmavenplus-plugin</artifactId>" pom.xml; then
    echo "pom detected with <artifactId>gmavenplus-plugin</artifactId>, assuming groovy project"
    echo "groovy" > $SCRIPT_PATH/labels.txt
    # Copy all files including dot files, but excluding '..'
    cp -rfv $SCRIPT_PATH/groovy/. .
  else
    echo "pom detected, assuming java project"
    echo "java" > $SCRIPT_PATH/labels.txt
    # Copy all files including dot files, but excluding '..'
    cp -rfv $SCRIPT_PATH/java/. .
    if [ -e "xxx.gitignore" ]; then
      rm -f .gitignore
      mv xxx.gitignore .gitignore
    fi

    # src/test/lombok.config only required for spring-boot projects
    if ! grep 'spring-boot' pom.xml; then
      rm -f src/test/lombok.config
    fi

    # Need the project.artifactId to create the run config
    # assume the first artifactId tag in the pom is the main one
    # TODO exclude parent block in case it appears first
    artifactId=$(sed -E -n 's/^.*<artifactId>(.*)<\/artifactId>.*$/\1/p' pom.xml | head -n 1)
    $SCRIPT_PATH/create-run-configs.sh "$artifactId"

    # .run not required for libs, how to detect lib?
  #  if grep '@SpringBootApplication' ./**/main/**/*.java; then
  #    echo "@SpringBootApplication detected, assuming java application"
  #    echo "application" >> $SCRIPT_PATH/labels.txt
  #    cp -rfv $SCRIPT_PATH/java-app/.run .
  #  TODO patch the run config:
  #    <module name="fo-xva-trade-service" />
  #    <option name="MAIN_CLASS_NAME" value="com.hsbc.host.raven.foxvatrade.Application" />
  #    The file name should match the class name
  #    Could search for main classes and create run config for it
  #  fi

    # Need to add some mandatory dependencies to the pom
    # Could do that here, or could be in plugin tool, or perhaps a new tool.
    # The lombok.config requires the spotbugs dep, so would make sense to do it here
    # There could be some other mandatory deps like junit
    # So could have a list of snippets to add.
    # plugins are different because they have config
    # does the order matter? perhaps could have another tool sort the dependencies
    echo >> $SCRIPT_PATH/description.txt
    for dependency in $SCRIPT_PATH/dependencies/*.xml; do
      artifactId="${dependency%.*}"    # remove .xml
      artifactId="${artifactId##*/}"   # remove path to leave file name
      echo "checking for $artifactId"
      if ! cat "pom.xml" | sed -E '/<dependencyManagement>/,/<\/dependencyManagement>/d;/<pluginManagement>/,/<\/pluginManagement>/d;/<profiles>/,/<\/profiles>/d;/<plugins>/,/<\/plugins>/d' | grep -q "<artifactId>$artifactId<\/artifactId>"; then
        echo "missing $artifactId, adding to end of dependencies"
        appendMultiline 'dependencies' "$dependency" "pom.xml"
        echo "$artifactId" >> $SCRIPT_PATH/description.txt
      fi
    done
  fi
fi

git add .
# TODO the following tries to add '..'
# fatal: ..: '..' is outside repository at 'C:/Users/43999227/IdeaProjects/raven-risk-source'
git add .* || true
