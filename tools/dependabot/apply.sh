#!/usr/bin/env bash

SCRIPT_PATH=$(dirname "$0")

# and the current dir is where the files to be modified are

$SCRIPT_PATH/install.sh

# this requires the code to be checked out

$SCRIPT_PATH/runOver.sh package.json npm_and_yarn
$SCRIPT_PATH/runOver.sh build.gradle gradle
$SCRIPT_PATH/runOver.sh Dockerfile docker
