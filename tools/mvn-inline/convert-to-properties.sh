#!/usr/bin/env bash

# assume all scripts are in the source dir
SCRIPT_PATH=$(dirname "$0")

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-E -i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-E -i '')
esac

f="$1"  # file

function extractMultiline() {
  tag="$1"
  sed -E -n '
/<'"$tag"'>$/{
  :b
  /.*<'"$tag"'>.*<\/'"$tag"'>$/!{N;bb
  }
  '"$2"'
}' "$3"
}

function replaceMultiline() {
  tag="$1"
  sed "${SED_OPTIONS[@]}" '
/<'"$tag"'>$/{
  :b
  /.*<'"$tag"'>.*<\/'"$tag"'>$/!{N;bb
  }
  '"$2"'
}' "$3"
}


# convert dependencies to use properties
# for each dep
#   extract the version
#   replace with placeholder - artefactId.version
#   add to properties holder
# add all properties in holder to properties section
# What about repeat versions?
# These should already be properties
# How to restore to non-properties?
# Extract version, copy original file back, insert version
# Or reverse process of property extraction
# But need to remember which ones to leave in place

# Can set version in new property as 0
# how to hold the artifactId to use to create the property?

cp "$f" "$f.props"
# config block might have a version tag, eg:
#            <plugin>
#                <groupId>org.apache.maven.plugins</groupId>
#                <artifactId>maven-enforcer-plugin</artifactId>
#                <configuration>
#                    <rules>
#                        <dependencyConvergence/>
#                        <requireMavenVersion>
#                            <version>3.6.3</version>
#                        </requireMavenVersion>
#                    </rules>
#                </configuration>
#            </plugin>
# so exclude these
# these sections will not be in the final pom,
# but this is ok since its just being used to find updates

configBlockExclude='s/<configuration>(.*)<\/configuration>//'
executionBlockExclude='s/<executions>(.*)<\/executions>//'
dependencyBlockExclude='s/<dependencies>(.*)<\/dependencies>//'
propertyExtractor='/\$\{.*\}/!{s/.*<artifactId>(.*)<\/artifactId>.*<version>(.*)<\/version>.*/<\1.version>\2<\/\1.version>/p}'
# remove blocks first as they might have ${props} in them
pluginPropertyExtractor="${configBlockExclude}"';'"${dependencyBlockExclude}"';/\$\{.*\}/!{s/.*<artifactId>(.*)<\/artifactId>.*<version>(.*)<\/version>.*/<\1.version>\2<\/\1.version>/p}'
extractMultiline 'dependency' "$propertyExtractor" "$f.props" > "$f.extracted"
extractMultiline 'plugin' "$pluginPropertyExtractor" "$f.props" >> "$f.extracted"
extractMultiline 'extension' "$propertyExtractor" "$f.props" >> "$f.extracted"

propertyReplacer='/\$\{.*\}/!{s/<artifactId>(.*)<\/artifactId>(.*)<version>.*<\/version>/<artifactId>\1<\/artifactId>\2<version>${\1.version}<\/version>/}'
# ok to remove config block, but not dependency block
# how to ignore without removing?
# use [^<] as should not be another tag in between
# use [^$] so it doesn't touch existing properties
pluginPropertyReplacer="${executionBlockExclude}"';'"${configBlockExclude}"';{s/<artifactId>([^<]*)<\/artifactId>([^<]*)<version>[^<$]*<\/version>/<artifactId>\1<\/artifactId>\2<version>${\1.version}<\/version>/}'
replaceMultiline 'dependency' "$propertyReplacer" "$f"
replaceMultiline 'plugin' "$pluginPropertyReplacer" "$f"
replaceMultiline 'extension' "$propertyReplacer" "$f"

# insert props into right place
# <properties> could be in a profile block, so only update root section
# assume root properties section will appear first in the pom
# use grep to find first line number - grep output is like: 25: <properties>
lineNum=$(grep -n "<properties>" "$f" | head -n 1 | sed 's/:.*//')
sed "${SED_OPTIONS[@]}" "${lineNum}r $f.extracted" "$f"

rm -f "$f.props"
rm -f "$f.extracted"
