# Pre-built Database (prebuiltdb) Extension

This extension extends [the base Oracle Single Instance Database image](../../README.md) in such a way that the resultant image has a pre-built database. So, when a container is started using this extended image, the start-up time is quite fast. 

The configurable parameters while building this extension are as follows:

- ORACLE_SID
- ORACLE_PDB (non-Free images)
- ORACLE_PWD
- ENABLE_ARCHIVELOG
- ENABLE_FORCE_LOGGING
- AUTO_MEM_CALCULATION

Example command for building this extension is as:

```
./buildExtensions.sh -b <base-image> -t <target-image> -x 'prebuiltdb' -o '--build-arg ORACLE_SID=<Database SID> --build-arg ENABLE_ARCHIVELOG=false --build-arg ENABLE_FORCE_LOGGING=false --build-arg ORACLE_PWD=<database-password>'
```

The detailed instructions for building extensions are [here](../README.md).

EE/SE2 and other non-Free images use the original `Dockerfile`: the database
and PDB remain in the image, without the slimming or extraction steps below.

## Free image optimizations

`buildExtensions.sh` selects `Dockerfile.free` when the base image has
`release=Free` in its labels. It reads the base version from the `version`
label unless `-v` is supplied, so custom image tags are supported.
For a direct build, select `-f Dockerfile.free` and provide the matching
clean `<base-image>-base` image.

For Free builds through `buildExtensions.sh`, a matching
`<base-image>-base` stage is created automatically. The prebuilt database is
created in the first stage, while the final image is rebuilt from that clean
base stage so build-time database layers are not retained in the resulting
image. Build-time diagnostic output under `diag` and
`cfgtoollogs` is also removed after the database is shut down; Oracle
recreates the required diagnostic directories when the container starts. The
contents of `$ORACLE_HOME/assistants/dbca/templates` are removed as well,
since the prebuilt startup path does not run DBCA.

Standard DBCA templates are removed from the Free prebuilt image because its
normal startup path does not run database creation with DBCA. True Cache's
DBCA operations do not require those standard database-creation templates.

When combining extensions for Free images, `prebuiltdb` must come first,
for example `-x 'prebuiltdb truecache sharding'`. The build script rejects
other positions because the clean final stage would discard earlier
extensions' environment settings and files outside `ORACLE_BASE`.

Free prebuilt images use `FREEPDB1`, the same as standard Free images. The
prebuilt PDB datafiles are retained in the compressed archive and opened
during startup. `ORACLE_PDB` is ignored for Free images.

To reduce the unpacked image footprint, the final image stores the prebuilt
`oradata` directory as a compressed archive. The archive is expanded once by
`startPrebuilt.sh` before the normal Oracle entrypoint runs. This reduces the
image's on-disk footprint, but adds extraction time to the first
startup and requires writable storage for `oradata`; the database files still
occupy their normal runtime space after extraction.

When `TRUE_CACHE=true`, archive extraction is skipped because True Cache
creates its own instance from the primary database.

After successful extraction, stopping and starting the same container reuses
the database files. If extraction is interrupted, an in-progress marker causes
the next startup to retry extraction before starting Oracle.

For Free prebuilt images, character-set conversion is attempted only when
`ORACLE_CHARACTERSET` is supplied. On each container start, the PDB's current
character set is compared with the supplied value. If they differ, the PDB
is converted after it is opened and before the database password is updated.
Conversion is skipped when the values match or `ORACLE_CHARACTERSET` is
omitted. New database creation continues to default to `AL32UTF8`.

This extended image can be run as follows:

```
docker run -dt --name <container-name> -p :1521 -p :5500 oracle/database:ext 
```

**NOTE:**
- This extension supports Oracle Single Instance Database container image from version 19.3.0 onwards.
- The user should override 'persistence' to 'null' explicitly while deploying this image on Kubernetes. For example,

```
helm install db21c --set image=<image-url>,persistence=null oracle-db-1.0.0.tgz
```

## Advantages

This extended image includes an already setup database inside the image itself.
Non-Free images start that database directly. Free images additionally extract
the database files and open the prebuilt PDB on startup.

This extended image would be very useful in CI/CD scenarios, where database would be used for conducting tests, experiments and the workflow is simple.

## Limitations

Some limitations are listed as follows:
- Non-Free images store the database files inside the image; mounting an empty external volume hides those files.
- Free images can extract into an empty, Oracle-writable `oradata` volume. An existing nonempty directory is left untouched unless an interrupted-extraction marker is present.
- In Kubernetes environment, **the single replica mode** (i.e. replicas=1) can be used for database deployments.
- The database created will not use more than 2GB of memory.
  - The amount of memory allocated for the database is calculated during creation of the database, which runs during the image build phase. By default, `AUTO_MEM_CALCULATION` is `false` so that the container built with this extension is portable, but it also means that the database inside of the containers deployed with this image will not use more than 2GB, even if more is available/allocated.
  - If you know the environment where you plan to deploy the container built with this extension, you can build the image with `podman build --memory=4096m --build-arg AUTO_MEM_CALCULATION=true` so that the database is created with 4GB of memory allocated.
