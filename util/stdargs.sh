#!/usr/bin/env bash

totalProcessed=0
totalUpdated=0
maxFilesAffected=0
maxFilesProcessed=0

for i in "$@"; do
  case $i in
    --maxFilesAffected=*)
      maxFilesAffected="${i#*=}"
      shift
      ;;
    --maxFilesProcessed=*)
      maxFilesProcessed="${i#*=}"
      shift
      ;;
    --files=*)
      files="${i#*=}"
      shift
      ;;
    --*)
      echo "Unknown option $i"
      exit 1
      ;;
    *)
      ;;
  esac
done
