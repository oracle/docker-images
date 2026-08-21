# Connecting to an Oracle RAC Database
Follow this document to validate and connect to Oracle RAC Container Database.

## Using this documentation
- [Connecting to an Oracle RAC Database](#connecting-to-an-oracle-rac-database)
  - [Using this documentation](#using-this-documentation)
  - [Validating Oracle RAC Containers](#validating-oracle-rac-containers)
  - [Validating Oracle Grid Infrastructure](#validating-oracle-grid-infrastructure)
  - [Validating Oracle RAC Database](#validating-oracle-rac-database)
  - [Debugging Oracle RAC Containers](#debugging-oracle-rac-containers)
  - [Optional Host SSH Access](#optional-host-ssh-access)
  - [Client Connection](#client-connection)
  - [License](#license)
  - [Copyright](#copyright)

## Validating Oracle RAC Containers
First Validate if Container is healthy or not by running-
```bash
podman ps -a

CONTAINER ID  IMAGE                                        COMMAND                                       CREATED         STATUS                     PORTS                     NAMES
598385416fd7  localhost/oracle/rac-dnsserver:latest        /bin/sh -c exec $...                          55 minutes ago  Up 55 minutes (healthy)                              rac-dnsserver
835e3d113898  localhost/oracle/rac-storage-server:latest                                                 55 minutes ago  Up 55 minutes (healthy)                              racnode-storage
9ba7bbee9095  localhost/oracle/database-rac:23.26ai                                                      52 minutes ago  Up 52 minutes (healthy)                              racnodep1
ebbf520b0c95  localhost/oracle/database-rac:23.26ai                                                      52 minutes ago  Up 52 minutes (healthy)                              racnodep2
36df843594d9  localhost/oracle/client-cman:23.26ai         /bin/sh -c exec $...                          12 minutes ago  Up 12 minutes (healthy)     0.0.0.0:1521->1521/tcp   racnodepc1-cman
```

Look for `(healthy)` next to container names under `STATUS` section.

To connect to the container execute following command:
```bash
podman exec -i -t racnodep1 /bin/bash
```
## Optional Host SSH Access

The standard RAC `podman create` examples do not publish container port 22 to the host. The image installs OpenSSH packages for RAC setup, but publishing a port does not by itself create a login account, credentials, or guarantee that `sshd` is listening. For routine shell access, use:

```bash
podman exec -it racnodep1 /bin/bash
```

If SSH access from the host is specifically required, publish a unique host port when creating each container:

```bash
podman create ... -p 2222:22 ...
```

Then connect with:

```bash
ssh -p 2222 <container-os-user>@localhost
```

Use an OS user and SSH key or password configured in the image. Assign a different host port for each RAC node (for example, `2222` and `2223`). Avoid `-p 22:22` unless host port 22 is free; it commonly conflicts with the host SSH service. An existing container must be recreated to add this port mapping.

## Validating Oracle Grid Infrastructure
Validate if Oracle Grid is up and running from within Container-
```bash
su - grid
#Verify the status of Oracle Clusterware stack:
[grid@racnodep1 ~]$ crsctl check cluster -all
**************************************************************
racnodep1:
CRS-4537: Cluster Ready Services is online
CRS-4529: Cluster Synchronization Services is online
CRS-4533: Event Manager is online
**************************************************************
racnodep2:
CRS-4537: Cluster Ready Services is online
CRS-4529: Cluster Synchronization Services is online
CRS-4533: Event Manager is online
**************************************************************

[grid@racnodep1 u01]$ crsctl check crs
CRS-4638: Oracle High Availability Services is online
CRS-4537: Cluster Ready Services is online
CRS-4529: Cluster Synchronization Services is online
CRS-4533: Event Manager is online

[grid@racnodep1 ~]$ crsctl stat res -t
--------------------------------------------------------------------------------
Name           Target  State        Server                   State details
--------------------------------------------------------------------------------
Local Resources
--------------------------------------------------------------------------------
ora.LISTENER.lsnr
               ONLINE  ONLINE       racnodep1                STABLE
               ONLINE  ONLINE       racnodep2                STABLE
ora.chad
               ONLINE  ONLINE       racnodep1                STABLE
               ONLINE  ONLINE       racnodep2                STABLE
ora.helper
               OFFLINE OFFLINE      racnodep1                IDLE,STABLE
               OFFLINE OFFLINE      racnodep2                IDLE,STABLE
ora.net1.network
               ONLINE  ONLINE       racnodep1                STABLE
               ONLINE  ONLINE       racnodep2                STABLE
ora.ons
               ONLINE  ONLINE       racnodep1                STABLE
               ONLINE  ONLINE       racnodep2                STABLE
--------------------------------------------------------------------------------
Cluster Resources
--------------------------------------------------------------------------------
ora.ASMNET1LSNR_ASM.lsnr(ora.asmgroup)
      1        ONLINE  ONLINE       racnodep1                STABLE
      2        ONLINE  ONLINE       racnodep2                STABLE
ora.ASMNET2LSNR_ASM.lsnr(ora.asmgroup)
      1        ONLINE  ONLINE       racnodep1                STABLE
      2        ONLINE  ONLINE       racnodep2                STABLE
ora.DATA.dg(ora.asmgroup)
      1        ONLINE  ONLINE       racnodep1                STABLE
      2        ONLINE  ONLINE       racnodep2                STABLE
ora.LISTENER_SCAN1.lsnr
      1        ONLINE  ONLINE       racnodep2                STABLE
ora.LISTENER_SCAN2.lsnr
      1        ONLINE  ONLINE       racnodep1                STABLE
ora.asm(ora.asmgroup)
      1        ONLINE  ONLINE       racnodep1                Started,STABLE
      2        ONLINE  ONLINE       racnodep2                Started,STABLE
ora.asmnet1.asmnetwork(ora.asmgroup)
      1        ONLINE  ONLINE       racnodep1                STABLE
      2        ONLINE  ONLINE       racnodep2                STABLE
ora.asmnet2.asmnetwork(ora.asmgroup)
      1        ONLINE  ONLINE       racnodep1                STABLE
      2        ONLINE  ONLINE       racnodep2                STABLE
ora.cdp1.cdp
      1        OFFLINE OFFLINE                               STABLE
ora.cdp2.cdp
      1        OFFLINE OFFLINE                               STABLE
ora.cvu
      1        ONLINE  ONLINE       racnodep2                STABLE
ora.cvuhelper
      1        OFFLINE OFFLINE                               STABLE
ora.orclcdb.db
      1        ONLINE  ONLINE       racnodep1                Open,HOME=/u01/app/o
                                                             racle/product/26ai/d
                                                             bhome_1,STABLE
      2        ONLINE  ONLINE       racnodep2                Open,HOME=/u01/app/o
                                                             racle/product/26ai/d
                                                             bhome_1,STABLE
ora.orclcdb.orclcdb_orclpdb.svc
      1        ONLINE  ONLINE       racnodep2                STABLE
      2        ONLINE  ONLINE       racnodep1                STABLE
ora.orclcdb.orclpdb.pdb
      1        ONLINE  ONLINE       racnodep1                READ WRITE,STABLE
      2        ONLINE  ONLINE       racnodep2                READ WRITE,STABLE
ora.orclcdb.soepdb.svc
      1        ONLINE  ONLINE       racnodep2                STABLE
      2        ONLINE  ONLINE       racnodep1                STABLE
ora.racnodep1.vip
      1        ONLINE  ONLINE       racnodep1                STABLE
ora.racnodep2.vip
      1        ONLINE  ONLINE       racnodep2                STABLE
ora.rhpserver
      1        OFFLINE OFFLINE                               STABLE
ora.scan1.vip
      1        ONLINE  ONLINE       racnodep2                STABLE
ora.scan2.vip
      1        ONLINE  ONLINE       racnodep1                STABLE
--------------------------------------------------------------------------------

[grid@racnodep1 ~]$ olsnodes -n
racnodep1       1
racnodep2       2
```
## Validating Oracle RAC Database
Validate Oracle RAC Database from within Container-
```bash
su - oracle

#Confirm the status of Oracle Database instances:
[oracle@racnodep1 ~]$  srvctl status database -d ORCLCDB
Instance ORCLCDB1 is running on node racnodep1
Instance ORCLCDB2 is running on node racnodep2

# Validate network configuration and connectivity:
[oracle@racnodep1 ~]$ srvctl config scan
SCAN name: racnodepc1-scan, Network: 1
Subnet IPv4: 10.0.20.0/255.255.255.0/eth0, static
Subnet IPv6: 
SCAN 1 IPv4 VIP: 10.0.20.237
SCAN VIP is enabled.
SCAN 2 IPv4 VIP: 10.0.20.238
SCAN VIP is enabled.
SCAN 3 IPv4 VIP: 10.0.20.236
SCAN VIP is enabled.
```

## Debugging Oracle RAC Containers
If the install fails for any reason, log in to container using the above command and check `/var/tmp/oracle_db_setup.log`. You can also review the Grid Infrastructure logs located at `$GRID_BASE/diag/crs` and check for failure logs. If the failure occurred during the database creation then check the database logs.


## Optional Host SSH Access

The Oracle RAC container image includes `openssh-server` (installed via `setupLinuxEnv.sh`). This is useful when you need to:

* SSH into a running RAC node from the host or another machine for diagnostics.
* Verify inter-node SSH trust between RAC nodes (used internally by cluster setup scripts).

### Enabling SSH login to a container

The sshd binary is present in the image but **not started automatically** and port 22 is **not exposed by default**. To enable external SSH access follow these steps:

1. **When creating the container, publish an unused host port mapped to container port 22:**

   Use an offset-based convention so each RAC node gets a unique host port. A common pattern is `2200 + node_number`:

   ```bash
   # Node 1 -> host port 2201, Node 2 -> host port 2202, etc.
   podman run -p 2201:22 \
     --name racnodep1 \
     <rac_image_name>

   podman run -p 2202:22 \
     --name racnodep2 \
     <rac_image_name>
   ```

2. **Start sshd inside the container** (if not already running). From the host:

   ```bash
   podman exec -i racnodep1 /usr/sbin/sshd
   ```

   The first start of sshd requires SSH host keys in `/etc/ssh/` -- run this once on each container:

   ```bash
   podman exec -i racnodep1 ssh-keygen -A
   ```

3. **Connect from the host using the unique host port:**

   ```bash
   # Node 1 (host port 2201), Node 2 (host port 2202)
   ssh -p 2201 grid@<host-ip>   # to racnodep1
   ssh -p 2202 grid@<host-ip>   # to racnodep2
   ```

### SSH trust between RAC nodes (inter-node connectivity)

RAC relies on password-less SSH between `grid` and `oracle` users across all cluster nodes for inter-client communication, Oracle Restart, and CRS operations. The container scripts handle this automatically:

* During normal RAC deployment the `orasshsetup.py` script sets up SSH trust keys between all nodes (grid/grid, oracle/oracle).
* If you provide `SSH_PRIVATE_KEY` and `SSH_PUBLIC_KEY`, those keys are distributed to every node in the cluster.

For details on these environment variables, see [Environment Variables Explained for Oracle RAC on Podman](ENVIRONMENTVARIABLES.md).


## Client Connection
* If you are using the podman network created using MACVLAN driver, and you have configured DNS appropriately, then you can connect using the public Single Client Access (SCAN) listener directly from any external client. To connect with the SCAN, use the following connection string, where `<scan_name>` is the SCAN name for the database, and `<ORACLE_SID>` is the database system identifier:

   ```bash
   system/<password>@//<scan_name>:1521/<ORACLE_SID>
   ```

* If you are using a connection manager and exposed the port 1521 on the host, then connect from an external client using the following connection string, where `<container_host>` is the host container, and `<ORACLE_SID>` is the database system identifier:

   ```bash
   system/<password>@//<container_host>:1521/<ORACLE_SID>
   ```
* If you are using bridge driver and not using connection manager, you need to connect application to the same bridge network which you are using for Oracle RAC.
## License

All scripts and files hosted in this repository which are required to build the container  images are, unless otherwise noted, released under UPL 1.0 license.

## Copyright

Copyright (c) 2014-2025 Oracle and/or its affiliates.
