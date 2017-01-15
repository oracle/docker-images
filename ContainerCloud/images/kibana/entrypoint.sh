#!/bin/sh

# Wait for the Elasticsearch container to be ready before starting Kibana.
echo "Stalling for Elasticsearch..."
while true; do
    nc -z elasticsearch 9200 && break
done

echo "Starting Kibana"
${KIBANA_HOME}/bin/kibana
