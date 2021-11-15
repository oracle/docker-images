# Local Software and Patch

This directory contains local Software and Patch. The software is usually not part of the git repo. It have to be downloaded by the *user* prior building the Docker images. The `*.download` files provides the necessary download url and information.

The fusion middleware software is only required when building a Docker image for *OUDSM*. For a regular *OUD* Docker image it is sufficient to have the OUD and optional patch sets.

| Sofware Package                                                       | Type     | Description                                                                                             |
|-----------------------------------------------------------------------|----------|---------------------------------------------------------------------------------------------------------|
| [p30188241_122140_Generic.zip](p30188241_122140_Generic.zip.download) | Binaries | Oracle Fusion Middleware 12c (12.2.1.4.0) Weblogic Werver and Coherence. Required for the OUDSM images. |
| [p30188352_122140_Generic.zip](p30188352_122140_Generic.zip.download) | Binaries | Oracle Fusion Middleware 12c (12.2.1.4.0) Unified Directory. Required for the OUD images.               |