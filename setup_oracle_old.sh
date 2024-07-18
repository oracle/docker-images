#!/bin/bash


# Get the directory where the script is located
SCRIPT_DIR=$(dirname "$0")

# Check if the Docker network exists
NETWORK_NAME="my-net"
if ! docker network ls --format '{{.Name}}' | grep -w $NETWORK_NAME > /dev/null; then
    echo "Creating Docker network: $NETWORK_NAME"
    docker network create $NETWORK_NAME
else
    echo "Docker network $NETWORK_NAME already exists"
fi || exit 1

# Change to the Oracle Database directory
cd "$SCRIPT_DIR/OracleDatabase/SingleInstance/dockerfiles" || exit 1

# Build the Oracle Database container image
./buildContainerImage.sh -v 19.3.0 -e || exit 1

# Run the Oracle Database container
docker run -d --name oracledb19.3 --network=my-net \
             -p 1521:1521 \
			 -p 5500:5500 \
			 -p 2484:2484 \
			 --ulimit nofile=1024:65536 \
			 --ulimit nproc=2047:16384  \
			 --ulimit stack=10485760:33554432 \
			 --ulimit memlock=3221225472 \
			 -e ORACLE_SID=dev \
			 -e ORACLE_PDB=pdb1 \
			 -e ORACLE_PWD=SysPassw0rd \
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
 oracle/database:19.3.0-ee 

sleep 1200

cd .. || exit 1
cd .. || exit 1
cd .. || exit 1
# Change to the Oracle REST Data Services directory
cd "OracleApplicationExpress/dockerfiles" || exit 1

# Download and unzip ORDS
./download_apex.sh "https://download.oracle.com/otn_software/apex/apex_24.1.zip" "$SCRIPT_DIR/tmp" || exit 1

# Build the ORDS Docker image
docker build --build-arg BASE_IMAGE=oracle/database:19.3.0-ee -t apex:24.1 . || exit 1

#Run the ORDS container
docker run -d --name apex24.1 --network my-net \
             -e DB_HOST=192.168.4.48 \
			 -e DB_PORT=1521 \
			 -e DB_SERVICE=DEV \
			 -e DB_USER=sys \
			 -e DB_PASSWORD=SysPassw0rd \
apex:24.1 || exit 1



cd .. || exit 1
cd .. || exit 1
# Change to the Oracle REST Data Services directory
cd "OracleRestDataServices/dockerfiles" || exit 1

# Download and unzip ORDS
./download_ords.sh "https://download.oracle.com/otn_software/java/ords/ords-24.2.2.187.1943.zip" "$SCRIPT_DIR/tmp" || exit 1

# Build the ORDS Docker image
docker build --build-arg BASE_IMAGE=oracle/database:19.3.0-ee -t ords:latest . || exit 1

# Run the ORDS container
docker run -d --name ords -p 8080:8080 ords:latest || exit 1

echo "Setup completed successfully."
