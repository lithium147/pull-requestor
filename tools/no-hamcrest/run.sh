#!/usr/bin/env bash

SCRIPT_PATH=$(dirname "$0")

#git checkout .

$SCRIPT_PATH/hamcrest-assertions/migrate.sh
$SCRIPT_PATH/hamcrest-matchers/migrate.sh
$SCRIPT_PATH/delete-hamcrest-dependency.sh
