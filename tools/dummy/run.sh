#!/usr/bin/env bash

dummyFile=$(mktemp -p . dummy-XXX.txt)

git add $dummyFile
