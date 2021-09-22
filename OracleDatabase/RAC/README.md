# Oracle Database on Docker
Sample Docker build files to facilitate installation, configuration, and environment setup for DevOps users. For more information about Oracle Database please see the [Oracle Database Online Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/index.html).

## How to build Oracle RAC docker image and access in your environment
Please review README of following sections in a given order. After reviewing the README of each section, you can skip the image/container creation if you do not meet the requirement.

* Please review following points before you proceed to next sections:
  * For better performance, it is good to use BTRFS file system for Docker storage on the Docker host. Please refer to [Oracle Container Runtime for Docker Documentation](https://docs.oracle.com/cd/E52668_01/E87205/html/index.html)
  * Install and configure Docker Engine on Oracle Linux 7 to run RAC on Docker.
  * For Oracle RAC setup in this document, we have used public network on 172.16.1.0/24 and the private network on 192.168.17.0/24.
  * If you plan to use different public and private network in your environment, please gather details for following IPs:
    * Public IP address for each OracleRealApplicationClusters container.
    * Private IP address for each OracleRealApplicationClusters container.
    * Virtual IP address for each OracleRealApplicationClusters container.
    * If you have DNS then collect three single client access name (SCAN) addresses for the cluster. For details, please refer to [Installing Oracle Grid Infrastructure Guide](https://docs.oracle.com/en/database/oracle/oracle-database/18/cwlin/index.html). If you do not have DNS server, you can use single scan IP along with scan name for testing purpose.
    * Public IP for OracleConnectionManager container.
    * Private IP for OracleRACStorageServer container.
   * You must have internet connectivity for yum.

## OracleConnectionManager
Provides Docker build files to create an Oracle Connection Manager docker image. If you are planing to run RAC containers on single host and RAC containers IPs are not accessible on your network, you can use connection manager image to access RAC database on your network. For more details, see [OracleConnectionManager/README.md](./OracleConnectionManager/README.md).

## OracleRACStorageServer
Provides Docker build files to create an NFS based Storage Server for Oracle RAC. If you do not have block storage or NAS device for Oracle RAC to store OCR/Voting files and Datafiles, you can use OracleRACStorageServer docker image to provide shared storage. For more details, see [OracleRACStorageServer/README.md](./OracleRACStorageServer/README.md).

## OracleRACDNSServer
Provides Docker build files to create a local DNS Server container for Oracle RAC On Docker. This container based DNS server provides IP addresses and the hostname resolution for the docker containers on the host. For more details, see [OracleRACDNSServer/README.md](./OracleDNSServer/README.md).

## OracleRealApplicationClusters
Provides Docker build files to create an Oracle RAC Database docker image. For more details, see [OracleRealApplicationClusters/README.md](./OracleRealApplicationClusters/README.md).

**Note:** Please make sure that you have reviewed the README of OracleConnectionManager and OracleRACStorageServer sections and created the images/container based on your env before you review the README of OracleRealApplicationClusters.
