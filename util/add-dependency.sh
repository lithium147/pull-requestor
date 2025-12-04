#!/usr/bin/env bash

SCRIPT_PATH=$(dirname "$0")

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i)
case "$(uname)" in
Darwin*) SED_OPTIONS=(-i '') ;;
esac

f=$1
groupId=$2
artifactId=$3
version=$4
scope=$5

function exitIfAlreadyHasDependency() {
  # TODO check groupId and artifactId are for the same <dependency>
  grep -q "$groupId" "$f"
  if [ $? -ne 0 ]; then
    return
  fi
  grep -q "$artifactId" "$f"
  if [ $? -ne 0 ]; then
    return
  fi
  exit
}

exitIfAlreadyHasDependency

# add the dependency before </dependencies>
# but only on the top level </dependencies> section
# if section doesn't exist add it
# how to find the top level </dependencies> ?
# could use the indentation, but that's not precise

#<...> - level++
#</...> - level--

# could produce a line mapped file, then
#   remove comment blocks
#   join wrapped lines
#   add the nesting level
# find line with expect level and tag
#   extract the original line number from that mapped line


lineNum=$(awk -v tag='</dependencies>' -f $SCRIPT_PATH/find-tag.awk "$f")
if [ "$lineNum" == "" ]; then
  echo "could not find </dependencies> tag, dependency not added: $groupId:$artifactId"
  exit
fi
if [ $lineNum -le 0 ]; then
  echo "could not find </dependencies> tag, dependency not added: $groupId:$artifactId"
  exit
fi
let lineNum=lineNum-1
#echo "found tag at lineNum: $lineNum"

echo -n '' > dependency.xml
echo '        <dependency>' >> dependency.xml
echo "            <groupId>$groupId</groupId>" >> dependency.xml
echo "            <artifactId>$artifactId</artifactId>" >> dependency.xml
echo "            <version>$version</version>" >> dependency.xml
echo "            <scope>$scope</scope>" >> dependency.xml
echo '        </dependency>' >> dependency.xml

sed "${SED_OPTIONS[@]}" "${lineNum}r dependency.xml" "$f"

rm -f dependency.xml
