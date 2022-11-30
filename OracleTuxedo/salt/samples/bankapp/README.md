# Oracle Tuxedo SALT bankapp sample application container image

This sample "bankapp" application extends the Oracle Tuxedo image.

## Prerequisites

This image uses the Oracle Tuxedo core container image `oracle/tuxedo:latest` as its base. Please follow the [Oracle Tuxedo image](https://github.com/oracle/docker-images/tree/main/OracleTuxedo/core) documentation to build the container image before performing the operations described in this document.

## How to build the image

To build the "bankapp" sample application, run:

```shell
docker build -t tuxedo-bankapp .
```

## Create and run a container from the image

Use the image built in the preceding section to create a container that runs the application with the following command:

```shell
docker run -d -p 5955:5955 tuxedo-bankapp
```

You can review the container logs by using the `docker logs <container_id>` command. The `container_id` can be found by running the `docker ps` command.

## How to test the application

You can test the application using the `curl` HTTP client using the following sample commands. These commands must be run on the same host upon which the container created above is running.

```shell
TUX_HOSTNAME="127.0.0.1"

curl -X POST -H "Content-type:application/json" http://${TUX_HOSTNAME}:5955/INQUIRY -d '{"ACCOUNT_ID":10000}'
```

The expected output is

```json
        "ACCOUNT_ID":   10000,
        "FORMNAM":      "CBALANCE",
        "SBALANCE":     "$1456.00"
```

```shell
curl -X POST -H "Content-type:application/json" http://${TUX_HOSTNAME}:5955/WITHDRAWAL -d '{"ACCOUNT_ID":10001,"SAMOUNT":"10"}'
```

The expected output is

```json
        "ACCOUNT_ID":   10001,
        "STATLIN":      " ",
        "FORMNAM":      "CWITHDRAW",
        "SBALANCE":     "$5568.00",
        "SAMOUNT":      "$10.00"
```

```shell
curl -X POST -H "Content-type:application/json" http://${TUX_HOSTNAME}:5955/DEPOSIT -d '{"ACCOUNT_ID":10001,"SAMOUNT":"1"}'
```

The expected output is

```json
        "ACCOUNT_ID":   10001,
        "BALANCE":      5569,
        "STATLIN":      "",
        "FORMNAM":      "CDEPOSIT",
        "SBALANCE":     "$5569.00",
        "SAMOUNT":      "$1.00"
```

```shell
curl -X POST -H "Content-type:application/json" http://${TUX_HOSTNAME}:5955/TRANSFER -d '{"ACCOUNT_ID":[10001,10002],"SAMOUNT":"1"}'
```

The expected output is

```json
        "ACCOUNT_ID":   [10001, 10002],
        "STATLIN":      "",
        "FORMNAM":      "CTRANSFER",
        "SBALANCE":     ["$5568.00", "$904.00"],
        "SAMOUNT":      "$1.00"
```

```shell
curl -X POST -H "Content-type:application/json" http://${TUX_HOSTNAME}:5955/ABAL -d '{"b_id":10}' 
```

The expected output is

```json
        "b_id": 10,
        "balance":      219216,
        "ermsg":        ""
```
