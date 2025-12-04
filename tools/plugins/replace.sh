#!/usr/bin/env bash

shopt -s nullglob

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i.bak)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-E -i '.bak')
esac

SCRIPT_PATH=$(dirname "$0")

f="$1"

function replaceMultiline() {
  local tag="$1"
  local artifactId="$2"
  # insert \1 at beginning of each line so the indentation is preserved
  local newContent=$(cat "$3")
  newContent="${newContent//\//\\/}"
  newContent="\1${newContent//$'\n'/\\$'\n'\\1}"
  local file="$4"
#  echo "$newContent"
  # ignore pluginManagement/profiles by skipping to end
  sed "${SED_OPTIONS[@]}" '
/<pluginManagement>/,/<\/pluginManagement>/be
/<profiles>/,/<\/profiles>/be
/<'"$tag"'>$/{
  :b
  /<'"$tag"'>.*<\/'"$tag"'>$/!{N;bb
  }
  /<'"$tag"'>.*<artifactId>'"$artifactId"'<\/artifactId>/{s/^([[:space:]]*)<'"$tag"'>.*/'"$newContent"'/
  }
}
:e
' "$file"

  # zero means true in bash if statements
  local changed=0
  if diff "${file}" "${file}.bak" &> /dev/null; then
    changed=1 # not changed
  fi
  rm "${file}.bak"

  return $changed
}

function isExcluded() {
  local artifactId="$1"
  local suffix="$2"
  local file="$3"

  excludeFile="$SCRIPT_PATH/templates/${artifactId}.exclude.${suffix}"
  if [ -f "$excludeFile" ]; then
    while IFS= read -r exclude; do
      # echo "checking for exclude $exclude"
      if grep -q "<artifactId>$exclude<\/artifactId>" "$file"; then
        # echo "pom contains exclude ($exclude) for $artifactId, ignoring"
        return 0  # zero means true in bash if statements
      fi
    done < "$excludeFile"
  fi
  return 1 # not excluded
}

# works for distinct plugins
# but what about surefire plugin where its configured differently for certain projects?
# could have a subdir: /java, /groovy
# can just exclude surefire for groovy for now
# this doesn't work for the <spring.profiles.active>test</spring.profiles.active>
# as it affects many lib projects
# the beam projects also have a different surefire config, but that could be handled by an exclusion
# what about repeating the surefire plugin:
# maven-surefire-plugin.xml.1
# maven-surefire-plugin.xml.2
# with each one having different excludes so only one gets selected
# once one is selected, it stops looking at the others
# is there an exclude for libs? spring-boot-maven-plugin
function selectTemplate() {
  local artifactId="$1"
  local file="$2"

  # if there are no exclude files, then suffix is "0"
  if ! compgen -G "$SCRIPT_PATH/templates/${artifactId}.exclude.*" > /dev/null; then
    echo 0
  fi

  # TODO iterate in alphabetical order
  # XXX ignore plugins in pluginManagement
  sed -E '/<pluginManagement>/,/<\/pluginManagement>/d' "$file" > "${file}.excl"
  for excludeFile in $SCRIPT_PATH/templates/${artifactId}.exclude.*; do
    suffix="${excludeFile##*.}"
    if ! isExcluded $artifactId $suffix "${file}.excl"; then
      echo $suffix
      rm -f "${file}.excl"
      return
    fi
  done
  rm -f "${file}.excl"
}

function insertMultiline() {
  local tag="$1"
  local artifactId="$2"
  # insert \1 at beginning of each line so the indentation is preserved
  local newContent=$(cat "$3")
  newContent="${newContent//\//\\/}"
  newContent="\1${newContent//$'\n'/\\$'\n'\\1}"
  local file="$4"
#  echo "$newContent"
  sed "${SED_OPTIONS[@]}" '
/<pluginManagement>/,/<\/pluginManagement>/be
/<profiles>/,/<\/profiles>/be
/<'"$tag"'>$/{
  :b
  /<'"$tag"'>.*<\/'"$tag"'>$/!{N;bb
  }
  /<'"$tag"'>.*<artifactId>'"$artifactId"'<\/artifactId>/{s/^([[:space:]]*)<'"$tag"'>.*/\0\n'"$newContent"'/
  }
}
:e
' "$file"
  rm "${file}.bak"
}

function appendMultiline() {
  local tag="$1"
  # insert \1 and an extra indent level at beginning of each line so the indentation is preserved
  local newContent=$(cat "$2")
  newContent="${newContent//\//\\/}"
  newContent="\1    ${newContent//$'\n'/\\$'\n'\\1    }"
  local file="$3"
#  echo "$newContent"
  sed "${SED_OPTIONS[@]}" '
/<pluginManagement>/,/<\/pluginManagement>/be
/<profiles>/,/<\/profiles>/be
s/^([[:space:]]*)<\/'"$tag"'>.*/'"$newContent"'\n\0/
:e
' "$file"
  rm "${file}.bak"
}

# TODO ignore profile property blocks
function insertProperty() {
  local key="$1"
  local value="$2"
  local file="$3"
  value="${value//\//\\/}"

  sed "${SED_OPTIONS[@]}" 's/([[:space:]]*)<\/properties>/\1\1<'"$key"'>'"$value"'<\/'"$key"'>\n\0/' "$file"
  rm "${file}.bak"
}

