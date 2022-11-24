
# Oracle Tuxedo `bankapp` Sample Container Image

This sample extends the Oracle Tuxedo image by creating a "bankapp" application.

## Prerequisites

This image uses the Orace Tuxedo container image `oracle/tuxedo:latest` as its base. Please follow the [Oracle Tuxedo image](https://github.com/oracle/docker-images/tree/main/OracleTuxedo/core) documentation to build the container image before performing the operations described in this document.

## How to Build the Image

Download the parent directory (bankapp) of this README.md file from GitHub to a location of your choice. This location is referenced as `YOUR_APP_DIR` in this document.

```shell
export TUXDIR=<Tuxedo installation directory when the above mentioned `oracle/tuxedo:latest` image was built>
cp -rp ${TUXDIR}/samples/atmi/bankapp/*  &lt;YOUR_APP_DIR>/bankapp/

cd &lt;YOUR_APP_DIR>/bankapp
export APPDIR=$(pwd)

export LD_LIBRARY_PATH=${TUXDIR}/lib:$LD_LIBRARY_PATH
make -f bankapp.mk TUXDIR="${TUXDIR}" APPDIR="${APPDIR}"

docker build -t tuxedo-bankapp .
```

## How to Run the Image

Use the image built in the preceding section to create a container that runs the application with the following command:

```shell
docker run -d -p 5955:5955 tuxedo-bankapp
```

You can review the container logs by using the `docker logs <container_id>` command. The `container_id` can be found by running the `docker ps` command.

## How to Test the HTTP Client

You can test the HTTP client by running the following commands on the same box where you ran the `docker run` command as described in the preceding section.

```shell
TUX_HOSTNAME="127.0.0.1"

curl -v -X POST -H "Content-type:application/json" http://${TUX_HOSTNAME}:5955/INQUIRY    -d '{"ACCOUNT_ID":10000}'

curl -v -X POST -H "Content-type:application/json" http://${TUX_HOSTNAME}:5955/WITHDRAWAL -d '{"ACCOUNT_ID":10001,"SAMOUNT":"10"}'

curl -v -X POST -H "Content-type:application/json" http://${TUX_HOSTNAME}:5955/DEPOSIT    -d '{"ACCOUNT_ID":10001,"SAMOUNT":"1"}'

curl -v -X POST -H "Content-type:application/json" http://${TUX_HOSTNAME}:5955/TRANSFER   -d '{"ACCOUNT_ID":[10001,10002],"SAMOUNT":"1"}'

curl -v -X POST -H "Content-type:application/json" http://${TUX_HOSTNAME}:5955/ABAL       -d '{"b_id":10}' 
```

