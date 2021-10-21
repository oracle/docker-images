# Oracle WebCenter Portal 12.2.1.4 in a container

## Mount a host directory into container

The default location of the volume in the container is under `/var/lib/docker/volumes`. There is an option to mount a directory from the host into a container. In this project we will use that option.
To mount a host directory `/scratch/wcpdocker/volumes/wcpportal`(`DATA_MOUNT`) into container, execute the below command.

> The User ID can be anything but it must belong to `uid:guid` as `1000:1000`, which is same as the `oracle` user running in the container.

> This ensures `oracle` user has access to bind mounted filesystem.

```
$ sudo mkdir -p /scratch/wcpdocker/volumes/wcpportal
$ sudo chown 1000:1000 /scratch/wcpdocker/volumes/wcpportal
```
  All container operations are performed as the `oracle` user.
  
  **Note**: If a user already exist with `-u 1000` `-g 1000` then use the same user or create user to have `-u 1000` `-g 1000`

 
##  Preparing to run the Oracle WebCenter Portal container

Configure an environment before running the Oracle WebCenter Portal container.

### A. Creating a user-defined network
Create a user-defined network to enable containers to communicate by running the following command:

```
$ docker network create -d bridge WCPortalNET
```

### B. WebCenter Content Server (Optional)

If you want to integrate Oracle WebCenter Portal with Oracle WebCenter Content Server, you need to have a running Oracle WebCenter Content Server on any machine. But if you want to run  [Oracle WebCenter Content Server Container](../../../OracleWebCenterContent/dockerfiles/README.md) on the same machine as Oracle WebCenter Portal Container,
then it must be running in same network as Oracle WebCenter Portal Container (use above created `WCPortalNET` network)

##  Running the Oracle WebCenter Portal containers

Oracle WebCenter Portal requires the creation of at least two containers
* An Administration Server container.
* A single Managed server container.

**Note :** While Naming Containers avoid using underscore in Container Name to avoid encountering malformed URL exception.  
### 1. Creating containers for WebCenter Portal Server

### 1.1. Update the environment file 

Create an environment file `webcenter.env.list` file, to define the parameters.

Update the parameters inside `webcenter.env.list` as per your local setup.

```
# Database Configuration details
DB_DROP_AND_CREATE=<true or false>
DB_CONNECTION_STRING=<Hostname/ContainerName>:<Database Port>/<DB_PDB>.<DB_DOMAIN>
DB_RCUPREFIX=<RCU Prefix>
DB_PASSWORD=<Database Password>
DB_SCHEMA_PASSWORD=<Schema Password>

# Admin Server Configuration details
ADMIN_SERVER_CONTAINER_NAME=<Admin Server Container Name>
ADMIN_PORT=<Admin Server Port>
ADMIN_PASSWORD=<Admin Server Password>
ADMIN_USERNAME=<Admin Server User Name>
MANAGED_SERVER_PORT=<Managed Server Port>

# Portlet Server Configuration details
MANAGED_SERVER_PORTLET_PORT=<Portlet Server Port>

# Content Server Connection Configuration details
CONFIGURE_UCM_CONNECTION=<true or false>
# Valid option for connection type are socket,jaxws 
UCM_SOCKET_TYPE=<UCM Socket Type >
# Set to true if UCM is using SSL or else false
UCM_USING_SSL=<true or false>
UCM_HOST=<UCM Host>
UCM_PORT=<UCM Port>
UCM_ADMIN_USER=<UCM Admin User>
UCM_INTRADOC_SERVER_PORT=<required if socket>
UCM_CLIENT_SECURITY_POLICY=<required if jaxws>

# Elasticsearch Server Configuration details
SEARCH_APP_USERNAME=<Search User Name>
SEARCH_APP_USER_PASSWORD=<Search User Password>
```

### 1.2. Admin Container (WCPAdminContainer)
#### A. Creating and Running Admin Container

Run the following command to create the Admin Server container:

```
$ docker run -i -t --name <ADMIN_CONTAINER_NAME> --network=<NETWORK_NAME> -p <HostFreePort>:<ADMIN_PORT> -v <DATA_MOUNT>:/u01/oracle/user_projects --env-file <webcenter.env.list> oracle/wcportal:12.2.1.4
```

Sample Run Command

```
$ docker run -i -t --name WCPAdminContainer --network=WCPortalNET -p 7001:7001 -v /scratch/wcpdocker/volumes/wcpportal:/u01/oracle/user_projects --env-file /scratch/<userid>/docker/webcenter.env.list oracle/wcportal:12.2.1.4

```
Admin Container start up command explained:

