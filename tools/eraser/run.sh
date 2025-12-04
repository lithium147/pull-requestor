#!/usr/bin/env bash

shopt -s nullglob
shopt -s globstar
setopt extended_glob

SCRIPT_PATH=$(dirname "$0")
UTIL_PATH=$(dirname "$0")/../util

source="$1"
echo "erasing '$source'"

$SCRIPT_PATH/erase.sh "$source"
