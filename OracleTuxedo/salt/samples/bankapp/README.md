# Oracle Tuxedo SALT bankapp sample application container image

This sample "bankapp" application extends the Oracle Tuxedo image.

## Prerequisites

This image uses the Oracle Tuxedo core container image `oracle/tuxedo:22.1.0.0.0` as its base image. Please follow the [Oracle Tuxedo image documentation](https://github.com/oracle/docker-images/tree/main/OracleTuxedo/core) to build the base image before continuing.

## How to build the image

To build the "bankapp" sample application, run:

```shell
docker build -t tuxedo-bankapp .
```

## Create and run a container from the image

Run the following command to create a container that runs the application from the image built in the previous step:

```shell
docker run --name tuxedo-bankapp -d -p 5955:5955 tuxedo-bankapp
```

Run `docker logs tuxedo-bankapp` to see the logs from the running container. Add `-f` to the command to follow the logs then hit `CTRL+C` to stop following.

## How to test the application

You can test the application using the `curl` HTTP client using the following sample commands. Run these commands on the same host that's running the sample application container.

First, set `TUX_HOSTNAME` to use the loopback address:

```shell
export TUX_HOSTNAME="127.0.0.1"
```

To send an `INQUIRY` request for account ID 10000, run:

```shell
curl -X POST -H "Content-type:application/json" http://${TUX_HOSTNAME}:5955/INQUIRY -d '{"ACCOUNT_ID":10000}'
```

The expected output is

```json
{
        "ACCOUNT_ID":   10000,
        "FORMNAM":      "CBALANCE",
        "SBALANCE":     "$1456.00"
}
```

To withdraw funds from account 10001, run:

```shell
curl -X POST -H "Content-type:application/json" http://${TUX_HOSTNAME}:5955/WITHDRAWAL -d '{"ACCOUNT_ID":10001,"SAMOUNT":"10"}'
```

The expected output is

```json
{
        "ACCOUNT_ID":   10001,
        "STATLIN":      " ",
        "FORMNAM":      "CWITHDRAW",
        "SBALANCE":     "$5568.00",
        "SAMOUNT":      "$10.00"
}
```

To deposit funds into account 10001, run:

```shell
curl -X POST -H "Content-type:application/json" http://${TUX_HOSTNAME}:5955/DEPOSIT -d '{"ACCOUNT_ID":10001,"SAMOUNT":"1"}'
```

The expected output is

```json
{
        "ACCOUNT_ID":   10001,
        "BALANCE":      5569,
        "STATLIN":      "",
        "FORMNAM":      "CDEPOSIT",
        "SBALANCE":     "$5569.00",
        "SAMOUNT":      "$1.00"
}
```

To transfer funds from account 10001 to 10002, run:

```shell
curl -X POST -H "Content-type:application/json" http://${TUX_HOSTNAME}:5955/TRANSFER -d '{"ACCOUNT_ID":[10001,10002],"SAMOUNT":"1"}'
```

The expected output is

```json
{
        "ACCOUNT_ID":   [10001, 10002],
        "STATLIN":      "",
        "FORMNAM":      "CTRANSFER",
        "SBALANCE":     ["$5568.00", "$904.00"],
        "SAMOUNT":      "$1.00"
}
```

To obtain the total balance for the bank associated with branch id 10, run:

```shell
curl -X POST -H "Content-type:application/json" http://${TUX_HOSTNAME}:5955/ABAL -d '{"b_id":10}' 
```

The expected output is

```json
{
        "b_id":         10,
        "balance":      219216,
        "ermsg":        ""
}
```
