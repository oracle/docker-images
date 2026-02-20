# Examples of how to extend the Oracle Database Container Image
================================

## applypatch

Example of how to apply a custom patch or Release Update (RU) to the image. You can apply RU or custom patch on Oracle Grid Infrastructure Home or on Oracle RAC DB Home. For details, refer [README.MD of applypatch](./applypatch/README.md).

## customracdb

Example of how to create 2 node RAC based on sample responsefiles provided under customracdb/<version> folder. You can create multinode rac using responsefiles based on your environment. For details, refer [README.MD of customracdb](./customracdb/README.md).

## rac-compose

Example of how to create 2 node Oracle RAC Setup on **Podman Compose** using Oracle RAC image or RAC slim image, with or without User Defined Response files. You can also create multinode rac using responsefiles based on your environment.  

Refer [Podman Compose using Oracle RAC container image](./rac-compose/racimage/README.md) for details in order to setup 2 node Oracle RAC Setup on Podman Compose using Oracle RAC Container Image.  
Refer [Podman Compose using Oracle RAC slim image](./rac-compose/racslimimage/README.md) for details in order to setup 2 node Oracle RAC Setup on Podman Compose using Oracle RAC Slim Image.

## License 

All scripts and files hosted in this repository which are required to build the container  images are, unless otherwise noted, released under UPL 1.0 license.

## Copyright

Copyright (c) 2014-2025 Oracle and/or its affiliates.