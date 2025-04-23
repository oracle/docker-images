Examples of how to extend the Oracle Database Docker Image
=======================================================

applypatch
----------
Example of how to apply a custom patch or Release Update (RU) to the image. You can apply RU or a custom patch on Oracle Grid Infrastructure Home or on Oracle RAC DB Home. For details, please refer to [README.MD of applypatch](./applypatch/README.md).

customracdb
-----------
Example of how to create a 2-node RAC based on sample response files provided under customracdb/<version> folder. You can create a multi-node RAC using response files based on your environment. For details, please refer to [README.MD of customracdb](./customracdb/README.md).

racdockercompose
----------------
Example of how to create a 2-node RAC based on Docker Compose. You can create a single-node RAC using Docker Compose based on your environment. For details, please refer to [README.MD of racdockercompose](./racdockercompose_1/README.md).

racpodmancompose
----------------
Example of how to create 2 node Oracle RAC Setup on **Podman Compose** using Oracle RAC image or RAC slim image, with or without User Defined Response files. You can also create multinode rac using responsefiles based on your environment.

Refer [Podman Compose using Oracle RAC container image](./rac-compose/racimage/README.md) for details in order to setup 2 node Oracle RAC Setup on Podman Compose using Oracle RAC Container Image.
Refer [Podman Compose using Oracle RAC slim image](./rac-compose/racslimimage/README.md) for details in order to setup 2 node Oracle RAC Setup on Podman Compose using Oracle RAC Slim Image.

Copyright
---------
Copyright (c) 2014-2025 Oracle and/or its affiliates. All rights reserved.