#!/usr/bin/env bash

set -u   # crash on missing env variables
set -e   # stop on any error
set -x

# Run from project root
test ! -d scripts && echo "scripts dir not found in $PWD, exiting..." && exit 1

# Write cert file from env var
echo -e "$IIIF_IMAGE_SERVER_WABO_CERT" > /tmp/sw444v1912.pem

sleep 600  # For debugging stunnel on acc
# Start stunnel
if [ "$START_STUNNEL" = false ] ; then
    echo "## NOT starting stunnel"
else
    echo "## Starting stunnel"
    stunnel /app/cantaloupe/scripts/stunnel.conf
fi


echo "Starting cantaloupe"
exec java -Dcantaloupe.config=/app/cantaloupe/cantaloupe.properties -Xmx2g -jar /usr/local/cantaloupe/cantaloupe-${CANTALOUPE_VERSION}.war  \
    2>&1 | tee /var/log/cantaloupe/cantaloupe.log

## Command to start cantaloupe with debug options
#exec java -Dcantaloupe.config=/app/cantaloupe/cantaloupe.properties -Xmx2g "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005" -jar /usr/local/cantaloupe/cantaloupe-${CANTALOUPE_VERSION}-SNAPSHOT.war  \
#    2>&1 | tee /var/log/cantaloupe/cantaloupe.log
