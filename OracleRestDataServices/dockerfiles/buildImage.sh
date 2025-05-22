#!/bin/bash

# Source the properties file
source ../../config.properties

# Build the Docker image with the build arguments
docker build --no-cache --build-arg BASE_IMAGE=$ORACLE_IMAGE \
             --build-arg DB_HOST=$DB_HOST \
             --build-arg DB_PORT=$DB_PORT \
             --build-arg DB_SERVICE=$DB_SERVICE \
             --build-arg DB_USER=$DB_USER \
			 --build-arg DB_PASSWORD=$DB_PASSWORD \
             --build-arg ORDS_DB_API=$ORDS_DB_API \
             --build-arg ORDS_REST_ENABLED_SQL=$ORDS_REST_ENABLED_SQL \
             --build-arg ORDS_SDW=$ORDS_SDW \
             --build-arg ORDS_GATEWAY_MODE=$ORDS_GATEWAY_MODE \
             --build-arg ORDS_GATEWAY_USER=$ORDS_GATEWAY_USER \
             --build-arg ORDS_PROXY_USER=$ORDS_PROXY_USER \
             --build-arg ORDS_PASSWORD_SYS=$ORDS_PASSWORD_SYS \
             --build-arg ORDS_PASSWORD_APEX=$ORDS_PASSWORD_APEX \
             -t $ORDS_IMAGE .
