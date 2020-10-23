# Creating Oracle Unified Directory Containers

## Contents
1. [Before You Begin](#before-you-begin)
1. [What Do You Need?](#what-do-you-need)
1. [Prepare to Run OUD image](#prepare-to-run-oud-image)
1. [Directory Server/Service (instanceType=Directory)](#directory-serverservice-instancetypedirectory)
1. [Directory Proxy Server/Service (instanceType=Proxy)](#directory-proxy-serverservice-instancetypeproxy)
1. [Replication Server/Service (instanceType=Replication)](#replication-serverservice-instancetypereplication)
1. [Directory Server/Service added to existing Replication Server/Service (instanceType=AddDS2RS)](#directory-serverservice-added-to-existing-replication-serverservice-instancetypeaddds2rs)
1. [Directory Server/Service (myoudds2b) added to existing Directory Server/Service (myoudds2) (instanceType=AddDS2RS)](#directory-serverservice-myoudds2b-added-to-existing-directory-serverservice-myoudds2-instancetypeaddds2rs)
1. [Directory Client to run CLIs like ldapsearch, dsconfig, and dsreplication](#directory-client-to-run-clis-like-ldapsearch-dsconfig-and-dsreplication)
1. [Directory Server/Service (instanceType=Directory) with dstune configuration options](#directory-serverservice-instancetypedirectory-with-dstune-configuration-options)
1. [Access interfaces (LDAP / LDAPS / HTTP / HTTPS) exposed by OUD container](#access-interfaces-ldap-ldaps-http-https-exposed-by-oud-container)
1. [Removing an OUD Container](#removing-an-oud-container)

## Before You Begin
								
The samples below show you how to create and configure Oracle Unified Directory (OUD) 12.2.1.4.0 containers.

## What Do You Need?
                            
* An OUD image loaded into the Docker repository
* A basic understanding of Docker
* An understanding of OUD and its deployment options.
                            
## Prepare to Run OUD image

### Create a Bridged Network

Create a bridged network so the OUD container(s) can communicate with each other.

To create a bridged network, run the following command:

```
$ docker network create -d bridge OUDNet
```

The output will look similar to the following:

```
f18ca45a95c8ae1b6885fcc1b489a1a1a76bcdd292272276c2960335734c8d39
```

### Mount a host directory as a data volume

Mount a volume (a directory stored outside a container's file system), to store OUD Instance files and any other configuration. The default location of the user_projects volume in the container is /u01/oracle/user_projects (this is the directory under which the OUD instance is created).

This option allows you to mount a directory from your host to a container as a volume. This volume is used to store OUD Instance files.

To prepare a host directory (for example: /scratch/user_projects) for mounting as a data volume, execute the command below:

**Note:** The userid can be anything but it must have uid:guid with the value 1000:1000.  This is same value as the oracle user running in the container.  This ensures that the oracle user has access to the data volume.

```
$ sudo su - root
$ mkdir -p /scratch/user_projects
$ chown 1000:1000 /scratch/user_projects
$ exit
```

All container operations are performed as the oracle user.

## Directory Server/Service (instanceType=Directory)

In this section you will create two containers, each of which will host a single OUD 12c Directory Server/Service.

The parameter file for creating each of the containers can be found in this project at the following location : samples/oud-dir.env.  This file contains the following values:

```
instanceType=Directory
OUD_INSTANCE_NAME=myoudds1
hostname=myoudds1
baseDN=dc=example1,dc=com
rootUserDN=<rootUserDN>
rootUserPassword=<Password>
sampleData=100
```

Create a copy of the file and replace the placeholders <rootUserDN> and <Password> with the required values, for example:

```
rootUserDN=cn=Directory Manager
rootUserPassword=Oracle123
```

### Create the first container:

Run the following command to create the OUD12c Directory Server container.

```
$ docker run -d --network=OUDNet \
--name=myoudds1 \
--volume /scratch/user_projects:/u01/oracle/user_projects \
--env-file ~/oud-dir.env \
oud-with-patch:12.2.1.4.0
```

Run the following command to check that the container is created and starting:

```
$ docker ps
```

The output should look similar to the following:

```
CONTAINER ID        IMAGE                              COMMAND                  CREATED             STATUS                             PORTS               NAMES
3ee9ed788baf        oud-with-patch:12.2.1.4.0          "sh -c ${SCRIPT_DIR}…"   57 seconds ago      Up 56 seconds (health: starting)                       myoudds1
```

Run the following command to tail the log and check the status of the container creation:

```
$ docker logs -f myoudds1
```

The output should look similar to the following:

```
$ docker logs myoudds1
[Wed Sep 16 16:16:19 UTC 2020] - Create and Start OUD Instance - Initializing...
[Wed Sep 16 16:16:19 UTC 2020] - Environment Variables which would influence OUD Instance setup and configuration
instanceType [Directory]
hostname [myoudds1]
ldapPort [1389]
ldapsPort [1636]
rootUserDN [cn=Directory Manager]
baseDN [dc=example1,dc=com]
...
[16/Sep/2020:16:16:57 +0000] category=PROTOCOL severity=NOTICE msgID=2556180 msg=Started listening for new connections on HTTP Connection Handler 0.0.0.0 port 1081
[16/Sep/2020:16:16:57 +0000] category=CORE severity=NOTICE msgID=458887 msg=The Directory Server has started successfully
[16/Sep/2020:16:16:57 +0000] category=CORE severity=NOTICE msgID=458891 msg=The Directory Server has sent an alert notification generated by class org.opends.server.core.DirectoryServer (alert type org.opends.server.DirectoryServerStarted, alert ID 458887):  The Directory Server has started successfully
```

When you see the message "The Directory Server has started successfully" the OUD instance has started successfully.  This is reflected in the container listing which will show a STATUS of "healthy" (changed from "health: starting").

```
CONTAINER ID        IMAGE                              COMMAND                  CREATED             STATUS                   PORTS               NAMES
3ee9ed788baf        oud-with-patch:12.2.1.4.0          "sh -c ${SCRIPT_DIR}…"   4 minutes ago       Up 4 minutes (healthy)                       myoudds1
```

### Validate the first container:

Run the following command to retrieve entries from the OUD instance:

```
$ docker run -it --rm --network=OUDNet \
--name=MyOUDClient \
--volume /scratch/user_projects:/u01/oracle/user_projects \
oud-with-patch:12.2.1.4.0 \
/u01/oracle/oud/bin/ldapsearch \
--hostname myoudds1 \
--port 1389 \
--bindDN "cn=Directory Manager" \
--bindPassword "Oracle123" \
--baseDN "dc=example1,dc=com" \
"(objectClass=person)" dn
```

You should see entries output similar to those shown below:

```
dn: uid=user.0,ou=People,dc=example1,dc=com

dn: uid=user.1,ou=People,dc=example1,dc=com

dn: uid=user.2,ou=People,dc=example1,dc=com

...

dn: uid=user.97,ou=People,dc=example1,dc=com

dn: uid=user.98,ou=People,dc=example1,dc=com

dn: uid=user.99,ou=People,dc=example1,dc=com
```

**Note:** The domain created in the first instance is based on the baseDN=dc=example1,dc=com parameter.

### Create and validate the second container:

Run the following command to create the OUD12c Directory Server container.

```
$ docker run -d --network=OUDNet \
--name=myoudds2 \
--volume /scratch/user_projects:/u01/oracle/user_projects \
--env-file ~/oud-dir.env \
--env OUD_INSTANCE_NAME=myoudds2 \
--env hostname=myoudds2 \
--env baseDN="dc=example2,dc=com" \
oud-with-patch:12.2.1.4.0
```
**Note:** Here you override the values in the parameter file oud-dir.env for OUD_INSTANCE_NAME, hostname, and baseDN.

Check that the container has started as you did for the first instance and then run the following command to retrieve entries from the second OUD instance:

```
$ docker run -it --rm --network=OUDNet \
--name=MyOUDClient \
--volume /scratch/user_projects:/u01/oracle/user_projects \
oud-with-patch:12.2.1.4.0 \
/u01/oracle/oud/bin/ldapsearch \
--hostname myoudds2 \
--port 1389 \
--bindDN "cn=Directory Manager" \
--bindPassword "Oracle123" \
--baseDN "dc=example2,dc=com" \
"(objectClass=person)" dn
```

You should see entries output similar to those shown below:

```
dn: uid=user.0,ou=People,dc=example2,dc=com

dn: uid=user.1,ou=People,dc=example2,dc=com

dn: uid=user.2,ou=People,dc=example2,dc=com

...

dn: uid=user.97,ou=People,dc=example2,dc=com

dn: uid=user.98,ou=People,dc=example2,dc=com

dn: uid=user.99,ou=People,dc=example2,dc=com
```

**Note:** The domain created in the first instance is based on the --baseDN "dc=example2,dc=com" parameter.

## Directory Proxy Server/Service (instanceType=Proxy)

### Create the container

In this section you will create a single container, which will host a single OUD 12c Proxy Server/Service which can be used to front end the Directory Servers created in the previous example.

The parameter file for creating the container can be found in this project at the following location : samples/oud-proxy.env.  This file contains the following values:

```
instanceType=Proxy
OUD_INSTANCE_NAME=myoudp
hostname=myoudp
rootUserDN=<rootUserDN>
rootUserPassword=<Password>
dsconfig_1=create-extension --set enabled:true --set remote-ldap-server-address:myoudds1 --set remote-ldap-server-port:1389 --set remote-ldap-server-ssl-port:1636 --extension-name ldap_extn_1 --type ldap-server
dsconfig_2=create-workflow-element --set client-cred-mode:use-client-identity --set enabled:true --set ldap-server-extension:ldap_extn_1 --type proxy-ldap --element-name proxy_ldap_wfe_1
dsconfig_3=create-workflow --set base-dn:dc=example1,dc=com --set enabled:true --set workflow-element:proxy_ldap_wfe_1 --type generic --workflow-name wf_1
dsconfig_4=set-network-group-prop --group-name network-group --add workflow:wf_1
dsconfig_5=create-extension --set enabled:true --set remote-ldap-server-address:myoudds2 --set remote-ldap-server-port:1389 --set remote-ldap-server-ssl-port:1636 --extension-name ldap_extn_2 --type ldap-server
dsconfig_6=create-workflow-element --set client-cred-mode:use-client-identity --set enabled:true --set ldap-server-extension:ldap_extn_2 --type proxy-ldap --element-name proxy_ldap_wfe_2
dsconfig_7=create-workflow --set base-dn:dc=example2,dc=com --set enabled:true --set workflow-element:proxy_ldap_wfe_2 --type generic --workflow-name wf_2
dsconfig_8=set-network-group-prop --group-name network-group --add workflow:wf_2
```

Create a copy of the file and replace the placeholders <rootUserDN> and <Password> with the required values, for example:

```
rootUserDN=cn=Directory Manager
rootUserPassword=Oracle123
```

Run the following command to create the OUD12c Directory Server container.

```
$ docker run -d --network=OUDNet \
--name=myoudp \
--volume /scratch/user_projects:/u01/oracle/user_projects \
--env-file ~/oud-proxy.env \
oud-with-patch:12.2.1.4.0
```									

Run the following command to check that the container is created and starting:

```
$ docker ps
```

The output should look similar to the following:

```
CONTAINER ID        IMAGE                              COMMAND                  CREATED             STATUS                                          PORTS               NAMES
f8ef3e2137ab        oud-with-patch:12.2.1.4.0          "sh -c ${SCRIPT_DIR}…"   58 minutes ago      Up 58 minutes (Up 3 seconds (health: starting))                     myoudp
```

Run the following command to tail the log and check the status of the container creation:

```
$ docker logs -f myoudp
```

The output should look similar to the following:

```
$ docker logs -f myoudp
[Thu Sep 17 15:48:31 UTC 2020] - Create and Start OUD Instance - Initializing...
[Thu Sep 17 15:48:31 UTC 2020] - Environment Variables which would influence OUD Instance setup and configuration
instanceType [Proxy]
hostname [myoudp]
ldapPort [1389]
ldapsPort [1636]
rootUserDN [cn=Directory Manager]
baseDN [dc=example,dc=com]
adminConnectorPort [1444]
httpAdminConnectorPort [1888]
httpPort [1080]
httpsPort [1081]
...
[17/Sep/2020:15:49:01 +0000] category=PROTOCOL severity=NOTICE msgID=2556180 msg=Started listening for new connections on HTTP Connection Handler 0.0.0.0 port 1081
[17/Sep/2020:15:49:01 +0000] category=CORE severity=NOTICE msgID=458887 msg=The Directory Server has started successfully
[17/Sep/2020:15:49:01 +0000] category=CORE severity=NOTICE msgID=458891 msg=The Directory Server has sent an alert notification generated by class org.opends.server.core.DirectoryServer (alert type org.opends.server.DirectoryServerStarted, alert ID 458887):  The Directory Server has started successfully
```

When you see the message "The Directory Server has started successfully" the OUD proxy instance has started successfully.  This is reflected in the container listing which will show a STATUS of "healthy" (changed from "health: starting").

```
CONTAINER ID        IMAGE                              COMMAND                  CREATED             STATUS                    PORTS               NAMES
f8ef3e2137ab        oud-with-patch:12.2.1.4.0          "sh -c ${SCRIPT_DIR}…"   58 minutes ago      Up 58 minutes (healthy)                       myoudp
```

### Validate the container

Run the following command to retrieve entries from the OUD instance:

```
$ docker run -it --rm --network=OUDNet \
--name=MyOUDClient \
--volume /scratch/user_projects:/u01/oracle/user_projects \
oud-with-patch:12.2.1.4.0 \
/u01/oracle/oud/bin/ldapsearch \
--hostname myoudp \
--port 1389 \
--bindDN "cn=Directory Manager" \
--bindPassword "Oracle123" \
--baseDN "dc=example1,dc=com" \
"(objectClass=person)" dn
```

This returns users with a base of dc=example1,dc=com via the proxy, myoudp:


```
dn: uid=user.0,ou=People,dc=example1,dc=com

dn: uid=user.1,ou=People,dc=example1,dc=com

dn: uid=user.2,ou=People,dc=example1,dc=com

...

dn: uid=user.97,ou=People,dc=example1,dc=com

dn: uid=user.98,ou=People,dc=example1,dc=com

dn: uid=user.99,ou=People,dc=example1,dc=com
```

Updating the "--baseDN" parameter to dc=example2,dc=com will return users with a base of dc=example2,dc=com via the proxy, myoudp:

```
dn: uid=user.0,ou=People,dc=example2,dc=com

dn: uid=user.1,ou=People,dc=example2,dc=com

dn: uid=user.2,ou=People,dc=example2,dc=com

...

dn: uid=user.97,ou=People,dc=example2,dc=com

dn: uid=user.98,ou=People,dc=example2,dc=com

dn: uid=user.99,ou=People,dc=example2,dc=com
```

## Replication Server/Service (instanceType=Replication)

### Create the container

In this section you will create a single container, which will host a single OUD 12c Replication Server/Service.  You will also add the Directory Server created in Example 1 (myoudds1) into the replication group managed by this Replication Server.

The parameter file for creating the container can be found in this project at the following location : samples/oud-add-replication.env.  This file contains the following values:

```
instanceType=Replication
OUD_INSTANCE_NAME=myoudrs1
hostname=myoudrs1
baseDN=dc=example1,dc=com
rootUserDN=<rootUserDN>
rootUserPassword=<Password>
adminUID=admin
adminPassword=<Password>
bindDN1=<rootUserDN>
bindPassword1=<Password>
bindDN2=<rootUserDN>
bindPassword2=<Password>
sourceHost=myoudds1
dsreplication_1=disable --disableAll --hostname ${sourceHost} --port ${adminConnectorPort}
dsreplication_2=enable --host1 ${sourceHost} --port1 ${adminConnectorPort} --noReplicationServer1 --host2 ${hostname} --port2 ${adminConnectorPort} --replicationPort2	${replicationPort} --onlyReplicationServer2 --baseDN ${baseDN}
dsreplication_3=status --hostname ${hostname} --port ${adminConnectorPort} --baseDN ${baseDN} --dataToDisplay compat-view 
dsreplication_4=verify --hostname ${hostname} --port ${adminConnectorPort} --baseDN ${baseDN}
```

Create a copy of the file and replace the placeholders <rootUserDN> and <Password> with the required values, for example:

```
rootUserDN=cn=Directory Manager
rootUserPassword=Oracle123
```

Run the following command to create the OUD12c Replication Server container, and add the Directory Server instance to the replication group.

```
$ docker run -d --network=OUDNet \
--name=myoudrs1 \
--volume /scratch/user_projects:/u01/oracle/user_projects \
--env-file ~/oud-add-replication.env \
oud-with-patch:12.2.1.4.0
```									

Run the following command to check that the container is created and starting:

```
$ docker ps
```

The output should look similar to the following:

```
CONTAINER ID        IMAGE                              COMMAND                  CREATED             STATUS                            PORTS               NAMES
a2a34ebcb34c        oud-with-patch:12.2.1.4.0          "sh -c ${SCRIPT_DIR}…"   4 seconds ago       Up 2 seconds (health: starting)                       myoudrs1
```

Run the following command to tail the log and check the status of the container creation:

```
$ docker logs -f myoudrs1
```

The output should look similar to the following:

```
$ docker logs -f myoudrs1
[Fri Sep 18 13:24:35 UTC 2020] - Create and Start OUD Instance - Initializing...
[Fri Sep 18 13:24:35 UTC 2020] - Environment Variables which would influence OUD Instance setup and configuration
instanceType [Replication]
hostname [myoudrs1]
ldapPort [1389]
ldapsPort [1636]
rootUserDN [cn=Directory Manager]
baseDN [dc=example1,dc=com]
adminConnectorPort [1444]
httpAdminConnectorPort [1888]
httpPort [1080]
httpsPort [1081]
...
18/Sep/2020:13:25:00 +0000] category=PROTOCOL severity=NOTICE msgID=2556180 msg=Started listening for new connections on LDAP Connection Handler 0.0.0.0 port 1389
[18/Sep/2020:13:25:00 +0000] category=CORE severity=NOTICE msgID=458887 msg=The Directory Server has started successfully
[18/Sep/2020:13:25:00 +0000] category=CORE severity=NOTICE msgID=458891 msg=The Directory Server has sent an alert notification generated by class org.opends.server.core.DirectoryServer (alert type org.opends.server.DirectoryServerStarted, alert ID 458887):  The Directory Server has started successfully
```

When you see the message "The Directory Server has started successfully" the OUD replication server instance has started successfully.  This is reflected in the 
container listing which will show a STATUS of "healthy" (changed from "health: starting").

```
CONTAINER ID        IMAGE                              COMMAND                  CREATED             STATUS                   PORTS               NAMES
a2a34ebcb34c        oud-with-patch:12.2.1.4.0          "sh -c ${SCRIPT_DIR}…"   3 minutes ago       Up 3 minutes (healthy)                       myoudrs1
```									

### Validate the container

Validate the replication server by running the dsreplication command.  Issue the following command:

```
$ docker exec -it myoudrs1 \
/u01/oracle/user_projects/myoudrs1/OUD/bin/dsreplication status \
--trustAll \
--hostname myoudrs1 \
--port 1444 \
--adminUID admin \
--dataToDisplay compat-view \
--dataToDisplay rs-connections

Enter the admin password when prompted:

>>>> Specify Oracle Unified Directory LDAP connection parameters

Password for user 'admin': Oracle123
```

Output should be similar to the following:

```
Establishing connections and reading configuration ..... Done.

dc=example1,dc=com - Replication Enabled
========================================

Server         : Entries  : M.C. [1] : A.O.M.C. [2] : Port [3] : Encryption [4] : Trust [5] : U.C. [6] : Status [7] : ChangeLog [8] : Group ID [9] : Connected To [10]
---------------:----------:----------:--------------:----------:----------------:-----------:----------:------------:---------------:--------------:-----------------------
myoudrs1:1444  : -- [11]  : 0        : --           : 1898     : Disabled       : --        : --       : Up         : --            : 1            : --
myoudds1:1444  : 102      : 0        : 0            : -- [12]  : Disabled       : Trusted   : --       : Normal     : Enabled       : 1            : myoudrs1:1898 (GID=1)

[1] The number of changes that are still missing on this element (and that have been applied to at least one other server).
[2] Age of oldest missing change: the age (in seconds) of the oldest change that has not yet arrived on this element.
[3] The replication port used to communicate between the servers whose contents are being replicated.
[4] Whether the replication communication initiated by this element is encrypted or not.
[5] Whether the directory server is trusted or not. Updates coming from an untrusted server are discarded and not propagated.
[6] The number of untrusted changes. These are changes generated on this server while it is untrusted.
    Those changes are not propagated to the rest of the topology but are effective on the untrusted server.
[7] The status of the replication on this element.
[8] Whether the external change log is enabled for the base DN on this server or not.
[9] The ID of the replication group to which the server belongs.
[10] The replication server this server is connected to with its group ID between brackets.
[11] Server does not contain replicated data for the suffix.
[12] Server not configured as a replication server (no replication change log).
```

You can see that the Replication Server myoudrs1 has been created, and that myoudrs1 and the Directory Server myoudds1 have been added to the same replication group.

## Directory Server/Service added to existing Replication Server/Service (instanceType=AddDS2RS)

### Create the container

In this example you will create a single container, which will host a single OUD 12c Directory Server/Service.  You will add this Directory Server to the replication group created in the previous section.

The parameter file for creating the container can be found in this project at the following location : samples/oud-add-dir-to-rs.env.  This file contains the following values:

```
instanceType=AddDS2RS
OUD_INSTANCE_NAME=myoudds1b
hostname=myoudds1b
baseDN=dc=example1,dc=com
rootUserDN=<rootUserDN>
rootUserPassword=<Password>
adminUID=admin
adminPassword=<Password>
bindDN1=<rootUserDN>
bindPassword1=<Password>
bindDN2=<rootUserDN>
bindPassword2=<Password>
sourceHost=myoudrs1
initializeFromHost=myoudds1
dsreplication_1=verify --hostname ${sourceHost} --port ${adminConnectorPort} --baseDN ${baseDN} --serverToRemove ${hostname}:${adminConnectorPort}
dsreplication_2=enable --host1 ${hostname} --port1 ${adminConnectorPort} --noReplicationServer1 --host2 ${sourceHost} --port2 ${adminConnectorPort} --replicationPort2 ${replicationPort} --onlyReplicationServer2 --baseDN ${baseDN}
dsreplication_3=initialize --hostSource ${initializeFromHost} --portSource ${adminConnectorPort} --hostDestination ${hostname} --portDestination ${adminConnectorPort} --baseDN ${baseDN}
dsreplication_4=verify --hostname ${hostname} --port ${adminConnectorPort} --baseDN ${baseDN}
dsreplication_5=status --hostname ${hostname} --port ${adminConnectorPort} --baseDN ${baseDN} --dataToDisplay compat-view
```

Create a copy of the file and replace the placeholders <rootUserDN> and <Password> with the required values, for example:

```
rootUserDN=cn=Directory Manager
rootUserPassword=Oracle123
```

Run the following command to create the OUD12c Directory Server container, myoudds1b, and add the Directory Server instance to the replication group.

```
$ docker run -d --network=OUDNet \
--name=myoudds1b \
--volume /scratch/user_projects:/u01/oracle/user_projects \
--env OUD_INSTANCE_NAME=myoudds1b \
--env hostname=myoudds1b \
--env-file ~/oud-add-dir-to-rs.env \
oud-with-patch:12.2.1.4.0
```

Run the following command to check that the container is created and starting:

```
$ docker ps
```

The output should look similar to the following:

```
CONTAINER ID        IMAGE                              COMMAND                  CREATED             STATUS                            PORTS               NAMES
c039a4590a48        oud-with-patch:12.2.1.4.0          "sh -c ${SCRIPT_DIR}…"   4 seconds ago       Up 2 seconds (health: starting)                       myoudds1b
```

Run the following command to tail the log and check the status of the container creation:

```
$ docker logs -f myoudds1b
```

The output should look similar to the following:

```
$ docker logs -f myoudds1b
[Fri Sep 18 14:34:21 UTC 2020] - Create and Start OUD Instance - Initializing...
[Fri Sep 18 14:34:21 UTC 2020] - Environment Variables which would influence OUD Instance setup and configuration
instanceType [AddDS2RS]
hostname [myoudds1b]
ldapPort [1389]
ldapsPort [1636]
rootUserDN [cn=Directory Manager]
baseDN [dc=example1,dc=com]
adminConnectorPort [1444]
httpAdminConnectorPort [1888]
...
[18/Sep/2020:14:34:56 +0000] category=PROTOCOL severity=NOTICE msgID=2556180 msg=Started listening for new connections on HTTP Connection Handler 0.0.0.0 port 1081
[18/Sep/2020:14:34:56 +0000] category=CORE severity=NOTICE msgID=458887 msg=The Directory Server has started successfully
[18/Sep/2020:14:34:56 +0000] category=CORE severity=NOTICE msgID=458891 msg=The Directory Server has sent an alert notification generated by class org.opends.server.core.DirectoryServer (alert type org.opends.server.DirectoryServerStarted, alert ID 458887):  The Directory Server has started successfully
```

When you see the message "The Directory Server has started successfully" the OUD replication server instance has started successfully.  This is reflected in the container listing which will show a STATUS of "healthy" (changed from "health: starting").

```
CONTAINER ID        IMAGE                              COMMAND                  CREATED             STATUS                       PORTS               NAMES
add6660dcb5d        oud-with-patch:12.2.1.4.0          "sh -c ${SCRIPT_DIR}…"   3 minutes ago       Up 3 minutes (healthy)                           myoudds1b
```									

### Validate the container

Validate the replication server by running the dsreplication command.  Issue the following command:

```
$ docker exec -it myoudrs1 \
/u01/oracle/user_projects/myoudrs1/OUD/bin/dsreplication status \
--trustAll \
--hostname myoudrs1 \
--port 1444 \
--adminUID admin \
--dataToDisplay compat-view \
--dataToDisplay rs-connections

Enter the admin password when prompted:

>>>> Specify Oracle Unified Directory LDAP connection parameters

Password for user 'admin': Oracle123
```

Output should be similar to the following:

```
Establishing connections and reading configuration ..... Done.

dc=example1,dc=com - Replication Enabled
========================================

Server          : Entries  : M.C. [1] : A.O.M.C. [2] : Port [3] : Encryption [4] : Trust [5] : U.C. [6] : Status [7] : ChangeLog [8] : Group ID [9] : Connected To [10]
----------------:----------:----------:--------------:----------:----------------:-----------:----------:------------:---------------:--------------:-----------------------
myoudrs1:1444   : -- [11]  : 0        : --           : 1898     : Disabled       : --        : --       : Up         : --            : 1            : --
myoudds1:1444   : 102      : 0        : 0            : -- [12]  : Disabled       : Trusted   : --       : Normal     : Enabled       : 1            : myoudrs1:1898 (GID=1)
myoudds1b:1444  : 102      : 0        : 0            : -- [12]  : Disabled       : Trusted   : --       : Normal     : Enabled       : 1            : myoudrs1:1898 (GID=1)

[1] The number of changes that are still missing on this element (and that have been applied to at least one other server).
[2] Age of oldest missing change: the age (in seconds) of the oldest change that has not yet arrived on this element.
[3] The replication port used to communicate between the servers whose contents are being replicated.
[4] Whether the replication communication initiated by this element is encrypted or not.
[5] Whether the directory server is trusted or not. Updates coming from an untrusted server are discarded and not propagated.
[6] The number of untrusted changes. These are changes generated on this server while it is untrusted.
    Those changes are not propagated to the rest of the topology but are effective on the untrusted server.
[7] The status of the replication on this element.
[8] Whether the external change log is enabled for the base DN on this server or not.
[9] The ID of the replication group to which the server belongs.
[10] The replication server this server is connected to with its group ID between brackets.
[11] Server does not contain replicated data for the suffix.
[12] Server not configured as a replication server (no replication change log).
```

You can see that the new Directory Server myoudds1b has been created and added to the replication group.

## Directory Server/Service (myoudds2b) added to existing Directory Server/Service (myoudds2) (instanceType=AddDS2RS)

### Create the container

In this example you will create a single container, which will host a single OUD 12c Directory/Replication Server/Service.  This server will form part of a new replication group which includes the Directory Server created in the first example (myoudds2).

The parameter file for creating the container can be found in this project at the following location : samples/oud-add-ds_rs.env.  This file contains the following values:

```
instanceType=AddDS2RS
OUD_INSTANCE_NAME=myoudds2b
hostname=myoudds2b
baseDN=dc=example2,dc=com
rootUserDN=<rootUserDN>
rootUserPassword=<Password>
adminUID=admin
adminPassword=<Password>
bindDN1=<rootUserDN>
bindPassword1=<Password>
bindDN2=<rootUserDN>
bindPassword2=<Password>
sourceHost=myoudds2
dsreplication_1=verify --hostname ${sourceHost} --port ${adminConnectorPort} --baseDN ${baseDN} --serverToRemove ${hostname}:${adminConnectorPort}
dsreplication_2=enable --host1 ${sourceHost} --port1 ${adminConnectorPort} --replicationPort1 ${replicationPort} --host2 ${hostname} --port2 ${adminConnectorPort} --replicationPort2 ${replicationPort} --baseDN ${baseDN}
dsreplication_3=initialize --hostSource ${initializeFromHost} --portSource ${adminConnectorPort} --hostDestination ${hostname} --portDestination ${adminConnectorPort} --baseDN ${baseDN}
dsreplication_4=verify --hostname ${hostname} --port ${adminConnectorPort} --baseDN ${baseDN}
dsreplication_5=status --hostname ${hostname} --port ${adminConnectorPort} --baseDN ${baseDN} --dataToDisplay compat-view
post_dsreplication_dsconfig_1=set-replication-domain-prop --domain-name ${baseDN} --set group-id:2
post_dsreplication_dsconfig_2=set-replication-server-prop --set group-id:2
```

Create a copy of the file and replace the placeholders <rootUserDN> and <Password> with the required values, for example:

```
rootUserDN=cn=Directory Manager
rootUserPassword=Oracle123
```								

Run the following command to create the OUD12c Directory Server container, myoudds2b, and add this Directory Server and the existing myoudds2 instance to the replication group.

```
$ docker run -d --network=OUDNet \
--name=myoudds2b \
--volume /scratch/user_projects:/u01/oracle/user_projects \
--env OUD_INSTANCE_NAME=myoudds2b \
--env hostname=myoudds2b \
--env-file ~/oud-add-ds_rs.env \
oud-with-patch:12.2.1.4.0
```									

Run the following command to check that the container is created and starting:

```
$ docker ps
```

The output should look similar to the following:

```
CONTAINER ID        IMAGE                              COMMAND                  CREATED             STATUS                            PORTS               NAMES
4ac271b366ff        oud-with-patch:12.2.1.4.0          "sh -c ${SCRIPT_DIR}…"   3 seconds ago       Up 2 seconds (health: starting)                       myoudds2b
```

Run the following command to tail the log and check the status of the container creation:

```
$ docker logs -f myoudds2b
```

The output should look similar to the following:

```
$ docker logs -f myoudds2b
[Fri Sep 18 15:38:32 UTC 2020] - Create and Start OUD Instance - Initializing...
[Fri Sep 18 15:38:32 UTC 2020] - Environment Variables which would influence OUD Instance setup and configuration
instanceType [AddDS2RS]
hostname [myoudds2b]
ldapPort [1389]
ldapsPort [1636]
rootUserDN [cn=Directory Manager]
baseDN [dc=example2,dc=com]
adminConnectorPort [1444]
httpAdminConnectorPort [1888]
httpPort [1080]
httpsPort [1081]
...
[18/Sep/2020:15:39:04 +0000] category=PROTOCOL severity=NOTICE msgID=2556180 msg=Started listening for new connections on HTTP Connection Handler 0.0.0.0 port 1081
[18/Sep/2020:15:39:04 +0000] category=CORE severity=NOTICE msgID=458887 msg=The Directory Server has started successfully
[18/Sep/2020:15:39:04 +0000] category=CORE severity=NOTICE msgID=458891 msg=The Directory Server has sent an alert notification generated by class org.opends.server.core.DirectoryServer (alert type org.opends.server.DirectoryServerStarted, alert ID 458887):  The Directory Server has started successfully
```

When you see the message "The Directory Server has started successfully" the OUD server instances have started successfully.  This is reflected in the container listing which will show a STATUS of "healthy" (changed from "health: starting").

```
CONTAINER ID        IMAGE                              COMMAND                  CREATED             STATUS                       PORTS               NAMES
4ac271b366ff        oud-with-patch:12.2.1.4.0          "sh -c ${SCRIPT_DIR}…"   8 minutes ago       Up 8 minutes (healthy)                           myoudds2b
```									
								
### Validate the container

Validate the replication server by running the dsreplication command.  Issue the following command:

```
$ docker exec -it myoudds2 \
/u01/oracle/user_projects/myoudrs1/OUD/bin/dsreplication status \
--trustAll \
--hostname myoudds2 \
--port 1444 \
--adminUID admin \
--dataToDisplay compat-view \
--dataToDisplay rs-connections

Enter the admin password when prompted:

>>>> Specify Oracle Unified Directory LDAP connection parameters

Password for user 'admin': Oracle123
```

Output should be similar to the following:

```
Establishing connections and reading configuration ..... Done.

dc=example2,dc=com - Replication Enabled
========================================

Server          : Entries : M.C. [1] : A.O.M.C. [2] : Port [3] : Encryption [4] : Trust [5] : U.C. [6] : Status [7] : ChangeLog [8] : Group ID [9] : Connected To [10]
----------------:---------:----------:--------------:----------:----------------:-----------:----------:------------:---------------:--------------:------------------------
myoudds2:1444   : 102     : 0        : 0            : 1898     : Disabled       : Trusted   : --       : Normal     : Enabled       : 1            : myoudds2:1898 (GID=1)
myoudds2b:1444  : 102     : 0        : 0            : 1898     : Disabled       : Trusted   : --       : Normal     : Enabled       : 2            : myoudds2b:1898 (GID=2)

Replication Server [11] : RS #1 : RS #2
------------------------:-------:------
myoudds2:1898 (#1)      : --    : Yes
myoudds2b:1898 (#2)     : Yes   : --

[1] The number of changes that are still missing on this element (and that have been applied to at least one other server).
[2] Age of oldest missing change: the age (in seconds) of the oldest change that has not yet arrived on this element.
[3] The replication port used to communicate between the servers whose contents are being replicated.
[4] Whether the replication communication initiated by this element is encrypted or not.
[5] Whether the directory server is trusted or not. Updates coming from an untrusted server are discarded and not propagated.
[6] The number of untrusted changes. These are changes generated on this server while it is untrusted.
    Those changes are not propagated to the rest of the topology but are effective on the untrusted server.
[7] The status of the replication on this element.
[8] Whether the external change log is enabled for the base DN on this server or not.
[9] The ID of the replication group to which the server belongs.
[10] The replication server this server is connected to with its group ID between brackets.
[11] This table represents the connections between the replication servers.  The headers of the columns use a number as identifier for each replication server.  See the values of the first column to identify the corresponding replication server for each number.
```

You can see that myoudds2 and the newly created myoudds2b have been added to the replication group, and are both acting as replication and directory servers.

## Directory Client to run CLIs like ldapsearch, dsconfig, and dsreplication

### LDAPSEARCH

The ldapsearch command can be executed to retrieve details from the Directory and Proxy instances created in the previous sections. For example:

```
$ docker run -it --rm --network=OUDNet \
--name=MyOUDClient \
--volume /scratch/user_projects:/u01/oracle/user_projects \
oud-with-patch:12.2.1.4.0 \
/u01/oracle/oud/bin/ldapsearch \
--hostname myoudp \
--port 1389 \
--bindDN "cn=Directory Manager" \
--bindPassword "Oracle123" \
--baseDN "" \
--searchScope base \
"(objectClass=*)" dn + | grep naming
```

This returns the following output:

```
ds-private-naming-contexts: cn=schema
namingContexts: dc=example1,dc=com
namingContexts: dc=example2,dc=com
```

### DSCONFIG

To run the dsconfig command issue the following:

```
$ docker run -it --rm --network=OUDNet \
--name=MyOUDClient \
--volume /scratch/user_projects:/u01/oracle/user_projects \
oud-with-patch:12.2.1.4.0 \
/u01/oracle/oud/bin/dsconfig \
--hostname myoudp \
--port 1444 \
--portProtocol LDAP \
--bindDN "cn=Directory Manager" \
--bindPassword "Oracle123" \
--trustAll --advanced --displayCommand

Enter the admin password when prompted:

>>>> Specify Oracle Unified Directory LDAP connection parameters

Password for user 'admin': Oracle123
```

Output should be similar to the following:

```
>>>> Oracle Unified Directory configuration console main menu

What do you want to configure?

    1)  General Configuration             7)   Virtualization
    2)  Authentication and authorization  8)   Load Balancing
    3)  Schema                            9)   Distribution
    4)  Replication                       10)  Integration
    5)  Local Data Source                 11)  Http
    6)  Remote Data Source

    q)  quit

Enter choice:
```									

### DSREPLICATION

Check the replication status for the replication instances created in the previous sections:

Run the following command:

```
$ docker run -it --rm --network=OUDNet \
--name=MyOUDClient \
--volume /scratch/user_projects:/u01/oracle/user_projects \
oud-with-patch:12.2.1.4.0 \
/u01/oracle/oud/bin/dsreplication status \
--hostname myoudds1b \
--port 1444 \
--portProtocol LDAP \
--bindDN "cn=Directory Manager" \
--trustAll

Enter the admin password when prompted:

>>>> Specify Oracle Unified Directory LDAP connection parameters

Password for user 'admin': Oracle123
```

Output should be similar to the following:

```
Establishing connections and reading configuration ...... Done.

dc=example1,dc=com - Replication Enabled
========================================

Server          : Entries : M.C. [1] : A.O.M.C. [2] : Port [3] : Status [4] : Conflicts [5]
----------------:---------:----------:--------------:----------:------------:--------------
myoudrs1:1444   : -- [6]  : 0        : --           : 1898     : Up         : --
myoudds1:1444   : 102     : 0        : 0            : -- [7]   : Normal     : 0
myoudds1b:1444  : 102     : 0        : 0            : -- [7]   : Normal     : 0

[1] The number of changes that are still missing on this element (and that have been applied to at least one other server).
[2] Age of oldest missing change: the age (in seconds) of the oldest change that has not yet arrived on this element.
[3] The replication port used to communicate between the servers whose contents are being replicated.
[4] The status of the replication on this element.
[5] The number of currently unresolved replication conflicts.
[6] Server does not contain replicated data for the suffix.
[7] Server not configured as a replication server (no replication change log).
```

## Directory Server/Service (instanceType=Directory) with dstune configuration options

In the examples below you will create two containers, which will each host a single OUD 12c Directory Server/Service.  In this case you pass in dstune parameters.

### Create and validate the first container

The parameter file for creating the first container can be found in this project at the following location : samples/oud-dir-dstune.env.  This file contains the following values:

```
instanceType=Directory
OUD_INSTANCE_NAME=myouddstune
hostname=myoudds1
baseDN=dc=example1,dc=com
rootUserDN=<rootUserDN>
rootUserPassword=<Password>
sampleData=100
dstune_1=mem-based --memory 2.5g --targetTool server
dstune_2=data-based --entryNumber 10000 --entrySize 40
```

Create a copy of the file and replace the placeholders <rootUserDN> and <Password> with the required values, for example:

```
rootUserDN=cn=Directory Manager
rootUserPassword=Oracle123
```

Run the following command to create the OUD12c Directory Server container, myouddstune:

```
$ docker run -d --network=OUDNet \
--name=myouddstune \
--volume /scratch/user_projects:/u01/oracle/user_projects \
--env-file ~/oud-dir-dstune.env \
oud-with-patch:12.2.1.4.0
```

Run the following command to check that the container is created and starting:

```
$ docker ps
```

The output should look similar to the following:

```
CONTAINER ID        IMAGE                              COMMAND                  CREATED             STATUS                            PORTS               NAMES
dbfabfa85fd0        oud-with-patch:12.2.1.4.0          "sh -c ${SCRIPT_DIR}…"   6 seconds ago       Up 2 seconds (health: starting)                       myouddstune
```

Run the following command to tail the log and check the status of the container creation:

```
$ docker logs -f myouddstune
```

The output should look similar to the following:

```
$ docker logs myouddstune
[Mon Sep 21 12:27:10 UTC 2020] - Create and Start OUD Instance - Initializing...
[Mon Sep 21 12:27:10 UTC 2020] - Environment Variables which would influence OUD Instance setup and configuration
instanceType [Directory]
hostname [myoudds1]
ldapPort [1389]
ldapsPort [1636]
rootUserDN [cn=Directory Manager]
baseDN [dc=example1,dc=com]
adminConnectorPort [1444]
httpAdminConnectorPort [1888]
...
[Mon Sep 21 12:28:01 UTC 2020] - dstune - Starting

Calculating Tuning Settings ..... Done.
Updating the tuning properties ..... Done.
Updating scripts ..... Done.
[Mon Sep 21 12:28:07 UTC 2020] - execStatus [0]

Calculating tuning settings based on the provided entry number ..... Done.

Memory Requirements Information for the Provided Entries:

System Memory:                   14.06 GB
Recommended Min. Memory:         1.02 GB (7.23 % of System Memory)
                                 0.25 GB (Java Heap) +  0.76 GB (Estimated File
                                 System Cache)
Memory for Optimal Performance:  3.29 GB (23.39 % of System Memory)
                                 2.53 GB (Java Heap) +  0.76 GB (Estimated File
                                 System Cache)
================================================================================
Recommended Memory:              3.29 GB (23.39 % of System Memory)
                                 2.53 GB (Java Heap) +  0.76 GB (Estimated File
                                 System Cache)

Based on the provided data and the available memory on the machine, the OUD
server process will be tuned to use 3.29 GB (23.39 % of System Memory)
2.53 GB (Java Heap) +  0.76 GB (Estimated File System Cache)

Updating the tuning properties ..... Done.
Updating scripts ..... Done.
[Mon Sep 21 12:28:13 UTC 2020] - execStatus [0]

Tool          : Tuning Value
--------------:-------------------------------------------------------------------
server        : -Xms2586m -Xmx2586m -d64 -XX:+UseCompressedOops -server -Xmn512m
              : -XX:MaxTenuringThreshold=1 -XX:+UseConcMarkSweepGC
              : -XX:CMSInitiatingOccupancyFraction=55
import-ldif   : Automatic Tuning
export-ldif   : Automatic Tuning
rebuild-index : Automatic Tuning
verify-index  : Automatic Tuning

[Mon Sep 21 12:28:16 UTC 2020] - Executed all configured dstune commands.
[Mon Sep 21 12:28:16 UTC 2020] - Setting the flag for restarting OUD Instance to have JVM parameters in affect
...
[21/Sep/2020:12:28:40 +0000] category=PROTOCOL severity=NOTICE msgID=2556180 msg=Started listening for new connections on HTTP Connection Handler 0.0.0.0 port 1081
[21/Sep/2020:12:28:40 +0000] category=CORE severity=NOTICE msgID=458887 msg=The Directory Server has started successfully
[21/Sep/2020:12:28:40 +0000] category=CORE severity=NOTICE msgID=458891 msg=The Directory Server has sent an alert notification generated by class org.opends.server.core.DirectoryServer (alert type org.opends.server.DirectoryServerStarted, alert ID 458887):  The Directory Server has started successfully
```

When you see the message "The Directory Server has started successfully" the OUD instance has started successfully.  This is reflected in the container listing which will show a STATUS of "healthy" (changed from "health: starting").

```
CONTAINER ID        IMAGE                              COMMAND                  CREATED             STATUS                    PORTS               NAMES
dbfabfa85fd0        oud-with-patch:12.2.1.4.0          "sh -c ${SCRIPT_DIR}…"   16 minutes ago      Up 16 minutes (healthy)                       myouddstune
```
									
**Note:** additional logging shows the dstune utility being run as part of the installation.
									
Run the following command to list the tuning parameters for the OUD instance:

```
$ docker run -it --rm --network=OUDNet \
--name=MyOUDClient \
--volume /scratch/user_projects:/u01/oracle/user_projects \
oud-with-patch:12.2.1.4.0 \
/u01/oracle/user_projects/myouddstune/OUD/bin/dstune list
```

You should see output similar to that shown below:

```
Tool          : Tuning Value
--------------:-------------------------------------------------------------------
server        : -Xms2586m -Xmx2586m -d64 -XX:+UseCompressedOops -server -Xmn512m
              : -XX:MaxTenuringThreshold=1 -XX:+UseConcMarkSweepGC
              : -XX:CMSInitiatingOccupancyFraction=55
import-ldif   : Automatic Tuning
export-ldif   : Automatic Tuning
rebuild-index : Automatic Tuning
verify-index  : Automatic Tuning
```

Select 'q' to quit the dstune utility.

### Create and validate the second container

The parameter file for creating the second container can be found in this project at the following location : samples/oud-dir-dstune-autotune.env.  This file contains the following values:

```
instanceType=Directory
OUD_INSTANCE_NAME=myoudautotune
hostname=myoudds1
baseDN=dc=example1,dc=com
rootUserDN=<rootUserDN>
rootUserPassword=<Password>
dstune_1=set-runtime-options --value autotune --targetTool server
```

Create a copy of the file and replace the placeholders <rootUserDN> and <Password> with the required values, for example:

```
rootUserDN=cn=Directory Manager
rootUserPassword=Oracle123
```

Run the following command to create the OUD12c Directory Server container, myoudautotune:

```
$ docker run -d --network=OUDNet \
--name=myoudautotune \
--volume /scratch/user_projects:/u01/oracle/user_projects \
--env-file ~/oud-dir-dstune-autotune.env \
oud-with-patch:12.2.1.4.0
```

Run the following command to check that the container is created and starting:

```
$ docker ps
```

The output should look similar to the following:

```
CONTAINER ID        IMAGE                              COMMAND                  CREATED             STATUS                            PORTS               NAMES
0851a5487c19        oud-with-patch:12.2.1.4.0          "sh -c ${SCRIPT_DIR}…"   3 seconds ago       Up 2 seconds (health: starting)                       myoudautotune
```

Run the following command to tail the log and check the status of the container creation:

```
$ docker logs -f myoudautotune
```

The output should look similar to the following:

```
$ docker logs myoudautotune
[Mon Sep 21 13:33:11 UTC 2020] - Create and Start OUD Instance - Initializing...
[Mon Sep 21 13:33:11 UTC 2020] - Environment Variables which would influence OUD Instance setup and configuration
instanceType [Directory]
hostname [myoudds1]
ldapPort [1389]
ldapsPort [1636]
rootUserDN [cn=Directory Manager]
baseDN [dc=example1,dc=com]
adminConnectorPort [1444]
httpAdminConnectorPort [1888]
httpPort [1080]
httpsPort [1081]
...
[Mon Sep 21 13:33:54 UTC 2020] - dstune - Starting

Updating the tuning properties ..... Done.

The server will be automatically tuned the next time it will be restarted.
[Mon Sep 21 13:34:00 UTC 2020] - execStatus [0]

Tool          : Tuning Value
--------------:-------------------------------------------------------------------
server        : Automatic Tuning
import-ldif   : Default JVM
export-ldif   : Default JVM
rebuild-index : Default JVM
verify-index  : Default JVM

[Mon Sep 21 13:34:02 UTC 2020] - Executed all configured dstune commands.
...
[21/Sep/2020:13:34:32 +0000] category=PROTOCOL severity=NOTICE msgID=2556180 msg=Started listening for new connections on HTTP Connection Handler 0.0.0.0 port 1081
[21/Sep/2020:13:34:32 +0000] category=CORE severity=NOTICE msgID=458887 msg=The Directory Server has started successfully
[21/Sep/2020:13:34:32 +0000] category=CORE severity=NOTICE msgID=458891 msg=The Directory Server has sent an alert notification generated by class org.opends.server.core.DirectoryServer (alert type org.opends.server.DirectoryServerStarted, alert ID 458887):  The Directory Server has started successfully
										When you see the message "The Directory Server has started successfully" the OUD instance has started successfully.  This is reflected in the container listing which will show a STATUS of "healthy" (changed from "health: starting").
										CONTAINER ID        IMAGE                              COMMAND                  CREATED             STATUS                       PORTS               NAMES
0851a5487c19        oud-with-patch:12.2.1.4.0          "sh -c ${SCRIPT_DIR}…"   13 minutes ago      Up 13 minutes (healthy)                          myoudautotune
```

**Note:** additional logging shows the dstune utility being run as part of the installation.
									
Run the following command to list the tuning parameters for the OUD instance:

```
$ docker run -it --rm --network=OUDNet \
--name=MyOUDClient \
--volume /scratch/user_projects:/u01/oracle/user_projects \
oud-with-patch:12.2.1.4.0 \
/u01/oracle/user_projects/myoudautotune/OUD/bin/dstune list
```

You should see output similar to that shown below:

```
Tool          : Tuning Value
--------------:-------------------------------------------------------------------
server        : Automatic Tuning
import-ldif   : Default JVM
export-ldif   : Default JVM
rebuild-index : Default JVM
verify-index  : Default JVM
```

Select 'q' to quit the dstune utility.

## Access interfaces (LDAP / LDAPS / HTTP / HTTPS) exposed by OUD container

You can use the `docker inspect` command to return various configuration parameters from your container.

To return the full list of parameters run the following command:

```
docker inspect <container-name>
```

For example:

```
$ docker inspect myoudds1
```

From the list returned you can select specific parameters to interrogate using the following syntax:

```
docker inspect --format '{{<paramname>}}' <container-name>
```

For example, to return the IP address for your containers:

```
$ docker inspect --format '{{.NetworkSettings.Networks.OUDNet.IPAddress}}' myoudds1 myoudds2 myoudds1b myoudds2b
```

Returns:

```
172.18.0.2
172.18.0.3
172.18.0.6
172.18.0.7
```

You can return multiple values:

```
$ docker inspect --format '{{.Name}} : {{.NetworkSettings.Networks.OUDNet.IPAddress}}' myoudds1 myoudds2 myoudds1b myoudds2b
```

Returns:

```
/myoudds1 : 172.18.0.2
/myoudds2 : 172.18.0.3
/myoudds1b : 172.18.0.6
/myoudds2b : 172.18.0.7
```

When container ports are mapped to the host port (through -p parameter for `docker run`), you can access those ports using the hostname as well.

Using ldapsearch CLI, access to ldapPort and ldapsPort can be validated.

Using dsconfig CLI, access to adminConnectorPort and httpAdminConnectorPort can be validated.

Using REST Client, access to httpPort and httpsPort can be validated.

## Removing an OUD Container

If you need to remove an OUD Docker container perform the following steps:
							
Stop the OUD container using the following command:

```
$ docker stop <containername>
```

For example:

```
$ docker stop myoudds1
```

Remove the OUD container using the following command:

```
$ docker rm <containername>
```

For example:

```
$ docker rm myoudds1
```
