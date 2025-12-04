#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

SCRIPT_PATH=$(dirname "$0")

mv $SCRIPT_PATH/bin/google-java-format-*-all-deps.jar ${SCRIPT_PATH}/google-java-format-all-deps.jar

sort --version
#echo "LC_ALL=$LC_ALL"

#curl -L "https://github.com/google/google-java-format/releases/download/v1.10.0/google-java-format-1.10.0-all-deps.jar" > $SCRIPT_PATH/google-java-format-all-deps.jar

#if [ "$JAVA_HOME" = "" ]; then
#  export JAVA_HOME='/Library/Java/JavaVirtualMachines/jdk-11.0.7.jdk/Contents/Home'
#fi
#$JAVA_HOME/bin/java -jar $SCRIPT_PATH/google-java-format-all-deps.jar -v