mandatory=('maven-compiler-plugin' 'maven-surefire-plugin' 'maven-checkstyle-plugin' 'maven-pmd-plugin' 'spotbugs-maven-plugin' 'sonar-maven-plugin' 'maven-enforcer-plugin' 'maven-source-plugin')
findPreviousMandatory() {
  local plugin="$1"
  local previous='MANDATORY_BUT_NO_PREVIOUS'
  local e
  for e in "${mandatory[@]}"; do
    if [ "$e" == "$plugin" ]; then
      echo "$previous"
      return
    fi
    previous="$e"
  done
}

ordered=("${mandatory[@]}")
# use .0 suffix as only want one entry per plugin
for template in $SCRIPT_PATH/templates/*.xml.0; do
  artifactId="${template%%.*}"     # remove .xml.0
  artifactId="${artifactId##*/}"   # remove path to leave file name
  previous=$(findPreviousMandatory "$artifactId")
  if [ "$previous" = "" ]; then
    ordered+=("$artifactId")
  fi
done
echo "processing plugins in order: ${ordered[*]}"

echo >> $SCRIPT_PATH/description.txt
for artifactId in "${ordered[@]}"; do
  echo "processing plugin template $artifactId"
  echo -n "."

  # it could be excluded, or it could be a selection by the suffix: ".1"
  # could give all the templates a suffix: ".0"
  # that means if selectTemplate return "", its excluded
  suffix=$(selectTemplate "${artifactId}" "$f")
  if [ "$suffix" == "" ]; then
    echo "no suffix, ignoring"
    continue
  fi
  echo "found suffix: ${suffix}"

  template="$SCRIPT_PATH/templates/${artifactId}.xml.$suffix"
  if ! cat "$f" | sed -E '/<pluginManagement>/,/<\/pluginManagement>/d;/<profiles>/,/<\/profiles>/d' | grep -q "<artifactId>$artifactId<\/artifactId>"; then
    #echo "missing $artifactId"
    # starting from this plugin, look for previous mandatory plugin
    # insert after that
    previous=$(findPreviousMandatory "$artifactId")
    # what if previous mandatory plugin is not present in pom?
    # it will try to insert after, but will not work since its not there
    # perhaps could iterate through mandatory templates first (and in order)
    # then if the first mandatory template doesn't exist, it will be appended
    # then the others will work off that one
    # build list of templates, remove mandatory from the list
    # append remaining to the mandatory list
    if [ "$previous" = "MANDATORY_BUT_NO_PREVIOUS" ]; then
      echo "couldn't find previous mandatory plugin, appending to end of plugins block"
      appendMultiline 'plugins' "$template" "$f"
      echo "$artifactId" >> $SCRIPT_PATH/description.txt
    elif [ "$previous" != '' ]; then
      echo "inserting after $previous"
      insertMultiline 'plugin' "$previous" "$template" "$f"
      echo "$artifactId" >> $SCRIPT_PATH/description.txt
    else
      echo "non-mandatory plugin, ignoring"
      continue
    fi
  else
    if replaceMultiline 'plugin' "$artifactId" "$template" "$f"; then
      echo "updated $artifactId"
      echo "$artifactId" >> $SCRIPT_PATH/description.txt
    fi
  fi

  propsFile="$SCRIPT_PATH/templates/${artifactId}.properties.$suffix"
  if [ -f "$propsFile" ]; then
    echo "checking property file: $propsFile"
    # TODO doesn't work if last line doesn't have a line feed
    while IFS='=' read -r key value; do
      if ! grep -q "<$key>" "$f"; then
        echo "missing property: $key"
        insertProperty "$key" "$value" "$f"
      else
        echo "found property: $key" "$f"
#        updateProperty "$key" "$value"
      fi
    done < "$propsFile"
  fi

  # also insert or update the properties for the plugin
  # for each property
  # if it exists, replace it
  # if not, append to end of properties block
done

# clean up the replacement
#sed "${SED_OPTIONS[@]}" '/TO_BE_DELETED_AFTER/d' "$f"

# might be easier to replace the whole plugin block
# but then need to detect the project type - jar or app
# also need to exclude profile section, but that applies to any approach
# there a few different types of projects
# - jar, jar-with-protobuf, jar-with-spring-boot
# - app-on-prem, app-gke
# replacing by plugin is more complex, but means replacement can be applied to different project types

# TODO mention which plugins were updated in the pr title/description
# Match indentation level with level in destination file
#   can match indent from first tag, but how to get that into replacement?
#   perhaps could update the replacement file before inserting into the pom.xml
#   how to extract the indent from sed? would be a bit clunky. better to keep it in the same replacement.
# TODO version will go out of date, so either keep it updated or ignore the version from the template
# How to insert missing plugins?
#   which ones to insert?
#     can have a list of mandatory plugins
#   where to insert them?
#     if there is a list, insert after closest existing plugin in the list
# TODO reorder plugins to match an expected order
# TODO build-helper-maven-plugin in raven-event-api has a custom setup
#   perhaps can have an exclude list
#   or could have some kind of autodetect - eg: if project contains protobuf
#   protobuf-maven-plugin

# TODO spring.profiles.active only makes sense for spring boot projects
# could be application or lib
# how to handle this?
# different set of plugins for spring-boot?
# what about using the exclude?
# exclude is for the whole plugin
