#!/bin/bash

# Function to read a property from a properties file
# function get_property {
    # local file=$1
    # local key=$2
    # local value=$(grep -w "$key" "$file" | cut -d'=' -f2)
    # echo $value
# }

# Path to the properties file
PROPERTIES_FILE="ords_params.properties"

# Read values from the properties file
BASE_IMAGE=oracle/database:19.3.0-ee
DB_HOST=192.168.112.1
DB_PORT=1521
DB_SERVICENAME=DEV
ORDS_ADMIN_USER=SYS
ORDS_DB_API=true
ORDS_REST_ENABLED_SQL=true
ORDS_SDW=true
ORDS_GATEWAY_MODE=proxied
ORDS_GATEWAY_USER=APEX_PUBLIC_USER
ORDS_PROXY_USER=true
ORDS_PASSWORD_SYS=SysPassw0rd
ORDS_PASSWORD_APEX=ApexPassw0rd

# Build the Docker image with the build arguments
docker build --build-arg BASE_IMAGE=$BASE_IMAGE \
             --build-arg DB_HOST=$DB_HOST \
             --build-arg DB_PORT=$DB_PORT \
             --build-arg DB_SERVICENAME=$DB_SERVICENAME \
             --build-arg ORDS_ADMIN_USER=$ORDS_ADMIN_USER \
             --build-arg ORDS_DB_API=$ORDS_DB_API \
             --build-arg ORDS_REST_ENABLED_SQL=$ORDS_REST_ENABLED_SQL \
             --build-arg ORDS_SDW=$ORDS_SDW \
             --build-arg ORDS_GATEWAY_MODE=$ORDS_GATEWAY_MODE \
             --build-arg ORDS_GATEWAY_USER=$ORDS_GATEWAY_USER \
             --build-arg ORDS_PROXY_USER=$ORDS_PROXY_USER \
             --build-arg ORDS_PASSWORD_SYS=$ORDS_PASSWORD_SYS \
             --build-arg ORDS_PASSWORD_APEX=$ORDS_PASSWORD_APEX \
             -t ords:latest .
