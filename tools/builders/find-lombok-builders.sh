#!/usr/bin/env bash

shopt -s nullglob
shopt -s globstar
# setopt extended_glob

files="$1"
excludeFilter="$2"

# what if the builder class is in a library?
# could clone the project or download the source jar
# or could accept a list of known builder classes

# find private final fields that don't have a value
# could also include public and others
# TODO gather fields in parent classes
# TODO ensure fields of nested classes are excluded
function findBuilderClassFields() {
  local f=$1
  local c=$2

  beginning='class[[:space:]]+'"$c"'[^0-9A-Za-z_$£]'
  ncb="[^{}]*"           # no bracket
  mcb="($ncb|\{$ncb\})*" # matched bracket - level 1
  mcb="($ncb|\{$mcb\})*" # matched bracket - level 2
  # TODO support more levels
  mab='[^<>;]*(<[^<>;]*>)?'

  # remove annotations first so they dont interfere
  # remove multiline comments
  sed -E '
  /[/][*]/{
  :b
  /[/][*].*[*][/]/!{N;bb
  }
  d
}' $f | sed -E '/@[0-9A-Za-z_$£]+/d' | sed -E -n '
/'"$beginning"'/{
  :b
  /'"$beginning"'[^{}]*\{'"$mcb"'\}/!{N;bb
  }
  s/[[:space:]]+(private|protected|public|)[[:space:]]*(final|)[[:space:]]+[0-9A-Za-z_$£]+'"$mab"'[[:space:]]+([0-9A-Za-z_$£]+);/±\4±/gp
}' | tr -d '\n' | sed -E 's/^[^±]*±(.*)±[^±]*$/\1/' | sed -E 's/±±/ /g'
}

function findBuilderClasses() {
  local f=$1

  beginning='@(Super)?Builder'
  mc='[[:space:]]+class[[:space:]]+'

  sed -E -n '
/'"$beginning"'/{
  :b
  /.*'"$beginning"'.*'"$mc"'/!{N;bb
  }
  s/^.*[[:space:]]+class[[:space:]]+([0-9A-Za-z_]+).*$/\1/p
}' "$f"
}

function extractPackageAndClass() {
  local f=$1
  ff="${f%.*}"      # remove .java
  c="${ff##*/}"     # remove path to leave class name
  p="${ff%/*}"      # remove file name to leave path
  p="${p##*java/}"  # remove src/main/java
  p="${p//\//.}"    # convert path to package

  # find all the @Builder/@SuperBuilder annotated classes
  # XXX only works for one level of nested classes
  # for multiple levels, need to capture the wrapper class to build the hierarchy
  classes=($(findBuilderClasses "$f"))
  for fc in "${classes[@]}"; do
    if [ "$fc" = "$c" ]; then
      fields=($(findBuilderClassFields "$f" "$c"))
      echo "$p $c" "${fields[@]}"
    else
      fields=($(findBuilderClassFields "$f" "$fc"))
      # nested class can be referenced in two ways
      echo "$p $c.$fc" "${fields[@]}"
      echo "$p.$c $fc" "${fields[@]}"
    fi
  done
}

for f in $files; do
#for f in src/main/java/com/hsbc/host/raven/foxvamarketdata/funding/MidRates.java; do
#for f in src/main/java/com/hsbc/host/raven/foxvamarketdata/model/curve/TenorPoint.java; do
#for f in src/main/java/com/hsbc/host/raven/foxvamarketdata/upload/MarketDataUploadResponse.java; do
#for f in src/main/java/com/hsbc/host/raven/foxvamarketdata/model/curve/historical/DateFixing.java; do
  if [ "$excludeFilter" != "" ] && grep -Eq "$excludeFilter" "$f"; then
    continue
  fi

  if grep -Eq 'import[[:space:]]+lombok.Builder' "$f" && grep -Eq '@Builder' "$f"; then
    extractPackageAndClass "$f"
    continue
  fi

  if grep -Eq 'import[[:space:]]+lombok.experimental.SuperBuilder' "$f" && grep -Eq '@SuperBuilder' "$f"; then
    extractPackageAndClass "$f"
    continue
  fi
done

# return package and class so static inner classes can also be returned

#@Data
#@NoArgsConstructor
#@AllArgsConstructor
#@Builder(toBuilder = true, setterPrefix = "with")
#public class CopyStorageRequest {

#com.hsbc.host.raven.gcpservicespringbootstarter.storage.CopyStorageRequest

#    @Data
#    @NoArgsConstructor
#    @AllArgsConstructor
#    @Builder(toBuilder = true, setterPrefix = "with")
#    public static class CopyFileAttribute {

#com.hsbc.host.raven.gcpservicespringbootstarter.storage.CopyStorageRequest.CopyFileAttribute

#        CopyStorageRequest.CopyFolderAttribute ca2 = CopyStorageRequest.CopyFolderAttribute.builder()
#                .withLocalPath(root + "/input1")
#                .withRemotePath("gs://bucket/input1")
#                .withIncludePatterns(Lists.newArrayList("deals\\.csv", "config\\.csv"))
#                .build();
#        CopyStorageRequest request = CopyStorageRequest.builder()
#                .withFiles(Lists.newArrayList(ca1))
#                .withFolders(Lists.newArrayList(ca2))
#                .build();
