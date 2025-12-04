#!/bin/bash

SCRIPT_PATH=$(dirname "$0")

for path in $(find . -path '*src/test/java'); do
  grep -rq 'extends TypeSafeMatcher' $path
  if [ $? -eq 0 ]; then
    echo 'copying MatchingConsumer over'
    mkdir -p $path/com/hsbc/contact/
    cp $SCRIPT_PATH/src/*.java $path/com/hsbc/contact/
  fi
done
