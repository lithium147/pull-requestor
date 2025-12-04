#!/usr/bin/env bash

shopt -s nullglob
shopt -s globstar
# setopt extended_glob

# what if the builder class is in a library?
# could clone the project or download the source jar
# or could accept a list of known builder classes

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
  for fc in ${classes[@]}; do
    if [ "$fc" = "$c" ]; then
      echo "$p $c"
    else
      echo "$p $c"
#       nested class can referenced in two ways
#      echo "$p $c.$fc"
#      echo "$p.$c $fc"
    fi
  done
}

for f in **/*.java; do
  # ignoring @Data and @Setter will mean there will be nothing left to change
#  if grep -Eq 'import[[:space:]]+lombok.Data' "$f" && grep -Eq '@Data' "$f"; then
#    # ignore @Data classes as these may have setters
#    continue
#  fi
#
#  if grep -Eq 'import[[:space:]]+lombok.Setter' "$f" && grep -Eq '@Setter' "$f"; then
#    # ignore @Setter classes as these may have mutable fields
#    continue
#  fi
  if grep -Eq 'import[[:space:]]+org.springframework.context.annotation.Configuration' "$f" && grep -Eq '@Configuration' "$f"; then
    # ignore @Configuration classes as these may have defaults
    continue
  fi

  grep -Eq 'import[[:space:]]+lombok.Builder' "$f" && grep -Eq '@Builder' "$f"
  if [ $? -eq 0 ]; then
    echo "$f"
#    extractPackageAndClass "$f"
    continue
  fi
  grep -Eq 'import[[:space:]]+lombok.experimental.SuperBuilder' "$f" && grep -Eq '@SuperBuilder' "$f"
  if [ $? -eq 0 ]; then
    echo "$f"
#    extractPackageAndClass "$f"
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
