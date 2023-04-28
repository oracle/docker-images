# Oracle Management Agent Container Image

This repository contains sample container configurations of [Oracle Management Agent](https://docs.oracle.com/en-us/iaas/management-agents/index.html) to facilitate installation and environment setup for DevOps users. This project includes Dockerfiles based on Oracle Linux and Oracle OpenJDK 8.

The certification of Oracle Management Agent in a container does not require the use of any file presented in this
repository. Customers and users are welcome to use them as starters, and customize/tweak, or create
from scratch new scripts and Dockerfiles.

> Note: The Oracle Management Agent container image no longer requires elevated privileges. You can now chose to create a new user for the agent when building the image or at runtime by providing the UID and GID values of an existing user account on the host system.

## How to build and run

Oracle Management Agent image uses the official `oraclelinux:8-slim` container image as the base image.

## Prerequisites

1. [Download the Oracle Management Agent software](https://cloud.oracle.com/macs)

    > Note: Select 'Downloads and Keys' then download 'Agent for LINUX (X86_64)' of the package type ZIP.

1. Copy the downloaded bundle to the same directory as the `Dockerfile`

    ```shell
    cp oracle.mgmt_agent.zip OracleManagementAgent/dockerfiles/latest/
    ```

1. Change to the directory in which the `Dockerfile` for this container image is located

    ```shell
    cd OracleManagementAgent/dockerfiles/latest/
    ```

1. Follow the steps in the [Create Install Key](https://docs.oracle.com/en-us/iaas/management-agents/doc/management-agents-administration-tasks.html#GUID-C841426A-2C32-4630-97B6-DF11F05D5712) documentation to download the install key.
Next, follow the steps to [Configure a Response File](https://docs.oracle.com/en-us/iaas/management-agents/doc/install-management-agent-chapter.html#GUID-5D20D4A7-616C-49EC-A994-DA383D172486) and save it locally as `input.rsp` in the current directory.

1. Create a directory on the host to store persisitent data. This directory will be bind mounted into the container at runtime.

    ```shell
    rm -rf /oracle-management-agent
    mkdir -p /oracle-management-agent
    ```

1. Create a local user account that will be used to run the container. This can be any user account on the host system and if the desired user already exists then this step can be skipped.

    ```shell
    groupadd -g 9100 orclmgmtagntgrp
    useradd orclmgmtagntusr -u 9200 -g 9100 -m -s /bin/bash
    ```

    > Note: Remember to substitute `orclmgmtagntusr` and `orclmgmtagntgrp`, wherever applicable, with the desired user if you choose to skip this step.

1. Change ownership of the directory holding persistent data to the desired user.

    ```shell
    chown -R orclmgmtagntusr:orclmgmtagntgrp /oracle-management-agent
    ```

1. Ensure your tenancy is configured correctly by [applying the documented prerequisites for deploying management agents](https://docs.oracle.com/en-us/iaas/management-agents/doc/perform-prerequisites-deploying-management-agents.html)

## Using Docker Compose

1. Create .env file to populate the environment variables

    ```shell
    echo "mgmtagent_hostname=mgmtagentcontainer1" > .env
    echo "DOCKER_BASE_DIR=/oracle-management-agent" >> .env
    echo "USERID=$(id -u orclmgmtagntusr)" >> .env
    echo "GROUPID=$(id -g orclmgmtagntusr)" >> .env
    ```

1. Use Docker Compose CLI to build and run a container image

    ```shell
    docker-compose up --build -d
    ```

## Using Docker or Podman

1. Build the container image

    ```shell
    > docker build -t oracle/mgmtagent-container .
    ```

1. Copy the Install Key (`input.rsp`) into the directory that will be bind mounted into the container and used for persistent storage

    ```shell
    mkdir -p /oracle-management-agent/mgmtagent_secret/
    cp input.rsp /oracle-management-agent/mgmtagent_secret/
    chown -R orclmgmtagntusr:orclmgmtagntgrp /oracle-management-agent/mgmtagent_secret/
    ```

1. Start a container

    ```shell
    # commands given below expect user to be running in a bash shell
    export USERID=$(id -u orclmgmtagntusr)
    export GROUPID=$(id -g orclmgmtagntusr)
    docker run --user $USERID:$GROUPID -d --name mgmtagentcontainer1 --hostname mgmtagentcontainer1 -v /oracle-management-agent/:/opt/oracle:rw --restart unless-stopped oracle/mgmtagent-container:latest
    ```

    > Note: Refer to [description of the recommended run parameters](https://docs.docker.com/engine/reference/run) used above

1. Remove the Install Key (`input.rsp`) from the host directory after [verifying the new Oracle Management Agent is registered and visible in the main Oracle Management Agent page](https://docs.oracle.com/en-us/iaas/management-agents/doc/install-management-agent-chapter.html#GUID-46BE5661-012E-4557-B679-6456DBBEAA4A)

    ```shell
    > rm  /oracle-management-agent/mgmtagent_secret/input.rsp
    ```

## Running custom user operations

You can provide a custom shell script that will run before the Oracle Management Agent starts by following these steps

1. Refer to [init-agent.sh](dockerfiles/latest/user-scripts/init-agent.sh) in the user-scripts directory

    Modify the script `init-agent.sh` to add custom commands that execute each time before Oracle Management Agent starts

1. Follow the steps to build and run a container and validate the output of `init-agent.sh` script is visible in the logs by running the following command

    ```shell
    > docker logs mgmtagent-container
    ```

## Troubleshooting

Below are some possible solutions to common issues that may occur when running the Oracle Management Agent in a container

1. mkdir: cannot create directory '/opt/oracle/bootstrap': Permission denied

    * Ensure the mounted bind volume exists and is accessible by the user used to run the container
    * Verify the user USERID and GROUPID used match the permissions set on the mounted bind volume
    * Verify the mounted bind volume exists on the host

1. Invalid argument: /opt/oracle/mgmtagent_secret/input.rsp

    * Ensure the install key exists at the required location

1. Oracle Management Agent registration failures due to old state files from a prior install
    * Once a Oracle Management Agent instance is deregistered that instance must be shutdown and any associated state files must be removed from the filesystem. Starting a deregistered Oracle Management Agent instance again can result in unregistered agent failures.
    This situation can present itself when old state files from a prior installation are present on the filesystem and made available to a new Oracle Management Agent container deployment. Run the command given below on the host filesystem to perform the necessary cleanup on the bind mount location and perform the deployment again starting at the prerequisites step.

    ```shell
    rm -rf /oracle-management-agent/
    ```

## Helpful commands

1. Starting a stopped Oracle Management Agent Container

    ```shell
    docker start mgmtagent-container
    ```

1. Stopping a running Oracle Management Agent Container

    ```shell
    docker stop mgmtagent-container
    ```

1. Inspecting the logs of a running Oracle Management Agent container

    ```shell
    docker logs mgmtagent-container
    ```

1. Gathering UID and GID of a user from the host environment

    ```shell
    id -u <username> # prints UID of user
    id -g <username> # prints GID of user
    ```

1. Creating a nominated user account during image development (optional)

    ```shell
    groupadd -g <numeric-gid-value> <desired-groupname>
    # example:
    groupadd -g 9100 orclmgmtagntgrp

    useradd <desired-username> -u <numeric-uid-value> -g <numeric-gid-value> -m -s /bin/bash
    # example:
    useradd orclmgmtagntusr -u 9200 -g 9100 -m -s /bin/bash

    # Tip: Add useradd/groupadd to Dockerfile to create a nominated user during image development
    ```

## Container Files for Older Releases

The Oracle Management Agent older container files mentioned below are no longer actively maintained and they are kept in this repository for historical purposes only.

* Oracle Management Agent container files version 1.0.0 [`docker-images/OracleManagementAgent/dockerfiles/1.0.0`](./dockerfiles/1.0.0)

**Notes:**

* Oracle Management Agent container files version 1.0.0 require elevated privileges to run and therefore are not compatible with the latest version found in this repository. Upgrading a version 1.0.0 container to run with the latest container files is also not supported for the same reason.

## License

To download and run the Oracle Management Agent, regardless whether inside or outside a container, you must download the binaries from the Oracle website and accept the license indicated at that page.

Oracle Linux is licensed under the [Oracle Linux End-User License Agreement](https://oss.oracle.com/ol/EULA).

All scripts and files hosted in this project and GitHub [`docker-images/OracleManagementAgent`](./) repository, required to build the container images are, unless otherwise noted, released under the [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Support

Oracle Management Agent container image is supported for the Linux images listed [here](https://docs.oracle.com/en-us/iaas/management-agents/doc/perform-prerequisites-deploying-management-agents.html#GUID-BC5862F0-3E68-4096-B18E-C4462BC76271). For more details please see My Oracle Support.

## Copyright

Copyright (c) 2022, 2023 Oracle and/or its affiliates.
