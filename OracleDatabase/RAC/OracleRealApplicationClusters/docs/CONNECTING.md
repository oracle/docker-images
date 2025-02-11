# Connecting to an Oracle RAC Database
Follow this document to validate and connect to Oracle RAC Container Database.

## Using this documentation
- [Connecting to an Oracle RAC Database](#connecting-to-an-oracle-rac-database)
  - [Using this documentation](#using-this-documentation)
  - [Validating Oracle RAC Containers](#validating-oracle-rac-containers)
  - [Validating Oracle Grid Infrastructure](#validating-oracle-grid-infrastructure)
  - [Validating Oracle RAC Database](#validating-oracle-rac-database)
  - [Debugging Oracle RAC Containers](#debugging-oracle-rac-containers)
  - [Client Connection](#client-connection)
  - [License](#license)
  - [Copyright](#copyright)

## Validating Oracle RAC Containers
First Validate if Container is healthy or not by running-
```bash
podman ps -a

CONTAINER ID  IMAGE                                        COMMAND                                       CREATED         STATUS                     PORTS                    NAMES
598385416fd7  localhost/oracle/rac-dnsserver:latest        /bin/sh -c exec $...                          55 minutes ago  Up 55 minutes (healthy)                            rac-dnsserver
835e3d113898  localhost/oracle/rac-storage-server:latest                                                55 minutes ago  Up 55 minutes (healthy)                            racnode-storage
9ba7bbee9095  localhost/oracle/database-rac:21c                                                      52 minutes ago  Up 52 minutes (healthy)                            racnodep1
ebbf520b0c95  localhost/oracle/database-rac:21c                                                      52 minutes ago  Up 52 minutes (healthy)                            racnodep2
36df843594d9  localhost/oracle/client-cman:21.3.0          /bin/sh -c exec $...                          12 minutes ago  Up 12 minutes (healthy)  0.0.0.0:1521->1521/tcp  racnodepc1-cman
```

Look for `(healthy)` next to container names under `STATUS` section.

To connect to the container execute following command:
```bash
podman exec -i -t racnodep1 /bin/bash
```
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

[grid@racnodep1 u01]$ crsctl stat res -t
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
               OFFLINE OFFLINE      racnodep1                STABLE
               OFFLINE OFFLINE      racnodep2                STABLE
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
      1        ONLINE  ONLINE       racnodep1                STABLE
ora.LISTENER_SCAN2.lsnr
      1        ONLINE  ONLINE       racnodep1                STABLE
ora.LISTENER_SCAN3.lsnr
      1        ONLINE  ONLINE       racnodep2                STABLE
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
      1        ONLINE  ONLINE       racnodep1                STABLE
ora.cdp2.cdp
      1        ONLINE  ONLINE       racnodep1                STABLE
ora.cdp3.cdp
      1        ONLINE  ONLINE       racnodep2                STABLE
ora.cvu
      1        ONLINE  ONLINE       racnodep1                STABLE
ora.orclcdb.db
      1        ONLINE  ONLINE       racnodep1                Open,HOME=/u01/app/o
                                                             racle/product/23ai/db
                                                             home_1,STABLE
      2        ONLINE  ONLINE       racnodep2                Open,HOME=/u01/app/o
                                                             racle/product/23ai/db
                                                             home_1,STABLE
ora.orclcdb.orclpdb.pdb
      1        ONLINE  ONLINE       racnodep1                READ WRITE,STABLE
      2        ONLINE  ONLINE       racnodep2                READ WRITE,STABLE
ora.orclcdb.soepdb.svc
      1        ONLINE  ONLINE       racnodep1                STABLE
      2        ONLINE  ONLINE       racnodep2                STABLE
ora.racnodep1.vip
      1        ONLINE  ONLINE       racnodep1                STABLE
ora.racnodep2.vip
      1        ONLINE  ONLINE       racnodep2                STABLE
ora.rhpserver
      1        OFFLINE OFFLINE                               STABLE
ora.scan1.vip
      1        ONLINE  ONLINE       racnodep1                STABLE
ora.scan2.vip
      1        ONLINE  ONLINE       racnodep1                STABLE
ora.scan3.vip
      1        ONLINE  ONLINE       racnodep2                STABLE
--------------------------------------------------------------------------------

/u01/app/21c/grid/bin/olsnodes -n
racnodep1       1
racnodep2       2
```
## Validating Oracle RAC Database
Validate Oracle RAC Database from within Container-
```bash
su - oracle

#Confirm the status of Oracle Database instances:
[oracle@racnodep1 ~]$  srvctl status database -d  ORCLCDB
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
If the install fails for any reason, log in to container using the above command and check `/tmp/orod/oracle_rac_setup.log`. You can also review the Grid Infrastructure logs located at `$GRID_BASE/diag/crs` and check for failure logs. If the failure occurred during the database creation then check the database logs.


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