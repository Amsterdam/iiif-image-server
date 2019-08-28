#!/usr/bin/env bash
set -u   # crash on missing env variables
set -e   # stop on any error
set -x

# Run from project root
test ! -f "./Jenkinsfile" && echo "Jenkinsfile not found in $PWD, exiting..." && exit 1

docker-compose build tester
docker-compose up tester
