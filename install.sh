#!/bin/bash

# Source the properties file
source ./config.properties
SCRIPT_DIR=$(dirname "$0")

# Function to create Docker network if it doesn't exist
create_docker_network() {
    if ! docker network ls --format '{{.Name}}' | grep -w $NETWORK_NAME > /dev/null; then
        echo "Creating Docker network: $NETWORK_NAME"
        docker network create $NETWORK_NAME
    else
        echo "Docker network $NETWORK_NAME already exists"
    fi || exit 1
}

# Function to clean up the temporary directory
cleanup_tmp_dir() {
    echo "Cleaning $TMP_DIR"
    if [ -d "$TMP_DIR" ]; then
        echo "Removing existing tmp directory: $TMP_DIR"
        rm -rf "$TMP_DIR"
    fi
}

# Function to build Oracle Database container image
build_oracle_image() {
    cd "$SCRIPT_DIR/OracleDatabase/SingleInstance/dockerfiles" || exit 1
    ./buildContainerImage.sh -v 19.3.0 -e || exit 1
    cd - || exit 1
}

# Function to run Oracle Database container
run_oracle_container() {
    docker run -d --name $ORACLE_CONTAINER --network=$NETWORK_NAME \
                 -p $DB_PORT:1521 \
                 -p 5500:5500 \
                 -p 2484:2484 \
                 --ulimit nofile=1024:65536 \
                 --ulimit nproc=2047:16384  \
                 --ulimit stack=10485760:33554432 \
                 --ulimit memlock=3221225472 \
                 -e ORACLE_SID=dev \
                 -e ORACLE_PDB=pdb1 \
                 -e ORACLE_PWD=$DB_PASSWORD \
                 -e INIT_SGA_SIZE=1000 \
                 -e INIT_PGA_SIZE=500 \
                 -e INIT_CPU_COUNT=4 \
                 -e INIT_PROCESSES=100 \
                 -e ORACLE_EDITION=enterprise \
                 -e ORACLE_CHARACTERSET=AL32UTF8 \
                 -e ENABLE_ARCHIVELOG=true \
                 -e ENABLE_FORCE_LOGGING=true \
                 -e ENABLE_TCPS=true \
                 -v /opt/oracle/oradata  \
     $ORACLE_IMAGE || exit 1
    sleep 1200
}

# Function to download and unzip APEX
download_apex() {
    cd "$SCRIPT_DIR/OracleApplicationExpress/dockerfiles" || exit 1
    cleanup_tmp_dir
    ./download_apex.sh "$APEX_URL" "$TMP_DIR" || exit 1
    cd - || exit 1
}

# Function to build and run APEX container
build_run_apex_container() {
    cd "$SCRIPT_DIR/OracleApplicationExpress/dockerfiles" || exit 1
    docker build --no-cache --build-arg BASE_IMAGE=$ORACLE_IMAGE -t $APEX_IMAGE . || exit 1
    docker run -d --name $APEX_CONTAINER --network $NETWORK_NAME \
                 -e DB_HOST=$DB_HOST \
                 -e DB_PORT=$DB_PORT \
                 -e DB_SERVICE=$DB_SERVICE \
                 -e DB_USER=$DB_USER \
                 -e DB_PASSWORD=$DB_PASSWORD \
    $APEX_IMAGE || exit 1
    cd - || exit 1
}

# Function to download and unzip ORDS
download_ords() {
    cd "$SCRIPT_DIR/OracleRestDataServices/dockerfiles" || exit 1
    cleanup_tmp_dir
    ./download_ords.sh "$ORDS_URL" "$TMP_DIR" || exit 1
    cd - || exit 1
}

# Function to build and run ORDS container
build_run_ords_container() {
    cd "$SCRIPT_DIR/OracleRestDataServices/dockerfiles" || exit 1
	./buildImage.sh || exit 1
    #docker build --no-cache --build-arg BASE_IMAGE=$ORACLE_IMAGE -t $ORDS_IMAGE . || exit 1
    docker run -d --name $ORDS_CONTAINER --network $NETWORK_NAME -p $ORDS_PORT:8080 $ORDS_IMAGE || exit 1
	

    cd - || exit 1
}

# Main script execution
create_docker_network
build_oracle_image
run_oracle_container
download_apex
build_run_apex_container
download_ords
build_run_ords_container

echo "Setup completed successfully."

