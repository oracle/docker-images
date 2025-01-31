# Cleanup Oracle RAC Container  Environment
Execute below commands to cleanup Oracle RAC Container Environment-
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

If you have setup using Block Devices, then cleanup ASM Disks-
```bash
dd if=/dev/zero of=/dev/oracleoci/oraclevdd  bs=8k count=10000 
dd if=/dev/zero of=/dev/oracleoci/oraclevde  bs=8k count=10000
```
If you have setup using Oracle Slim Image, then cleanup data folders-
```bash
rm -rf /scratch/rac/cluster01/node1/*
rm -rf /scratch/rac/cluster01/node2/*
```

If you have setup using User Defined Response files, then cleanup response files-
```bash
rm -rf /scratch/common_scripts/podman/rac/*
```

## License

All scripts and files hosted in this repository which are required to build the container  images are, unless otherwise noted, released under UPL 1.0 license.

## Copyright

Copyright (c) 2014-2024 Oracle and/or its affiliates.