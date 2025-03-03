# Deleting a Node from Existing Oracle RAC on Container Cluster
First identify the node you want to remove from RAC Container Cluster, then login to container and execute below-
```bash
cd /opt/scripts/startup/scripts/
python3 main.py --delracnode="del_rachome=true;del_gridnode=true"
```
E.g In this example we will delete racnodep3 from a cluster of 3 nodes viz. racnodep1,racnodep2, racnodep3.
```bash
podman exec -it racnodep3 bash
cd /opt/scripts/startup/scripts/
python3 main.py --delracnode="del_rachome=true;del_gridnode=true"
```
Validate racnodep3 is deleted successfully from Oracle RAC on Container Cluster -
```bash
podman exec -it racnodep1 bash
[root@racnodep1 bin]# /u01/app/21c/grid/bin/olsnodes -n
racnodep1       1
racnodep2       2
```
Now racnodep3 container can be removed by running command-
```bash
podman rm -f racnodep3
```

## License

All scripts and files hosted in this repository which are required to build the container  images are, unless otherwise noted, released under UPL 1.0 license.

## Copyright

Copyright (c) 2014-2025 Oracle and/or its affiliates.