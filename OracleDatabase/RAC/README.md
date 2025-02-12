# Oracle Database on Containers

Sample build files to facilitate installation, configuration, and environment setup for DevOps users. For more information about Oracle Database please see the [Oracle Database Online Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/index.html).

## How to build Oracle RAC container image and access in your environment

Please review README of following sections in a given order. After reviewing the README of each section, you can skip the image/container creation if you do not meet the requirement.

* Please review following points before you proceed to next sections:
  * For better performance, it is good to use BTRFS file system for Podman storage on the Podman host. Please refer to [Oracle Container Runtime for Podman Documentation](https://docs.oracle.com/en/learn/run-containers-podman/index.html#introduction)
  * To run Oracle RAC on Podman, install and configure the Podman engine on Oracle Linux 8.
  * For the Oracle RAC setup in this document, we have configured the public network on 10.0.20.0/24 and the private network on 192.168.17.0/24 and 192.168.18.0/2.
  * If you plan to use different public and private network in your environment, please gather details for following IPs:
    * Public IP address for each OracleRealApplicationClusters container.
    * Private IP address for each OracleRealApplicationClusters container.
    * Virtual IP address for each OracleRealApplicationClusters container.
    * If you have DNS then collect three single client access name (SCAN) addresses for the cluster. For details, please refer to [Installing Oracle Grid Infrastructure Guide](https://docs.oracle.com/en/database/oracle/oracle-database/21/cwlin/index.html). If you do not have DNS server, you can use single scan IP along with scan name for testing purpose.
    * Public IP for OracleConnectionManager container.
    * Private IP for OracleRACStorageServer container.
  * You must have internet connectivity for dnf package manager.

## OracleConnectionManager

Provides Docker build files to create an Oracle Connection Manager container image. If you are planing to run RAC containers on single host and RAC containers IPs are not accessible on your network, you can use connection manager image to access RAC database on your network. For more details, see [OracleConnectionManager/README.md](./OracleConnectionManager/README.md).

## Oracle Restart
Provides Details to create Oracle database on Oracle Restart. For more details, see [OracleRealApplicationClusters/docs/orestart/README.md](./OracleRealApplicationClusters/docs/orestart/README.md)

## OracleRealApplicationClusters

Provides Podman build files to create an Oracle RAC Database container image. For more details, see [OracleRealApplicationClusters/README.md](./OracleRealApplicationClusters/README.md)


## Oracle Real Application Clusters for Developers

Provides Details to create an Oracle RAC Database for a rapid deployment to build CI/CD pipeline.

You need to review `OracleRACDNSServer` and `OracleRACStorageServer` sections, create the images and containers based on your environment configuration before you proceed to `Oracle Real Application Clusters For Developers` section.
* **OracleRACDNSServer Container**

  Provides Podman build files to create a local DNS Server container for Oracle RAC on Podman. This container-based DNS server provides IP addresses and the hostname resolution for the containers on the host. For more details, see [OracleRACDNSServer/README.md](./OracleDNSServer/README.md).

* **OracleRACStorageServer Container**

  Provides Podman build files to create an NFS-based storage server for Oracle RAC. If you do not have a block storage or NAS device for Oracle RAC to store OCR, Voting files and Datafiles, then you can use the Oracle RAC Storage Server container image to provide shared storage. For more details, see [OracleRACStorageServer/README.md](./OracleRACStorageServer/README.md).

* **Oracle Real Application Clusters for Developers**  
  Provides Details to create an Oracle RAC Database container image for developers. For more details, see [OracleRealApplicationClusters/docs/developers/README.md](./OracleRealApplicationClusters/docs/developers/README.md)
