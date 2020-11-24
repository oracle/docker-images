# Oracle WebCenter Portal 12.2.1.4.0 on Docker
##  Preparing to Run Oracle WebCenter Portal Docker Container
Configure an environment before running the Oracle WebCenter Portal Docker container. You need to set up a communication network between containers on the same host and a WebCenter Content Server instance.

##### A. Creating a user-defined network
##### B. WebCenter Content Server (Optional)

### A. Creating a user-defined network
Create a user-defined network to enable containers to communicate by running the following command:

```
$ docker network create -d bridge WCPortalNET
```

### B. WebCenter Content Server (Optional)
You need to have a running WebCenter Content Server on any machine. The Content server connection details are required for configuring WebCenter Portal during configuration process.

**Note :** This step is required only when the WebCenter Portal uses Content Server as content repository.

##  Running Oracle WebCenter Portal Docker Container
To run the Oracle WebCenter Portal Docker container, you need to create:
* Container to manage the Admin Server.
* Container to manage the Managed Server.

### 1. Creating containers for WebCenter Portal Server

#### 1.1. Update the environment file 

Create an environment file `webcenter.env.list` file, to define the parameters.

Update the parameters inside `webcenter.env.list` as per your local setup.

```
#Database Configuration
DB_DROP_AND_CREATE=<true or false>
DB_CONNECTION_STRING=<Hostname/ContainerName>:<Database Port>/<DB_PDB>.<DB_DOMAIN>
DB_RCUPREFIX=<RCU Prefix>
DB_PASSWORD=<Database Password>
DB_SCHEMA_PASSWORD=<Schema Password>

#configure container
ADMIN_SERVER_CONTAINER_NAME=<Admin Server Container Name>
ADMIN_PORT=<Admin Server Port>
ADMIN_PASSWORD=<Admin Server Password>
ADMIN_USERNAME=<Admin Server User Name>
MANAGED_SERVER_PORT=<Managed Server Port>

# Configure Content Server
CONFIGURE_UCM_CONNECTION=<true or false>
#Valid option for socket type are socket,jaxws 
UCM_SOCKET_TYPE=<UCM Socket Type >
#Required if UCM_SOCKET_TYPE is jaxws
UCM_URL=<Configure UCM URL If Socket type is jaxws>
UCM_HOST=<UCM Host>
UCM_PORT=<UCM Port>
UCM_ADMIN_USER=<UCM Admin User>

# Configure Elasticsearch Server
SEARCH_APP_USERNAME=<Search User Name>
SEARCH_APP_USER_PASSWORD=<Search User Password>
```

### 1.2. Admin Container (WCPAdminContainer)
#### A. Creating and Running Admin Container

Run the following command to create the Admin Server container:

```
$ docker run -i -t --name $ADMIN_SERVER_CONTAINER_NAME --network=WCPortalNET -p <Any Free Port>:$ADMIN_PORT -v $DATA_VOLUME:/u01/oracle/user_projects --env-file <directory>/webcenter.env.list $WCPortalImageName
```
**Note:** Replace variables with values configured in webcenter.env.list
The above command deletes any previous RCU with the same prefix if **DB_DROP_AND_CREATE=true**

The docker run command creates the container as well as starts the Admin Server in sequence given below:

* Node Manager
* Admin Server

When the command is run for the first time, we need to create the domain and configure the portal server, so following are done in sequence:

* Loading WebCenter Portal schemas into the database
* Creating WebCenter Portal domain
* Configuring Node Manager
* Starting Node Manager
* Starting Admin Server

#### B. Stopping Admin Container
```
$ docker container stop WCPAdminContainer
```

#### C. Starting Admin Container
```
$ docker container start -i WCPAdminContainer
```

### 1.3. Portal Container (WCPortalContainer)

#### A. Creating and Running Portal Container
Run the following command to create the Portal Managed Server container:

```
$ docker run -i -t --name WCPortalContainer --network=WCPortalNET -p <Any Free Port>:$MANAGED_SERVER_PORT -v $DATA_VOLUME:/u01/oracle/user_projects --env-file <directory>/webcenter.env.list $WCPortalImageName configureOrStartWebCenterPortal.sh

```
**Note:** Replace variables with values configured in webcenter.env.list

The docker run command creates the container as well as starts the WebCenter Portal managed server. 

When the command is run for the first time, WebCenter Content Server connection creation is also done if **CONFIGURE_UCM_CONNECTION=true**.
 
#### B. Stopping Portal Container
```
$ docker container stop WCPortalContainer
```

#### C. Starting Portal Container
```
$ docker container start -i WCPortalContainer
```

#### D. Getting Shell in Portal Container
```
$ docker exec -it WCPortalContainer /bin/bash
```

