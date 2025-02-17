# Cleanup Oracle RAC Database Container Environment
To clean up the Oracle Real Application Clusters (Oracle RAC) environment, complete the following commands.

```bash
podman inspect rac-dnsserver &> /dev/null && podman rm -f rac-dnsserver
podman inspect racnode-storage &> /dev/null && podman rm -f racnode-storage
podman inspect racnodep1 &> /dev/null && podman rm -f racnodep1
podman inspect racnodep2 &> /dev/null && podman rm -f racnodep2
podman inspect racnodepc1-cman &> /dev/null && podman rm -f racnodepc1-cman
podman network inspect rac_pub1_nw &> /dev/null && podman network rm rac_pub1_nw 
podman network inspect rac_priv1_nw &> /dev/null && podman network rm rac_priv1_nw 
podman network inspect rac_priv2_nw &> /dev/null && podman network rm rac_priv2_nw
podman volume inspect racstorage &> /dev/null && podman volume rm racstorage
```

If you have set up the container environment to use block devices, then clean up the ASM Disks:
```bash
dd if=/dev/zero of=/dev/oracleoci/oraclevdd  bs=8k count=10000 
dd if=/dev/zero of=/dev/oracleoci/oraclevde  bs=8k count=10000
```
If you have set up the container environment using an Oracle Slim Image, then clean up the data folders:
```bash
rm -rf /scratch/rac/cluster01/node1/*
rm -rf /scratch/rac/cluster01/node2/*
```

If you have set up the container environment with User Defined Response files, then clean up the response files:
```bash
rm -rf /scratch/common_scripts/podman/rac/*
```

## License

All scripts and files hosted in this repository that are required to build the container images are, unless otherwise noted, released under UPL 1.0 license.

## Copyright

Copyright (c) 2014-2025 Oracle and/or its affiliates.