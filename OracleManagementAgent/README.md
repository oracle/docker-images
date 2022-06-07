# Oracle Management Agent Container Image
This repository contains sample container configurations to facilitate installation and environment setup for DevOps users. This project includes Dockerfiles based on Oracle Linux and Oracle OpenJDK 8.

The certification of Oracle Management Agent in a container does not require the use of any file presented in this
repository. Customers and users are welcome to use them as starters, and customize/tweak, or create
from scratch new scripts and Dockerfiles.


## How to build and run

Oracle Management Agent image uses the official `oraclelinux:7-slim` container image as the base image.

#### Prerequisites

1. [Download the Management Agent software](https://cloud.oracle.com/macs)

    **Note: Select 'Downloads and Keys' then download 'Agent for LINUX (X86_64)' of the package type ZIP.**

1. Copy the downloaded bundle to the same directory as the Dockerfile

    ```shell
    $ cp oracle.mgmt_agent.zip OracleManagementAgent/dockerfiles/latest/
    ```

1. Follow the steps in the [Create Install Key](https://docs.oracle.com/en-us/iaas/management-agents/doc/management-agents-administration-tasks.html#GUID-C841426A-2C32-4630-97B6-DF11F05D5712) and [Configure a Response File](https://docs.oracle.com/en-us/iaas/management-agents/doc/install-management-agent-chapter.html#GUID-5D20D4A7-616C-49EC-A994-DA383D172486) sections of the [Management Agent](https://docs.oracle.com/en-us/iaas/management-agents/index.html) documentation to create an install key and save it locally as `input.rsp`.

1. Copy the downloaded install key to the same directory as the Dockerfile

    ```shell
    $ cp input.rsp OracleManagementAgent/dockerfiles/latest/
    ```

1. Change to the directory in which the `Dockerfile` for this container image is located

    ```shell
    $ cd OracleManagementAgent/dockerfiles/latest/
    ```

1. Ensure your tenancy is configured correctly by [applying the documented prerequisites for deploying management agents](https://docs.oracle.com/en-us/iaas/management-agents/doc/perform-prerequisites-deploying-management-agents.html)

#### Steps to build and run using Docker Compose

1. Create .env file to populate the hostname variable
    ```shell
    $ echo "mgmtagent_hostname=mgmtagent912" > .env
    ```
    **Note: Chose a unique hostname as it will be used to identify Management Agent in the UI.**

1. Use Docker Compose CLI to build and run a container image

    ```shell
    $ docker-compose up -d
    ```

#### Steps to build and run using Docker CLI 

1. Build the container image

    ```shell
    $ docker build -t oracle/mgmtagent-container .
    ```

1. Create a Docker volume to share configs with the container

    ```shell
    $ docker volume create mgmtagent-volume

    # identify the mount point location to use in next steps
    $ docker volume inspect mgmtagent-volume|grep Mountpoint
        "Mountpoint": "/var/lib/docker/volumes/mgmtagent-volume/_data",
    ```

1. Copy the Install Key (input.rsp) into the shared Docker volume Mountpoint

    ```shell
    # create any necessary dirs
    $ mkdir -p /var/lib/docker/volumes/mgmtagent-volume/_data/mgmtagent_secret
    $ cp input.rsp /var/lib/docker/volumes/mgmtagent-volume/_data/mgmtagent_secret/
    ```

1. Start a container

    ```shell
    $ docker run -d --name mgmtagent-container --hostname mgmtagent1 -v mgmtagent-volume:/opt/oracle:rw --restart unless-stopped oracle/mgmtagent-container:latest
    ```

    **Description of Docker run parameters used above**
    <!-- markdownlint-disable MD033 -->
    | Parameter | Description |
    | --------- | ----------- |
    | -d | Starts mgmtagent-container in detached mode |
    | --name mgmtagent-container | The name given to the container to identify it. |
    | --hostname mgmtagent1 | Assign mgmtagent1 as the containers internal hostname. This can be any hostname compliant string and it will be used to identify the Management Agent instance in the OMC Console. |
    | -v mgmtagent-volume | /opt/oracle:rw: Mounts the volume mgmtagent-volume created on host filesystem inside the container at /opt/oracle with Read/Write privileges. |
    | --restart unless-stopped | Unless explicitly stopped, this restart policy restarts mgmtagent-container automatically when docker restarts. |
    <!-- markdownlint-enable MD033 -->

1. Remove the Install Key (input.rsp) from the shared Docker volume Mountpoint after [verifying the new Management Agent is registered and visible in the main Management Agents page](https://docs.oracle.com/en-us/iaas/management-agents/doc/install-management-agent-chapter.html#GUID-46BE5661-012E-4557-B679-6456DBBEAA4A)

    ```shell
    $ rm  /var/lib/docker/volumes/mgmtagent-volume/_data/mgmtagent_secret/input.rsp
    ```

#### Steps to execute custom user operations

Users can provide custom shell script commands to execute before starting Management Agent as described in the following steps

1. Refer to [init-agent.sh](dockerfiles/latest/user-scripts/init-agent.sh) in the user-scripts directory

    Modify the script `init-agent.sh` to add custom commands that execute each time before Management Agent starts

1. Follow the steps to build and run a container and validate the output of `init-agent.sh` script is visible in the logs by running the following command

    ```shell
    $ docker logs mgmtagent-container
    ```

#### Helpful administration commands

1. Starting a stopped Management Agent Container

    ```shell
    $ docker start mgmtagent-container
    ```

1. Stopping a running Management Agent Container

    ```shell
    $ docker stop mgmtagent-container
    ```

1. Inspecting logs of Management Agent Container

    ```shell
    $ docker logs mgmtagent-container
    ```

## License
To download and run the Oracle Management Agent, regardless whether inside or outside a container, you must download the binaries from the Oracle website and accept the license indicated at that page.

Oracle Linux is licensed under the [Oracle Linux End-User License Agreement](https://oss.oracle.com/ol/EULA).

All scripts and files hosted in this project and GitHub [`docker-images/OracleManagementAgent`](./) repository, required to build the Docker images are, unless otherwise noted, released under the [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Support
Oracle Management Agent container image is supported for the Linux images listed [here](https://docs.oracle.com/en-us/iaas/management-agents/doc/perform-prerequisites-deploying-management-agents.html#GUID-BC5862F0-3E68-4096-B18E-C4462BC76271). For more details please see My Oracle Support.

## Copyright
Copyright (c) 2022 Oracle and/or its affiliates.
