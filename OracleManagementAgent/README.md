<!--
    Copyright (c) 2022, Oracle and/or its affiliates.
    Licensed under the Universal Permissive License v 1.0 as shown at
    https://oss.oracle.com/licenses/upl.
-->
Oracle Management Agent on Docker
=====
This repository contains sample container configurations to facilitate installation and environment setup for DevOps users. This project includes Dockerfiles based on Oracle Linux and Oracle OpenJDK 8.

The certification of Oracle Management Agent on Docker does not require the use of any file presented in this
repository. Customers and users are welcome to use them as starters, and customize/tweak, or create
from scratch new scripts and Dockerfiles.


## How to build and run

Oracle Management Agent images use the Oracle Linux 7 Slim docker image as the base image.

### Prerequisites

* Latest Management Agent software for Linux (Linux-x86_64/latest/oracle.mgmt_agent.zip)

#### Build steps

1. [Download the Management Agent software](https://cloud.oracle.com/macs)

    **Note: Select 'Downloads and Keys' then download 'Agent for LINUX (X86_64)' of the package type ZIP.**
    ```shell
    Copy-paste link: https://cloud.oracle.com/macs
    ```

1. Copy the downloaded bundle to the same directory as the Dockerfile

    ```shell
    $ cp oracle.mgmt_agent.zip OracleManagementAgent/dockerfiles/latest/
    ```

1. Change directory to build the dockerfile

    ```shell
    $ cd OracleManagementAgent/dockerfiles/latest/
    ```

1. Build the Docker image

    ```shell
    $ docker build -t oracle/mgmtagent-container .
    ```

1. [Create and Download the Install Key](https://docs.oracle.com/en-us/iaas/management-agents/doc/install-management-agent-chapter.html)

    **Note: Follow the steps in the 'Create Install Key' and 'Configure a Response File' sections to create the install key and save it as input.rsp.**
    ```shell
    $ docker volume create mgmtagent-volume
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

1. [Apply Prerequisites for Deploying Management Agents](https://docs.oracle.com/en-us/iaas/management-agents/doc/perform-prerequisites-deploying-management-agents.html)

    **Note: Without the prerequisites applied the agent may not function as expected.**

1. Start the Docker container

    ```shell
    $ docker run -d --name mgmtagent-container --hostname mgmtagent1 -v mgmtagent-volume:/opt/oracle:rw --restart unless-stopped oracle/mgmtagent-container:latest
    ```
    **Description of Docker run parameters used above**
    ```shell
    -d: Starts mgmtagent-container in detached mode
    --name mgmtagent-container: The name given to the container to identify it.
    --hostname mgmtagent1: Assign mgmtagent1 as the containers internal hostname. This can be any hostname compliant string and it will be used to identify the Management Agent instance in the OMC Console.
    -v mgmtagent-volume:/opt/oracle:rw: Mounts the volume mgmtagent-volume created on host filesystem inside the container at /opt/oracle with Read/Write privileges.
    --restart unless-stopped: Unless explicitly stopped, this restart policy restarts mgmtagent-container automatically when docker restarts.
    ```

#### Helpful Docker Administration commands

1. Starting a stopped Management Agent Container

    ```shell
    $ docker container start mgmtagent-container
    ```

1. Stopping a running Management Agent Container

    ```shell
    $ docker container stop mgmtagent-container
    ```

1. Inspecting logs of Management Agent Container

    ```shell
    $ docker container logs mgmtagent-container
    ```

## License
To download and run the Oracle Management Agent, regardless whether inside or outside a container, you must download the binaries from the Oracle website and accept the license indicated at that page.

Oracle Linux is licensed under the [Oracle Linux End-User License Agreement](https://oss.oracle.com/ol/EULA).

All scripts and files hosted in this project and GitHub [`docker-images/OracleManagementAgent`](./) repository, required to build the Docker images are, unless otherwise noted, released under the [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Customer Support
Oracle Management Agent docker image is supported for Oracle Linux 7. For more details please see My Oracle Support.

## Copyright
Copyright (c) 2022 Oracle and/or its affiliates. All rights reserved.
