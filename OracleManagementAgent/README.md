# Oracle Management Agent Container Image

This repository contains sample container configurations to facilitate installation and environment setup for DevOps users. This project includes Dockerfiles based on Oracle Linux and Oracle OpenJDK 8.

The certification of Oracle Management Agent in a container does not require the use of any file presented in this
repository. Customers and users are welcome to use them as starters, and customize/tweak, or create
from scratch new scripts and Dockerfiles.
<!-- markdownlint-disable MD013 -->
**Note: The latest container files no longer require elevated privileges that were used to create a local system account in order to run the Oracle Management Agent and run the daemon process. The operator can now opt to create user accounts during image development (in Dockerfile) or at runtime they can simply provide the numeric UID and GID values that belong to a user found in the environment that hosts the container.**
<!-- markdownlint-enable MD013 -->
## How to build and run

Oracle Management Agent image uses the official `oraclelinux:8-slim` container image as the base image.

## Prerequisites

1. [Download the Management Agent software](https://cloud.oracle.com/macs)

    **Note: Select 'Downloads and Keys' then download 'Agent for LINUX (X86_64)' of the package type ZIP.**

1. Copy the downloaded bundle to the same directory as the `Dockerfile`

    ```shell
    # stage install bundle
    $ cp oracle.mgmt_agent.zip OracleManagementAgent/dockerfiles/latest/
    ```

1. Change to the directory in which the `Dockerfile` for this container image is located

    ```shell
    # to build and run container from this location
    $ cd OracleManagementAgent/dockerfiles/latest/
    ```
<!-- markdownlint-disable MD013 -->
1. Follow the steps in the [Create Install Key](https://docs.oracle.com/en-us/iaas/management-agents/doc/management-agents-administration-tasks.html#GUID-C841426A-2C32-4630-97B6-DF11F05D5712) and [Configure a Response File](https://docs.oracle.com/en-us/iaas/management-agents/doc/install-management-agent-chapter.html#GUID-5D20D4A7-616C-49EC-A994-DA383D172486) sections of the [Management Agent](https://docs.oracle.com/en-us/iaas/management-agents/index.html) documentation to create an install key and save it locally as `input.rsp` in the current directory.
<!-- markdownlint-enable MD013 -->
1. Create a bind mount location to persist container data

    ```shell
    # Important: cleanup any old state files
    $ rm -rf /home/$USER/oracle
    $ mkdir -p /home/$USER/oracle
    ```

1. Ensure your tenancy is configured correctly by [applying the documented prerequisites for deploying management agents](https://docs.oracle.com/en-us/iaas/management-agents/doc/perform-prerequisites-deploying-management-agents.html)

## Steps to build and run using Docker Compose

1. Create .env file to populate the environment variables

    ```shell
    # required environment settings
    $ echo "mgmtagent_hostname=mgmtagent912" > .env
    $ echo "DOCKER_BASE_DIR=$(/home/$USER/oracle)" >> .env
    $ echo "USERID=$(id -u)" >> .env
    $ echo "GROUPID=$(id -g)" >> .env
    ```

    **Notes:**

    * `USERID` is the numeric identifier assigned by Linux to each user, found by running `id -u <username>`
    * `GROUPID` is the numeric identifier assigned by Linux to each user group, found by running `id -g <username>`
    * Validate the `USERID` and `GROUPID` values are correct as having incorrect values can result in failure. Refer to the troubleshooting section on this page for specific examples of failure.
    * Choose a unique hostname as it will be used to identify Management Agent in the UI.

1. Use Docker Compose CLI to build and run a container image

    ```shell
    # build and start container
    $ docker-compose up --build -d
    ```

## Steps to build and run using Docker CLI

1. Build the container image

    ```shell
    # build the container
    $ docker build -t oracle/mgmtagent-container .
    ```

1. Copy the Install Key (input.rsp) into the shared Docker volume Mountpoint

    ```shell
    # create the mgmtagent_secret location to stage the install key
    $ mkdir -p /home/$USER/oracle/mgmtagent_secret/
    $ cp input.rsp /home/$USER/oracle/mgmtagent_secret/
    ```

1. Start a container

    ```shell
    # set required environment values then start container
    $ export "USERID=$(id -u)"
    $ export "GROUPID=$(id -g)"
    $ docker run --user $USERID:$GROUPID -d --name mgmtagent-container --hostname mgmtagent1 -v /home/$USER/oracle/:/opt/oracle:rw --restart unless-stopped oracle/mgmtagent-container:latest
    ```

    **Notes:**
    * `USERID` is the numeric identifier assigned by Linux to each user, found by running `id -u <username>`
    * `GROUPID` is the numeric identifier assigned by Linux to each user group, found by running `id -g <username>`
    * Validate the `USERID` and `GROUPID` values are correct as having incorrect values can result in failure. Refer to the troubleshooting section on this page for specific examples of failure.
    * Choose a unique hostname as it will be used to identify Management Agent in the UI.

    <!-- markdownlint-disable MD036 -->
    **Description of Docker run parameters used above**
    <!-- markdownlint-enable MD036 -->
    <!-- markdownlint-disable MD033 -->
    | Parameter | Description |
    | --------- | ----------- |
    | --user | Run the container and Management Agent with the given user `USERID` and `GROUPID` values. |
    | -d | Start the container in detached mode. |
    | --name | The name given to the container to identify it. |
    | --hostname | Assign the container an internal hostname. This can be any hostname compliant string and it will be used to identify the Management Agent instance in the OMC Console. |
    | -v | Assign the bind mount on host filesystem to the location inside the container with Read/Write privileges. |
    | --restart unless-stopped | Unless explicitly stopped, this restart policy restarts mgmtagent-container automatically when docker restarts. |
    <!-- markdownlint-enable MD033 -->

1. Remove the Install Key (input.rsp) from the shared Docker volume Mountpoint after [verifying the new Management Agent is registered and visible in the main Management Agents page](https://docs.oracle.com/en-us/iaas/management-agents/doc/install-management-agent-chapter.html#GUID-46BE5661-012E-4557-B679-6456DBBEAA4A)

    ```shell
    # remove install key after install
    $ rm  /home/$USER/oracle/mgmtagent_secret/input.rsp
    ```

## Steps to execute custom user operations

Users can provide custom shell script commands to execute before starting Management Agent as described in the following steps

1. Refer to [init-agent.sh](dockerfiles/latest/user-scripts/init-agent.sh) in the user-scripts directory

    Modify the script `init-agent.sh` to add custom commands that execute each time before Management Agent starts

1. Follow the steps to build and run a container and validate the output of `init-agent.sh` script is visible in the logs by running the following command

    ```shell
    # inspect container output logs
    $ docker logs mgmtagent-container
    ```

## Troubleshooting

Solutions to common issues when running Management Agent in a container are described in the following steps

1. mkdir: cannot create directory '/opt/oracle/bootstrap': Permission denied

    * Ensure the mounted volume exists and is accessible by the user used to run the container
    * Verify the user USERID and GROUPID used match the permissions set on the mounted bind volume
    * Verify the mounted bind volume exists on the host

1. Invalid argument: /opt/oracle/mgmtagent_secret/input.rsp

    * Ensure the install key exists at the required location

1. Management Agent registration failures due to old state files from a prior install
<!-- markdownlint-disable MD013 -->
<!-- markdownlint-disable MD046 -->
    * Once a Management Agent instance is deregistered that instance must be shutdown and any associated state files must be removed from the filesystem. Starting a deregistered Management Agent instance again can result in unregistered agent failures. This situation can present itself when old state files from a prior installation are present on the filesystem and made available to a new Management Agent container deployment. Run the command given below on the host filesystem to perform the necessary cleanup on the bind mount location and perform the deployment again starting at the prerequisites step.

    ```shell
    # cleanup old files from prior installation
    $ rm -rf /home/$USER/oracle/
    ```
<!-- markdownlint-enable MD046 -->
<!-- markdownlint-enable MD013 -->

## Helpful commands

1. Starting a stopped Management Agent Container

    ```shell
    # start container and agent
    $ docker start mgmtagent-container
    ```

1. Stopping a running Management Agent Container

    ```shell
    # stop container and agent
    $ docker stop mgmtagent-container
    ```

1. Inspecting logs of Management Agent Container

    ```shell
    # inspect container and agent install logs
    $ docker logs mgmtagent-container
    ```

1. Gathering UID and GID of a user from the host environment

    ```shell
    # see creating a user account below
    $ id -u <username> # prints UID of user
    $ id -g <username> # prints GID of user
    ```

1. Creating a named user account during image development (optional)

    ```shell
    # Commands given below can use used to precreate a user account in container image

    $ groupadd -g <numeric-gid-value> <desired-groupname> # create group with gid
    # example:
    $ groupadd -g 9100 agentadmingrp

    $ useradd <desired-username> -u <numeric-uid-value> -g <numeric-gid-value> -m -s /bin/bash # create user with uid/gid
    # example:
    $ useradd agentadminusr -u 9200 -g 9100 -m -s /bin/bash

    # Note: Add useradd/groupadd to Dockerfile prefixed with the RUN directive to create user during image development
    ```

## Container Files for Older Releases

The Oracle Management Agent older container files mentioned below are no longer actively maintained and they are kept in this repository for historical purposes only.

* Oracle Management Agent container files version 1.0.0 [`docker-images/OracleManagementAgent/dockerfiles/1.0.0`](./dockerfiles/1.0.0)

**Notes:**

* Oracle Management Agent container files version 1.0.0 require elevated privileges to run and therefore are not compatible with the latest version found in this repository. Upgrading a version 1.0.0 container to run with the latest container files is also not supported for the same reason.

## License

To download and run the Oracle Management Agent, regardless whether inside or outside a container, you must download the binaries from the Oracle website and accept the license indicated at that page.

Oracle Linux is licensed under the [Oracle Linux End-User License Agreement](https://oss.oracle.com/ol/EULA).

All scripts and files hosted in this project and GitHub [`docker-images/OracleManagementAgent`](./) repository, required to build the Docker images are, unless otherwise noted, released under the [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Support

Oracle Management Agent container image is supported for the Linux images listed [here](https://docs.oracle.com/en-us/iaas/management-agents/doc/perform-prerequisites-deploying-management-agents.html#GUID-BC5862F0-3E68-4096-B18E-C4462BC76271). For more details please see My Oracle Support.

## Copyright

Copyright (c) 2022 Oracle and/or its affiliates.