| 		Parameter    	 |     Parameter Name             | 							     		Description			                               |
| :--------------------: | :----------------------------: | :---------------------------------------------------------------------------------------:  |
| --name                 | ADMIN_CONTAINER_NAME                 |  Set to admin server container name                                                        |
| --network              | NETWORK_NAME                   | User-defined network to connect to; use the one created earlier `WCPortalNET`.             |
| -p                     | HostFreePort:ADMIN_PORT        | WebLogic admin server port; maps the container port to host's port.                      |
| -v                    | DATA_MOUNT                    | Mounts the host directory into container.                                                     |
| --env-file             | webcenter.env.list|  `webcenter.env.list` sets the environment variables.                                    |
| oracle/wcportal:12.2.1.4   | REPOSITORY:TAG           | The (optional) repo, name and tag of the image.                                              |


**Note:** Replace variables with values configured in `webcenter.env.list`
The above command deletes any previous RCU with the same prefix if `DB_DROP_AND_CREATE=true`

The docker run command creates the container as well as starts the Administration Server in sequence given below:

* Node Manager
* Administration Server

When the command is run for the first time, the domain is created and the Oracle WebCenter Portal Server is configured, so the following are done in sequence

* Loading WebCenter Portal schemas into the database
* Creating WebCenter Portal domain
* Configuring Node Manager
* Starting Node Manager
* Starting Admin Server

#### B. Stopping Admin Container
```
$ docker container stop <ADMIN_CONTAINER_NAME>
```

#### C. Starting Admin Container
```
$ docker container start -i <ADMIN_CONTAINER_NAME>
```
### 1.3. Portal Container (WCPortalContainer)

#### A. Creating and Running Portal Container
Run the following command to create the Portal Managed Server container:

```
$ docker run -i -t --name <WCP_CONTAINER_NAME> --network=<NETWORK_NAME> -p <HostFreePort>:<MANAGED_SERVER_PORT> -v <DATA_MOUNT>:/u01/oracle/user_projects --env-file webcenter.env.list oracle/wcportal:12.2.1.4 configureOrStartWebCenterPortal.sh

```

Sample Run Command
 
```
$ docker run -i -t --name WCPortalContainer --network=WCPortalNET -p 8888:8888 -v /scratch/wcpdocker/volumes/wcpportal:/u01/oracle/user_projects --env-file /scratch/<userid>/docker/webcenter.env.list oracle/wcportal:12.2.1.4 configureOrStartWebCenterPortal.sh

```
WebCenter Portal   Container start up command explained:

| 		Parameter    	   |     Parameter Name             | 							     		Description			                               |
| :----------------------: | :-----------------------------:| :---------------------------------------------------------------------------------------: |
| --name                   | WCP_CONTAINER_NAME                 |  Set to Oracle WebCenter Portal server container name                                                |
| --network                | NETWORK_NAME                   | User-defined network to connect to; use the one created earlier `WCPortalNET`.             |
| -p                       | HostFreePort:MANAGED_SERVER_PORT|  Set the mapped port on the host for the Managed server.              	   |
| -v                      | DATA_MOUNT                   | Mounts the host directory into container.      |
| --env-file               | webcenter.env.list  | `webcenter.env.list` sets the environment variables.                            |
|oracle/wcportal:12.2.1.4| REPOSITORY:TAG             | The (optional) repo, name and tag of the image.
  
**Note:** Replace variables with values configured in `webcenter.env.list`

The docker run command creates the container as well as starts the WebCenter Portal managed server. 

When the command is run for the first time and if `CONFIGURE_UCM_CONNECTION=true`, a default connection to Oracle WebCenter Content Server is created.
 
#### B. Stopping Portal Container
```
$ docker container stop <WCP_CONTAINER_NAME>
```

#### C. Starting Portal Container
```
$ docker container start -i <WCP_CONTAINER_NAME>
```

#### D. Getting Shell in Portal Container
```
$ docker exec -it <WCP_CONTAINER_NAME> /bin/bash
```
### 1.4. Portlet Container (WCPortletContainer)

#### A. Creating and Running Portlet Container
Run the following command to create the Portlet Managed Server container:

```
$ docker run -i -t --name <WCPORTLET_CONTAINER_NAME> --network=<NETWORK_NAME> -p <HostFreePort>:<MANAGED_SERVER_PORTLET_PORT> -v <DATA_VOLUME>:/u01/oracle/user_projects --env-file webcenter.env.list oracle/wcportal:12.2.1.4 configureOrStartWebCenterPortlet.sh

```
Sample Run Command 
```
$ docker run -i -t --name WCPortletContainer --network=WCPortalNET -p 7777:7777 -v /scratch/wcpdocker/volumes/wcpportal:/u01/oracle/user_projects --env-file /scratch/<userid>/docker/webcenter.env.list oracle/wcportal:12.2.1.4 configureOrStartWebCenterPortlet.sh

```
WebCenter Portlet Container start up command explained:

