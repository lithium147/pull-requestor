#!/usr/bin/env bash

# symbol:   class Map(String)
symbolRegex='/symbol:/s/symbol:[[:space:]]+[A-Za-z0-9_]+[[:space:]]+([A-Za-z0-9_]+).*$/\1/p'
# error: package DependencyNames does not exist
errorRegex='/error: package.*does not exist/s/^.*error: package ([A-Za-z0-9_]+) does not exist$/\1/p'

# TODO only compile main/test based on where the class is located
./gradlew compileTestJava compileJava 2>&1 | sed -E -n -e "$symbolRegex" -e "$errorRegex" | sort -u
