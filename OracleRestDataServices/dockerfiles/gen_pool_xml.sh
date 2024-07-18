#!/bin/bash

# Set the output file path
OUTPUT_FILE="/etc/ords/config/databases/default/pool.xml"

# Create the directory if it doesn't exist
mkdir -p $(dirname "$OUTPUT_FILE")

# Generate the pool.xml content
cat <<EOL > "$OUTPUT_FILE"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
<properties>
<comment>Saved on $(date)</comment>
<entry key="db.connectionType">basic</entry>
<entry key="db.hostname">192.168.4.48</entry>
<entry key="db.port">1521</entry>
<entry key="db.serviceNameSuffix"></entry>
<entry key="db.servicename">DEV</entry>
<entry key="db.username">ORDS_PUBLIC_USER</entry>
<entry key="feature.sdw">true</entry>
<entry key="plsql.gateway.mode">proxied</entry>
<entry key="restEnabledSql.active">true</entry>
<entry key="security.requestValidationFunction">ords_util.authorize_plsql_gateway</entry>
</properties>
EOL

# Verify the creation of the file
if [ -f "$OUTPUT_FILE" ]; then
  echo "pool.xml file has been successfully created at $OUTPUT_FILE"
else
  echo "Failed to create pool.xml file at $OUTPUT_FILE"
fi