| 		Parameter    	   |     Parameter Name             | 							     		Description			                               |
| :----------------------: | :-----------------------------:| :---------------------------------------------------------------------------------------: |
| --name                   | WCPORTLET_CONTAINER_NAME                 |  Set to WebCenter Portlet server container name                                                |
| --network                | NETWORK_NAME                   | User-defined network to connect to; use the one created earlier ‘WCPortalNET’.             |
| -p                       | HostFreePort:MANAGED_SERVER_PORTLET_PORT|  Set Portlet Server port ,Maps the container port to host's port.              	   |
| -v                      | DATA_VOLUME                   | Mounts the host directory as a Volume.      |
| --env-file               | webcenter.env.list  | `webcenter.env.list` sets the environment variables.                            |
|oracle/wcportal:12.2.1.4| REPOSITORY:TAG             | Repository name:Tag name of the image created using buildDockerImage.sh 
  
**Note:** Replace variables with values configured in webcenter.env.list

The docker run command creates the container as well as starts the WebCenter Portlet managed server. 

 
#### B. Stopping Portlet Container
```
$ docker container stop <WCPORTLET_CONTAINER_NAME>
```

#### C. Starting Portlet Container
```
$ docker container start -i <WCPORTLET_CONTAINER_NAME>
```
### 1.5. Elasticsearch Container  (ESContainer)
To create an Elasticsearch container, we can reuse the environment file `webcenter.env.list` from the above example.

#### A. Data on a volume for Elasticsearch Container
We need to bind mount a host directory to store crawled data outside the Elasticsearch container.

To mount a host directory `/scratch/wcpdocker/volumes/es` (`ES_DATA_MOUNT`) into container, execute the below command.

```
$ sudo mkdir -p /scratch/wcpdocker/volumes/es
$ sudo chown 1000:1000 /scratch/wcpdocker/volumes/es
```

#### B. Creating and Running Elasticsearch Container

```
$ docker run -i -t --name <ES_CONTAINER_NAME> --network=<NETWORK_NAME> -p <HostFreePort>:9200 --volumes-from <WCP_CONTAINER_NAME> -v <ES_DATA_MOUNT>:/u01/esHome/esNode/data --env-file webcenter.env.list oracle/wcportal:12.2.1.4 configureOrStartElasticsearch.sh
```

Sample Run Command

```
$ docker run -i -t --name ESContainer --network=WCPortalNET -p 9200:9200 --volumes-from WCPortalContainer -v /scratch/wcpdocker/volumes/es:/u01/esHome/esNode/data --env-file /scratch/<userid>/docker/webcenter.env.list oracle/wcportal:12.2.1.4 configureOrStartElasticsearch.sh

```

Elasticsearch Container start up command explained:

| 		Parameter    	 |     Parameter Name      | 							     		Description			                               |
| :--------------------: | :---------------------: | :---------------------------------------------------------------------------------------: |
| --name                 | ES_CONTAINER_NAME          |  Set to Elasticsearch container name                                                |
| --network              | NETWORK_NAME            | User-defined network to connect to; use the one created earlier `WCPortalNET`.             |
| -p                     | HostFreePort:9200| Elasticsearch default port 9200 as container port , Maps the container port to host's  port.              	   |
| --volumes-from         | WCP_CONTAINER_NAME  | Set the Oracle WebCenter Portal container name               	   |
| -v                    | ES_DATA_MOUNT| Mounts the host directory into container.      |
| --env-file             | webcenter.env.list | `webcenter.env.list`  sets the environment variables.                            |
| oracle/wcportal:12.2.1.4      | REPOSITORY:TAG      | The (optional) repo, name and tag of the image.   |
  
#### C. Stopping Elasticsearch Container
```
$ docker container stop <ES_CONTAINER_NAME>
```

#### D. Starting Elasticsearch Container
```
$ docker container start -i <ES_CONTAINER_NAME>
```

#  FAQs


##### 1. How do I reuse existing domain?
To reuse a existing domain we need to comply with existing domain configuration given in `webcenter.env.list` and container names.

Follow below instruction to recreate a container in such a way that they continue using existing domain on data volume.

