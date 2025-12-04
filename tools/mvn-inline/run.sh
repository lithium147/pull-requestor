#!/usr/bin/env bash

# assume all scripts are in the source dir
SCRIPT_PATH=$(dirname "$0")
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

sed -E -n "/<properties>/,/<\/properties>/{s/<\!--.*-->//;s/<\/[^>]*>//;s/.*<//;s/>/:/p}" pom.xml | grep version | grep -v 'java.version' | tee nameAndVersionArr.txt
propVersionCountArr=($(wc -l nameAndVersionArr.txt))
propVersionCount=${propVersionCountArr[0]}
nameAndVersionArr=($(cat nameAndVersionArr.txt))
rm -f nameAndVersionArr.txt
echo "Properties to inline: $propVersionCount"
inlined=0
firstLineNum=0

for nameAndVersion in ${nameAndVersionArr[@]}; do
  echo "checking property version: $nameAndVersion"

  parts=(${nameAndVersion//:/ })
  propName=${parts[0]}
  version=${parts[1]}
  artifactId=${propName%.version}  # remove '.version' from prop name

  occurrences=$(grep -c '${'"$propName"'}' pom.xml)
  if [ $occurrences -gt 1 ]; then
    echo "ignoring $propName since it occurs more than once"
    if [ $firstLineNum -eq 0 ]; then
      # track the first property for placement of the comment
      firstLineNum=$(grep -n "<${propName}>" pom.xml | head -n 1 | sed 's/:.*//')
    fi
    continue
  fi

  $SCRIPT_PATH/inline-property.sh pom.xml "$artifactId" "$version"

  inlined=$((inlined + 1))
done

if [ $inlined -gt 0 ]; then
  comment=$(cat $SCRIPT_PATH/description.txt)
  comment="<!-- $comment -->"
  echo "inserting comment at line $firstLineNum - $comment"

  sed "${SED_OPTIONS[@]}" "${firstLineNum}{s/^(\s*)(<.*>)/\1${comment}\n\1\2/}" pom.xml
fi

# title used for both commit message and pr title
title="mvn-inline $inlined of $propVersionCount properties removed"

# since already have description.txt, can follow a similar approach
echo $title > $SCRIPT_PATH/title.txt
