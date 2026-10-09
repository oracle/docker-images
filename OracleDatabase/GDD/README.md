# Oracle Globally Distributed Database in Linux Containers

Oracle Globally Distributed Database is a scalability and availability feature for custom-designed OLTP applications that enables the distribution and replication of data across a pool of Oracle Databases that do not share hardware or software. The pool of databases is presented to the application as a single logical database.

For more information, see [Oracle Globally Distributed Database Management Documentation](http://docs.oracle.com/en/database/).

This repository provides container build files, deployment samples, and quick-start instructions for creating Oracle Globally Distributed Database environments with Linux Containers.

Use this README as the entry point:

- Start with the [Quick Start](./docs/QUICKSTART.md) if you want a guided first deployment.
- Use the scenario guides if you already know your target platform and topology.
- Use the image build section if you need to build or retag images before deployment.

## About This Repository

This project helps you:

- Build Oracle Global Service Manager (GSM) container images.
- Use prebuilt Oracle Database and GSM images from Oracle Container Registry.
- Deploy sharded environments with Podman.
- Choose between quick-start, manual container deployment, and compose-based deployment.

## What Is Included

- `containerfiles/`: GSM container image definitions and helper scripts
- `docs/QUICKSTART.md`: the fastest way to deploy a working environment
- `docs/ENVVARIABLESCOMPOSE.md`: compose-related environment variable reference
- `samples/container-files/`: step-by-step manual deployment examples
- `samples/compose-files/`: compose-based deployment examples

The current `containerfiles/` directory includes versioned content for:

- `19.3.0`
- `21.3.0`
- `23.26.0`

## Recommended Reading Order

For the best onboarding experience, use this order:

1. Review [Prerequisites](#prerequisites).
2. Run the [Quick Start](./docs/QUICKSTART.md) to validate your host and workflow.
3. Choose a deployment scenario from [Choose Your Path](#choose-your-path).
4. Return to [Getting Container Images](#getting-container-images) only if you need to build images or use a different version.

## Choose Your Path

| Goal | Use this guide | Best for |
| --- | --- | --- |
| Get a working environment quickly | [Quick Start](./docs/QUICKSTART.md) | First-time users |
| Deploy with Oracle AI Database 26ai Free on Podman | [Podman with Free image](./samples/container-files/podman-container-files-free/README.md) | Evaluation and learning |
| Deploy with extended Single Instance Database images on Podman | [Podman with Single Instance Database](./samples/container-files/podman-container-files/README.md) | Manual Podman deployments |
| Deploy with Oracle Restart on Podman | [Podman with Oracle Restart](./samples/container-files/podman-container-files-gpc/README.md) | ASM-based deployments |
| Deploy with Oracle RAC on Podman | [Podman with RAC](./samples/container-files/podman-container-files-rac/README.md) | RAC-based deployments |
| Deploy with `podman-compose` | [Podman Compose](./samples/compose-files/podman-compose/README.md) | Single-host automation |

Notes:

- Oracle AI Database 26ai Free is not supported for Oracle Restart or RAC deployment scenarios in this repo.
- Podman is the preferred path for Oracle Linux 8 and later.

## Prerequisites

Run all steps in this guide as `root` or as a user with `sudo` privileges.

### Podman on Oracle Linux 8 or Later

Use Podman for Oracle Linux 8 and later. Oracle recommends Podman `4.9.4` or later on Oracle Linux `8.10` or later.

Install Podman:

```bash
dnf config-manager --enable ol8_appstream
dnf install -y podman
```

If SELinux is enabled on the host, also install:

```bash
dnf install -y selinux-policy-devel
```

### Storage and Temporary Space

Make sure the host has enough free space in `/var/lib/containers` while building images.

If needed, point Podman to a different temporary directory:

```bash
export TMPDIR=/path/to/tmpdir
```

## Quick Start

The [Quick Start guide](./docs/QUICKSTART.md) is the best entry point for new users. It walks through a single-host deployment using Podman and helps you validate the environment before moving to more advanced scenarios.

After you complete the quick start, use the scenario guides for production-style layouts, alternate topologies, or different image types.

## Getting Container Images

You can either pull prebuilt images from Oracle Container Registry or build the required images yourself.

### Option 1: Pull Images from Oracle Container Registry

You can pull images directly from Oracle Container Registry:

#### Deployment Using Oracle AI Database 26ai Free Images

| Image | Image ID |
| --- | --- |
| `container-registry.oracle.com/database/free:latest` | `cdf2f86bedfa` |
| `container-registry.oracle.com/database/gsm_ru:latest` | `9bfae0eecb59` |

#### Deployment Using Oracle AI Database 26ai Enterprise Images

| Image | Image ID |
| --- | --- |
| `container-registry.oracle.com/database/enterprise_ru:latest` | `7cbe91807bfc` |
| `container-registry.oracle.com/database/gsm_ru:latest` | `9bfae0eecb59` |

#### Deployment Using Oracle 19c Enterprise Images

| Image | Image ID |
| --- | --- |
| `container-registry.oracle.com/database/enterprise_ru:19.32.0.0` | `a166c08a937c` |
| `container-registry.oracle.com/database/gsm_ru:19.32.0.0` | `e96e30d0c96c` |

If you use non-`latest` tags, retag them as needed for your deployment commands.

**Important:**

- Make sure the OpenSSL version in the container image is compatible with the OpenSSL version on the host that generates the encrypted password file.
- The compatibility examples in [Oracle Container Registry Image Compatibility](#oracle-container-registry-image-compatibility) can help you choose matching images.

### Option 2: Build a GSM Image from Local Binaries

To build a GSM image for a supported version in this repository:

1. Download the `Oracle Global Service Manager (GSM/GDS) for Oracle Database for Linux x86-64` installation binaries for that version.
2. Place the binaries in `containerfiles/<version>/`.
3. Do not extract the binaries.
4. Run `containerfiles/buildContainerImage.sh`.

Example:

```bash
./buildContainerImage.sh -v 23.26.0
```

To view script usage:

```bash
./buildContainerImage.sh -h
```

This script performs checksum validation and simplifies image creation for new users. Advanced users can run `podman build` directly with their preferred parameters.

RPM provenance is always recorded under `/usr/share/oracle/image-metadata/rpms`.
Inspect it with:

```bash
podman run --rm --entrypoint /bin/sh IMAGE -c \
  'ls -l /usr/share/oracle/image-metadata/rpms && cat /usr/share/oracle/image-metadata/rpms/*.txt'
```

### Building Database Images

This repo focuses on GSM container files and deployment samples. For database image creation, use the upstream Oracle image guides:

- Single Instance Database base image: [OracleDatabase/SingleInstance README](https://github.com/oracle/docker-images/blob/main/OracleDatabase/SingleInstance/README.md)
- Single Instance extensions: [OracleDatabase/SingleInstance/extensions README](https://github.com/oracle/docker-images/blob/main/OracleDatabase/SingleInstance/extensions/README.md)
- RAC base image: [OracleDatabase/RAC/OracleRealApplicationClusters README](https://github.com/oracle/docker-images/blob/main/OracleDatabase/RAC/OracleRealApplicationClusters/README.md)
- RAC extensions: [OracleDatabase/RAC/OracleRealApplicationClusters/extensions README](https://github.com/oracle/docker-images/blob/main/OracleDatabase/RAC/OracleRealApplicationClusters/extensions/README.md)

Use those guides to build the base or extended database images, then return to the deployment scenarios in this repo for container-specific setup.

## Deployment Scenarios

Use the scenario that matches your platform and image type.

### Manual Container Deployments

- [Podman with Oracle AI Database 26ai Free](./samples/container-files/podman-container-files-free/README.md)
  Covers System-Managed Sharding, RAFT-enabled System-Managed Sharding, and User-Defined Sharding with the free image path.
- [Podman with Extended Single Instance Database images](./samples/container-files/podman-container-files/README.md)
  Covers manual Podman deployment using extended Enterprise Edition database images.
- [Podman with Oracle Restart](./samples/container-files/podman-container-files-gpc/README.md)
  Uses Oracle Restart-based containers for the catalog and shards.
- [Podman with Oracle RAC](./samples/container-files/podman-container-files-rac/README.md)
  Uses RAC-based containers for the catalog and shards.

### Compose-Based Deployments

- [Podman Compose deployment](./samples/compose-files/podman-compose/README.md)
  Best for a repeatable single-host Podman workflow.

## Support

- Podman-based deployment examples are intended for Oracle Linux 8 and later.

## License

To download and run Oracle Global Service Manager (GSM) and Oracle Globally Distributed Database, whether inside or outside a container, you must download the binaries from the Oracle website and accept the license terms provided there.

Unless otherwise noted, the scripts and files in this project and the related `docker-images/OracleDatabase` repository are released under the UPL 1.0 license.

## Copyright

Copyright (c) 2022 - 2024 Oracle and/or its affiliates.
Released under the Universal Permissive License v1.0 as shown at [https://oss.oracle.com/licenses/upl/](https://oss.oracle.com/licenses/upl/)


## Base image provenance

The GSM build wrapper resolves the selected base image to a sha256 digest and
passes `BASE_IMAGE`, `BASE_IMAGE_REF`, and `BASE_IMAGE_DIGEST` to the
build. The image exposes the source reference and digest as OCI labels and
writes the direct-base record to:

```
/usr/share/oracle/image-metadata/base-image-chain.json
```

Inspect an image with:

```
podman image inspect IMAGE --format '{{json .Config.Labels}}'
podman run --rm --entrypoint /bin/sh IMAGE -c \
  'cat /usr/share/oracle/image-metadata/base-image-chain.json'
```