*Delete existing container (ESContainer, WCPortletContainer, WCPortalContainer and WCPAdminContainer)*
 
```
$ docker container stop ESContainer
$ docker container stop WCPortletContainer
$ docker container stop WCPortalContainer
$ docker container stop WCPAdminContainer

$ docker container rm ESContainer
$ docker container rm WCPortletContainer
$ docker container rm WCPortalContainer
$ docker container rm WCPAdminContainer

```

*Reuse the WebCenter Portal database schema*

Update the following parameter inside `webcenter.env.list` :

```
DB_DROP_AND_CREATE=false

```

*Create container pointing to existing domain*
*Run the command to create Container in given Sequence (run as non root user)*
```
# create Admin Container
$ docker run -i -t --name WCPAdminContainer --network=WCPortalNET -p 7001:7001 -v /scratch/wcpdocker/volumes/wcpportal:/u01/oracle/user_projects --env-file /scratch/<userid>/docker/webcenter.env.list oracle/wcportal:12.2.1.4

# create Portal Container
$ docker run -i -t --name WCPortalContainer --network=WCPortalNET -p 8888:8888 -v /scratch/wcpdocker/volumes/wcpportal:/u01/oracle/user_projects --env-file /scratch/<userid>/docker/webcenter.env.list oracle/wcportal:12.2.1.4 configureOrStartWebCenterPortal.sh

#create Portlet Container
$ docker run -i -t --name WCPortletContainer --network=WCPortalNET -p 7777:7777 -v /scratch/wcpdocker/volumes/wcpportal:/u01/oracle/user_projects --env-file /scratch/<userid>/docker/webcenter.env.list oracle/wcportal:12.2.1.4 configureOrStartWebCenterPortlet.sh

# create Elasticsearch Container
$ docker run -i -t --name ESContainer --network=WCPortalNET -p 9200:9200 --volumes-from WCPortalContainer -v /scratch/wcpdocker/volumes/es:/u01/esHome/esNode/data --env-file /scratch/<userid>/docker/webcenter.env.list oracle/wcportal:12.2.1.4 configureOrStartElasticsearch.sh

```
 


##### 2 How do I create containers with new domain?
In case of any error or want a new fresh instance then you need to follow given instruction  in sequence:

*Delete existing container (WCPAdminContainer, WCPortletContainer, WCPortalContainer and ESContainer)*


*Delete data from shared bind mounts*

```
# below command should be run as root user
$ rm -rf  ES_DATA_MOUNT/*
$ rm -rf DATA_MOUNT/*

```

 
```
$ docker container stop ESContainer
$ docker container stop WCPortletContainer
$ docker container stop WCPortalContainer
$ docker container stop WCPAdminContainer

$ docker container rm ESContainer
$ docker container rm WCPortletContainer
$ docker container rm WCPortalContainer
$ docker container rm WCPAdminContainer


```
*Drop and recreate the WebCenter Portal database schema*

Update the following parameter inside `webcenter.env.list` :

```
DB_DROP_AND_CREATE=true

```

*Create containers*

*Run the command to create Container in given Sequence (run as non root user)*

```
# create Admin Container
$ docker run -i -t --name WCPAdminContainer --network=WCPortalNET -p 7001:7001 -v /scratch/wcpdocker/volumes/wcpportal:/u01/oracle/user_projects --env-file /scratch/<userid>/docker/webcenter.env.list oracle/wcportal:12.2.1.4

# create Portal Container
$ docker run -i -t --name WCPortalContainer --network=WCPortalNET -p 8888:8888 -v /scratch/wcpdocker/volumes/wcpportal:/u01/oracle/user_projects --env-file /scratch/<userid>/docker/webcenter.env.list oracle/wcportal:12.2.1.4 configureOrStartWebCenterPortal.sh 

#create Portlet Container
$ docker run -i -t --name WCPortletContainer --network=WCPortalNET -p 7777:7777 -v /scratch/wcpdocker/volumes/wcpportal:/u01/oracle/user_projects --env-file /scratch/<userid>/docker/webcenter.env.list oracle/wcportal:12.2.1.4 configureOrStartWebCenterPortlet.sh
 
# create Elasticsearch Container
$ docker run -i -t --name ESContainer --network=WCPortalNET -p 9200:9200 --volumes-from WCPortalContainer -v /scratch/wcpdocker/volumes/es:/u01/esHome/esNode/data --env-file /scratch/<userid>/docker/webcenter.env.list oracle/wcportal:12.2.1.4 configureOrStartElasticsearch.sh

```

# Copyright
 Copyright (c) 2020, 2021, Oracle and/or its affiliates.
