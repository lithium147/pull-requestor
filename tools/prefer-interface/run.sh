#!/usr/bin/env bash

SCRIPT_PATH=$(dirname "$0")

#git checkout .

$SCRIPT_PATH/run-list.sh
$SCRIPT_PATH/run-map.sh
$SCRIPT_PATH/run-set.sh