### 1.4. Elasticsearch Container  (ESContainer)
To create an Elasticsearch container, we can reuse the environment file `webcenter.env.list` from the above example.

#### A. Data on a volume for Elasticsearch Container
We need to mount data volume to store crawled data outside the Elasticsearch container.

To mount a host directory `/scratch/wcpdocker/volumes/es` ($ES_DATA_VOLUME) as a data volume, execute the below command.

```
$ sudo mkdir -p /scratch/wcpdocker/volumes/es
$ sudo chown 1000:1000 /scratch/wcpdocker/volumes/es
```

#### B. Creating and Running Elasticsearch Container

```
$ docker run -i -t --name ESContainer --network=WCPortalNET -p 9200:9200 --volumes-from WCPortalContainer -v $ES_DATA_VOLUME:/u01/esHome/esNode/data --env-file <directory>/webcenter.env.list $WCPortalImageName configureOrStartElasticsearch.sh
```

#### C. Stopping Elasticsearch Container
```
$ docker container stop ESContainer
```

#### D. Starting Elasticsearch Container
```
$ docker container start -i ESContainer
```

#  FAQs


##### 1. How do I reuse existing domain?
To reuse a existing domain we need to comply with existing domain configuration given in `webcenter.env.list` and container names.

Follow below instruction to recreate a container in such a way that they continue using existing domain on data volume.

*Delete existing container (ESContainer,WCPortalContainer and WCPAdminContainer)*
 
```
$ docker container stop ESContainer
$ docker container stop WCPortalContainer
$ docker container stop WCPAdminContainer

$ docker container rm ESContainer
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
$ docker run -i -t --name WCPAdminContainer --network=WCPortalNET -p 7001:7001 -v /scratch/wcpdocker/volumes/wcpportal:/u01/oracle/user_projects --env-file /scratch/<userid>/docker/webcenter.env.list oracle/wcportal:12.2.1.4.0
 
# create Portal Container
$ docker run -i -t --name WCPortalContainer --network=WCPortalNET -p 8888:8888 -v /scratch/wcpdocker/volumes/wcpportal:/u01/oracle/user_projects --env-file /scratch/<userid>/docker/webcenter.env.list oracle/wcportal:12.2.1.4.0 configureOrStartWebCenterPortal.sh

# create Elasticsearch Container
$ docker run -i -t --name ESContainer --network=WCPortalNET -p 9200:9200 --volumes-from WCPortalContainer -v /scratch/wcpdocker/volumes/es:/u01/esHome/esNode/data --env-file /scratch/<userid>/docker/webcenter.env.list oracle/wcportal:12.2.1.4.0 configureOrStartElasticsearch.sh

```
 


##### 2 How do I create containers with new domain?
In case of any error or want a new fresh instance then you need to follow given instruction  in sequence:

*Delete existing container (WCPAdminContainer, WCPortalContainer and ESContainer)*


*Delete data from shared data volume*

```
# below command should be run as root user
$ rm -rf  $ES_DATA_VOLUME/*
$ rm -rf $DATA_VOLUME/*

```

*Drop and recreate the WebCenter Portal database schema*
 
```
$ docker container stop ESContainer
$ docker container stop WCPortalContainer
$ docker container stop WCPAdminContainer

$ docker container rm ESContainer
$ docker container rm WCPortalContainer
$ docker container rm WCPAdminContainer


```

Update the following parameter inside `webcenter.env.list` :

```
DB_DROP_AND_CREATE=true

```

*Create containers*

*Run the command to create Container in given Sequence (run as non root user)*

```
# create Admin Container
$ docker run -i -t --name WCPAdminContainer --network=WCPortalNET -p 7001:7001 -v /scratch/wcpdocker/volumes/wcpportal:/u01/oracle/user_projects --env-file /scratch/<userid>/docker/webcenter.env.list oracle/wcportal:12.2.1.4.0
 
# create Portal Container
$ docker run -i -t --name WCPortalContainer --network=WCPortalNET -p 8888:8888 -v /scratch/wcpdocker/volumes/wcpportal:/u01/oracle/user_projects --env-file /scratch/<userid>/docker/webcenter.env.list oracle/wcportal:12.2.1.4.0 configureOrStartWebCenterPortal.sh 

# create Elasticsearch Container
$ docker run -i -t --name ESContainer --network=WCPortalNET -p 9200:9200 --volumes-from WCPortalContainer -v /scratch/wcpdocker/volumes/es:/u01/esHome/esNode/data --env-file /scratch/<userid>/docker/webcenter.env.list oracle/wcportal:12.2.1.4.0 configureOrStartElasticsearch.sh

```

# Copyright
 Copyright (c) 2020, Oracle and/or its affiliates.