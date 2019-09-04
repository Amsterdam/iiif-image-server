#!/usr/bin/env bash

set -u   # crash on missing env variables
set -e   # stop on any error
set -x

# Run from project root
test ! -d scripts && echo "scripts dir not found in $PWD, exiting..." && exit 1

echo "Starting gatekeeper"
keycloak-gatekeeper --config /app/gatekeeper/gatekeeper-config.yaml 2>&1 | tee /var/log/gatekeeper/gatekeeper.log &

echo "Starting cantaloupe"
exec java -Dcantaloupe.config=/app/cantaloupe/cantaloupe.properties -Xmx2g -jar /usr/local/cantaloupe/cantaloupe-4.1-SNAPSHOT.war  \
    2>&1 | tee /var/log/cantaloupe/cantaloupe.log
