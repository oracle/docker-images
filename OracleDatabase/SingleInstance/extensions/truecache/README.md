# True Cache Database Extension

This extension extends [the base Oracle Single Instance Database image](../../README.md) with scripts used to set up a True Cache database for a Primary Database container. The portable standalone Podman flow in this document generates the True Cache blob explicitly on the primary container, copies it to the Podman host, and mounts it into the True Cache container.

**NOTE:** This extension supports Oracle Single Instance Database container image from version 23ai onwards.

## Advantages

This extended image includes:

- helper scripts for creating the True Cache blob file from the Primary Database container
- scripts for setting up a working True Cache deployment which can be used with an application

## Prerequisites for Running Oracle Truecache on Podman

### Section 1 : Prerequisites for Running Oracle Truecache on Podman

 You must install and configure [Podman release 4.2.0](https://docs.oracle.com/en/operating-systems/oracle-linux/Podman/) or later on Oracle Linux 8.7 or later to run Oracle Truecache on Podman.

### Section 2: Build SIDB Container Image

To build Oracle TrueCache on container, you need to download and build [Oracle 23ai Database image](../../README.md), please refer README.MD of Oracle Single Database available on Oracle OraHub repository.

**Note:** You just need to create the image as per the instructions given in README.MD but you will create the container as per the steps given in this document under [Deploy Containers for True Cache Setup](#deploy-containers-for-true-cache-setup) section.

#### Create Extended Oracle Database Image with TrueCache  Feature

After creating the base image using buildContainerImage.sh in the previous step, use buildExtensions.sh present under the extensions folder `<GIT_CLONED_DIR>/docker-images/OracleDatabase/SingleInstance/extensions` to build an extended image that will include the truecache Feature. Build one True Cache extension image for the edition you will use, and use the same extension image for both the Primary Database container and the True Cache container.

Enterprise Edition example:

```bash
./buildExtensions.sh -x truecache -b oracle/database:23.26.0-ee -t oracle/database-ext-truecache:23.26.0-ee
```

Free example:

```bash
./buildExtensions.sh -x truecache -b oracle/database:23.26.0-free -t oracle/database-ext-truecache:23.26.0-free
```

Where:

- `-x truecache` specifies the True Cache extension.
- `-b` specifies the base image created in the previous step.
- `-t` specifies the name and tag for the extended image with the True Cache feature.

## Running Oracle True Cache Container Database

### Create Network Bridge

Before creating a container, create the podman network by creating podman network bridge based on your enviornment. If you are using the bridge name with the network subnet mentioned in this README.md then you can use the same IPs mentioned in Create Containers section.

If primary database is not running on same host as truecache db, you must use `macvlan` or `ipvlan` bridge to conect to the primary database.

#### Macvlan Bridge

```bash
# podman network create -d macvlan --subnet=172.20.1.0/24 --gateway=172.20.1.1 -o parent=eth0 truecache_pub1_n
```

#### Ipvlan Bridge

```bash
# podman network create -d ipvlan --subnet=172.20.1.0/24 --gateway=172.20.1.1 -o parent=eth0 truecache_pub1_n
```

If you are planning to create a test env within a single machine, you can use a podman bridge but these IPs will not be reachable on the user network.

#### Bridge

```bash
# podman network create --driver=bridge --subnet=172.20.1.0/24 truecache_pub1_n
```

**Note:** You can change subnet and choose one of the above mentioned podman network bridge based on your enviornment.

#### Setup Hostfile

Use one name-resolution method for the Podman containers:

- DNS provided by your environment or Podman network.
- A shared hostfile mounted as `/etc/hosts` in each container.
- `--add-host` entries on each `podman run` command.

If you use DNS, skip this hostfile section and omit `--add-host` entries unless you need extra aliases. If you use `--add-host`, skip this hostfile section. If you use the shared hostfile, mount it into every container and remove the `--add-host` lines from the `podman run` commands.

All containers can share one hostfile for bidirectional name resolution. The Primary Database container must resolve the True Cache hostname, and the True Cache container must resolve the Primary Database hostname used in `PRIMARY_DB_CONN_STR`. Create the empty shared host file, if it does not exist, at `/opt/containers/truecache_host_file`:

For example:

```bash
mkdir -p /opt/containers
rm -rf /opt/containers/truecache_host_file && touch /opt/containers/truecache_host_file
```

Add entries for the Primary Database container, the True Cache container, and any application client hosts. This file must be pre-populated before container startup. You can change these entries based on your environment and network setup.

```text
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
172.20.1.2      prod.example.com prod
172.20.1.98     truedb.example.com truedb
172.20.1.125    appclient.example.com appclient
```

**NOTE:** In this example, `prod.example.com` is the Primary Database container, `truedb.example.com` is the True Cache container, and `appclient.example.com` is an optional application container. Mount this hostfile into both the Primary Database and True Cache containers when using the hostfile method.

### Password Management

When using this extension, provide the same database password to both the Primary Database container and the True Cache container through Podman secrets. The extension startup scripts read the secret named `oracle_pwd`; when the companion secret `oracle_pwd_privkey` is also mounted, the password secret is treated as encrypted and is decrypted inside the container. These names must match the names used in the `podman run --secret` options shown later in this document.

For a plain Podman secret, create `oracle_pwd` directly from the password text:

```bash
printf "%s" "<Your Password>" | podman secret create oracle_pwd -
```

For an encrypted Podman secret, create a public-private key pair, encrypt the password with the public key, then create both required secrets:

```bash
mkdir -p /opt/.secrets
cd /opt/.secrets
openssl genrsa -out key.pem
openssl rsa -in key.pem -out key.pub -pubout
printf "%s" "<Your Password>" > pwdfile.txt
openssl pkeyutl -in pwdfile.txt -out pwdfile.enc -pubin -inkey key.pub -encrypt
rm -f pwdfile.txt

podman secret create oracle_pwd /opt/.secrets/pwdfile.enc
podman secret create oracle_pwd_privkey /opt/.secrets/key.pem
```

Verify that the secret names match the container commands:

```bash
podman secret ls
ID                         NAME                 DRIVER      CREATED        UPDATED
547eed65c01d525bc2b4cebd9  oracle_pwd           file        8 seconds ago  8 seconds ago
8ad6e8e519c26e9234dbcf60a  oracle_pwd_privkey   file        8 seconds ago  8 seconds ago
```

Mount `oracle_pwd` into both the Primary Database and True Cache containers. If you created the encrypted password secret, mount `oracle_pwd_privkey` into both containers as well. The True Cache setup uses this same password secret to connect to the Primary Database and run primary-side DBCA steps.

## SELinux Configuration on Podman Host

To run Podman containers in an environment with SELinux enabled, you must configure an SELinux policy for the containers. To check if your SELinux is enabled or not, run the `getenforce` command.
With Security-Enhanced Linux (SELinux), you must set a policy to implement permissions for your containers. If you do not configure a policy module for your containers, then they can end up restarting indefinitely or other permission errors. You must add all Podman host nodes for your cluster to the policy module `shard-podman`, by installing the necessary packages and creating a type enforcement file (designated by the .te suffix) to build the policy, and load it into the system.

In the following example, the Podman host `podman-host` is configured in the SELinux policy module `tc-podman`:

Copy [tc-podman.te](./tc-podman.te) to `/var/opt` folder in your host and then execute below-

```bash
cd /var/opt
make -f /usr/share/selinux/devel/Makefile tc-podman.pp
semodule -i tc-podman.pp
semodule -l | grep tc-podman
```

### Set Host Data Root

Set a single variable for the host-side data root and reuse it in the following commands. Update this value to match your environment.

```bash
export HOST_DATA_ROOT=/scratch/oradata
```

### Create Directory

You need to create mountpoint on the podman host to save datafiles for Primary Database and the Oracle True Cache Database. These directories will be exposed as a volume to the containers. This volume can be local on a podman host or exposed from your central storage. It contains a file system such as EXT4. During the setup of this sample True Cache Database Deployment, we used below directories and exposed as volume to the correcponding container.

```bash
mkdir -p ${HOST_DATA_ROOT}/trueCache/prod
chown -R 54321:54321 ${HOST_DATA_ROOT}/trueCache/prod

mkdir -p ${HOST_DATA_ROOT}/trueCache/truedb
chown -R 54321:54321 ${HOST_DATA_ROOT}/trueCache/truedb
```

- If SELinux is enabled on podman host, then execute following:

```bash
semanage fcontext -a -t container_file_t "${HOST_DATA_ROOT}/trueCache/prod(/.*)?"
restorecon -Rv ${HOST_DATA_ROOT}/trueCache/prod

semanage fcontext -a -t container_file_t "${HOST_DATA_ROOT}/trueCache/truedb(/.*)?"
restorecon -Rv ${HOST_DATA_ROOT}/trueCache/truedb
```

- If you are creating a Hostfile named `/opt/containers/truecache_host_file`, then complete the below step as well:

```bash
semanage fcontext -a -t container_file_t /opt/containers/truecache_host_file
restorecon -v /opt/containers/truecache_host_file
```

## Deploy Containers for True Cache Setup

### Deploying the Primary Container Database

Use the command that matches the edition of the Primary Database container. The Enterprise Edition CDB service is `ORCLCDB` and PDB is `ORCLPDB1`; the Free CDB service is `FREE` and PDB is `FREEPDB1`.

**NOTE:** If you are reusing a Podman host data directory from an earlier run, clean the primary data directory before starting the container to avoid stale database metadata.

```bash
rm -rf ${HOST_DATA_ROOT}/trueCache/prod
mkdir -p ${HOST_DATA_ROOT}/trueCache/prod
chown -R 54321:54321 ${HOST_DATA_ROOT}/trueCache/prod
```

Enterprise Edition Primary Database container:

```bash
podman run -d --name prod --hostname prod --ip 172.20.1.2 \
--net=truecache_pub1_n \
--secret=oracle_pwd \
--secret=oracle_pwd_privkey \
--add-host="truedb:172.20.1.98" \
--add-host="appclient:172.20.1.125" \
--dns-search=example.com \
-e DOMAIN=example.com \
-e ENABLE_ARCHIVELOG=true \
-e ENABLE_FORCE_LOGGING=true \
-v ${HOST_DATA_ROOT}/trueCache/prod:/opt/oracle/oradata \
oracle/database-ext-truecache:23.26.0-ee
```

Free Primary Database container:

```bash
podman run -d --name prod --hostname prod --ip 172.20.1.2 \
--net=truecache_pub1_n \
--secret=oracle_pwd \
--secret=oracle_pwd_privkey \
--add-host="truedb:172.20.1.98" \
--add-host="appclient:172.20.1.125" \
--dns-search=example.com \
-e DOMAIN=example.com \
-e ENABLE_ARCHIVELOG=true \
-e ENABLE_FORCE_LOGGING=true \
-v ${HOST_DATA_ROOT}/trueCache/prod:/opt/oracle/oradata \
oracle/database-ext-truecache:23.26.0-free
```

**NOTE:** True Cache setup requires bidirectional name resolution. The True Cache container must resolve the Primary Database hostname used in `PRIMARY_DB_CONN_STR`, and the Primary Database container must resolve the True Cache hostname used by the True Cache callback/service, for example `truedb` or `tc-db1`. If the Podman network does not provide container-name DNS resolution, use either `--add-host` mappings on both container commands or mount `/opt/containers/truecache_host_file:/etc/hosts` into both containers. When using the hostfile mount, remove the `--add-host` lines from the commands.

Once deployed, monitor the logs for the Primary Database Container (i.e. "prod" in this case) using the below command:

```bash
podman logs -f prod
```

The following lines will highlight when the Primary Database is ready for use:

```bash
#########################
DATABASE IS READY TO USE!
#########################
```

### Prepare the True Cache Blob File

The Primary Database must be created and ready before the True Cache container is started. The True Cache container requires a True Cache blob file generated from that Primary Database.

For explicit blob-based standalone Podman setup, generate the blob file from the Primary Database first, copy or mount that same `.tar.gz` blob file into the True Cache container, and set `TRUE_CACHE_BLOB` to the in-container path. The Enterprise Edition and Free standalone Podman examples below use this explicit blob flow.

Use DBCA on the Primary Database host to create the blob file into a host directory, then make that same file available to the True Cache container. When the Primary Database was started with the True Cache extension image shown above, the helper script is already available inside the primary container and writes the generated archive as `blobTestData.tar.gz`.

Enterprise Edition manual blob example:

```bash
export PRIMARY_DB_NAME=ORCLCDB
mkdir -p ${HOST_DATA_ROOT}/trueCache/blob
podman exec prod bash -c "mkdir -p /var/tmp/truecache_blob && /opt/oracle/createBlob.sh /var/tmp/truecache_blob ${PRIMARY_DB_NAME} /opt/oracle/scripts/base/decryptPassword.sh"
podman cp prod:/var/tmp/truecache_blob/blobTestData.tar.gz ${HOST_DATA_ROOT}/trueCache/blob/blobTestData.tar.gz
chown -R 54321:54321 ${HOST_DATA_ROOT}/trueCache/blob
```

Free manual blob example:

```bash
export PRIMARY_DB_NAME=FREE
mkdir -p ${HOST_DATA_ROOT}/trueCache/blob
podman exec prod bash -c "mkdir -p /var/tmp/truecache_blob && /opt/oracle/createBlob.sh /var/tmp/truecache_blob ${PRIMARY_DB_NAME} /opt/oracle/scripts/base/decryptPassword.sh"
podman cp prod:/var/tmp/truecache_blob/blobTestData.tar.gz ${HOST_DATA_ROOT}/trueCache/blob/blobTestData.tar.gz
chown -R 54321:54321 ${HOST_DATA_ROOT}/trueCache/blob
```


**Automatic blob generation note:** Automatic blob generation is supported only when the True Cache extension image startup command runs the extension `runOracle.sh` hook. The portable standalone Podman examples in this document use the explicit blob flow and set `TRUE_CACHE_BLOB` for both Enterprise Edition and Free because current 23ai/26ai base images start `$SCRIPT_BASE_DIR/$RUN_FILE`; automatic blob generation requires an image whose active startup path sources the True Cache extension hook.

After the blob file is available on the Podman host at `${HOST_DATA_ROOT}/trueCache/blob/blobTestData.tar.gz`, mount that directory read-only into the True Cache container and set:

```bash
-v ${HOST_DATA_ROOT}/trueCache/blob:/opt/oracle/truecache/blob:ro \
-e TRUE_CACHE_BLOB=/opt/oracle/truecache/blob/blobTestData.tar.gz \
```

### Deploying the True Cache Container Database

Use the following command to deploy the True Cache Database Container (named "truedb" in this case). Use the command that matches the edition of the Primary Database container.

The commands below use the explicit blob flow and set `TRUE_CACHE_BLOB` to the mounted blob path.

**NOTE:** If you are reusing a Podman host data directory from an earlier run, clean the true cache data directory before starting the container to avoid stale database metadata.

```bash
rm -rf ${HOST_DATA_ROOT}/trueCache/truedb
mkdir -p ${HOST_DATA_ROOT}/trueCache/truedb
chown -R 54321:54321 ${HOST_DATA_ROOT}/trueCache/truedb
```

Enterprise Edition True Cache container:

```bash
podman run -d --name truedb \
--ip 172.20.1.98 \
--net truecache_pub1_n \
--secret=oracle_pwd \
--secret=oracle_pwd_privkey \
--hostname truedb \
--add-host="prod:172.20.1.2" \
--add-host="appclient:172.20.1.125" \
--dns-search=example.com \
-e DOMAIN=example.com \
-e ORACLE_SID=truedb \
-e PRIMARY_DB_CONN_STR=prod:1521/ORCLCDB \
-e AUTO_TC_SVC_REGISTRATION="false" \
-e TRUE_CACHE=true \
-e TRUEDB_UNIQUE_NAME=truedb \
-e PDB_TC_SVCS="ORCLPDB1:sales1:sales1_tc;ORCLPDB1:sales2:sales2_tc;ORCLPDB1:sales3:sales3_tc;ORCLPDB1:sales4:sales4_tc" \
-v ${HOST_DATA_ROOT}/trueCache/blob:/opt/oracle/truecache/blob:ro \
-e TRUE_CACHE_BLOB=/opt/oracle/truecache/blob/blobTestData.tar.gz \
-v ${HOST_DATA_ROOT}/trueCache/truedb:/opt/oracle/oradata \
oracle/database-ext-truecache:23.26.0-ee
```

Free True Cache container:

```bash
podman run -d --name truedb \
--ip 172.20.1.98 \
--net truecache_pub1_n \
--secret=oracle_pwd \
--secret=oracle_pwd_privkey \
--hostname truedb \
--add-host="prod:172.20.1.2" \
--add-host="appclient:172.20.1.125" \
--dns-search=example.com \
-e DOMAIN=example.com \
-e PRIMARY_DB_CONN_STR=prod:1521/FREE \
-e PRIMARY_DB_NAME=FREE \
-e AUTO_TC_SVC_REGISTRATION="false" \
-e TRUE_CACHE=true \
-e TRUEDB_UNIQUE_NAME=truedb \
-e PDB_TC_SVCS="FREEPDB1:sales1:sales1_tc;FREEPDB1:sales2:sales2_tc;FREEPDB1:sales3:sales3_tc;FREEPDB1:sales4:sales4_tc" \
-v ${HOST_DATA_ROOT}/trueCache/blob:/opt/oracle/truecache/blob:ro \
-e TRUE_CACHE_BLOB=/opt/oracle/truecache/blob/blobTestData.tar.gz \
-v ${HOST_DATA_ROOT}/trueCache/truedb:/opt/oracle/oradata \
oracle/database-ext-truecache:23.26.0-free
```

The Free image sets `ORACLE_SID=FREE` internally, so do not add `-e ORACLE_SID=truedb` to the Free command. Use `FREE` for the primary CDB service and `FREEPDB1` in `PDB_TC_SVCS`. Set `PRIMARY_DB_NAME=FREE` explicitly for Free so the True Cache DBCA source database name is not inferred from the connect string.

If the Podman network does not provide container-name DNS resolution, use one of these alternatives for bidirectional name resolution:

- Add host mappings in both directions. The True Cache container needs a mapping for the primary hostname, for example `--add-host=prod:172.20.1.2` or `--add-host=prim-db1:10.89.0.11`, and the Primary Database container needs a mapping for the True Cache hostname, for example `--add-host=truedb:172.20.1.98` or `--add-host=tc-db1:10.89.0.12`. Keep `PRIMARY_DB_CONN_STR` aligned with the primary hostname mapping.
- Mount `/opt/containers/truecache_host_file:/etc/hosts` into both containers and remove the `--add-host` lines from the commands. The hostfile must contain both the primary and True Cache hostname entries.

For Free, the True Cache container must have one of these bootstrap inputs available by the time DBCA runs:

- `TRUE_CACHE_BLOB`, mounted as the blob file generated from the Primary Database.
- `PRIMARY_DB_PWD_FILE`, a mounted copy of the primary database password file.

Podman password secrets set `ORACLE_PWD`; they do not create the mounted primary password file used by `dbca -createTrueCacheInstance`.

To use the primary password file instead of a blob file for Free, copy `orapwFREE` from the Primary Database container, mount it read-only into the True Cache container, and set `PRIMARY_DB_PWD_FILE`:

```bash
mkdir -p ${HOST_DATA_ROOT}/trueCache/passwordfile
podman exec prod bash -c 'cp "$($ORACLE_HOME/bin/orabaseconfig)/dbs/orapwFREE" /var/tmp/orapwFREE'
podman cp prod:/var/tmp/orapwFREE ${HOST_DATA_ROOT}/trueCache/passwordfile/orapwFREE
chown -R 54321:54321 ${HOST_DATA_ROOT}/trueCache/passwordfile
```

Add these options to the Free True Cache `podman run` command:

```bash
-v ${HOST_DATA_ROOT}/trueCache/passwordfile/orapwFREE:/opt/oracle/orapwFREE:ro \
-e PRIMARY_DB_PWD_FILE=/opt/oracle/orapwFREE \
```

**NOTE:** In above command, the list of Primary and True Cache services are mentioned using the string "ORCLPDB1:sales1:sales1_tc;ORCLPDB1:sales2:sales2_tc;ORCLPDB1:sales3:sales3_tc;ORCLPDB1:sales4:sales4_tc"

The string consists of multiple entries in the format "<PDB_NAME>:<PRIMARY_SERVICE_NAME>:<TRUECACHE_SERVICE_NAME>" and these entries are separated by ";".

For example, `DB0515_PDB1:tcokeprim.example.com:tcokenodes.example.com` means:

- `DB0515_PDB1`: primary PDB name
- `tcokeprim.example.com`: primary service name on the source database
- `tcokenodes.example.com`: service name that True Cache should expose locally after the primary-side association step

**NOTE:** With `AUTO_TC_SVC_REGISTRATION="false"` the primary-side service creation, startup, and True Cache association for these mappings are manual steps. In this mode, the container prints the exact primary-host helper command for each mapping so the primary administrator can run the checked-in sample script manually on the primary host.

**NOTE:** If you mount a DB credentials wallet for `dbca -createTrueCacheInstance` through `TRUE_CACHE_DB_CREDENTIAL_WALLET_DIR`, the wallet covers the DBCA create step. Primary-side service registration can still stay manual with `AUTO_TC_SVC_REGISTRATION="false"`, or it can be automated with `AUTO_TC_SVC_REGISTRATION="true"` when the primary-host helper script has been installed.

When the primary pod also uses the same True Cache extension image, the sample script [samples/truecache/configure-primary-truecache-service.sh](../../samples/truecache/configure-primary-truecache-service.sh) is already prebaked at `/home/oracle/configure-primary-truecache-service.sh`, so `AUTO_TC_SVC_REGISTRATION="true"` does not require a separate manual copy step. If the primary runs outside that extension-image workflow, copy the same script to the primary host at `/home/oracle/configure-primary-truecache-service.sh`, or use a custom location exposed through `PRIMARY_TC_SERVICE_SCRIPT_PATH`. Keep it owned by the Oracle software owner and executable.

On RAC primaries, validate the real scheduler runtime before relying on `AUTO_TC_SVC_REGISTRATION="true"`. A matching `externaljob.ora` is not enough by itself; run a `DBMS_SCHEDULER` executable smoke test and verify the generated `/tmp/extjob_id_test.out` file shows the Oracle DB software owner, for example `uid=... (oracle)`. If the file shows any other OS user, correct the scheduler runtime so it launches the helper under the Oracle DB software owner.

If you want the primary-host DBCA service-configuration step to use a mkstore wallet instead of stdin password input, place that wallet on the primary host and set `PRIMARY_TC_SERVICE_WALLET_PATH` to that primary-host directory. `registerService.sh` will pass that path through `DBMS_SCHEDULER`, and the primary-host helper will run DBCA with `-useWalletForDBCredentials true -dbCredentialsWalletLocation <path>`.

In the automatic flow, the True Cache side only invokes that admin-installed primary-host script through `DBMS_SCHEDULER`. That helper is responsible for creating or starting the primary service when needed and then running the primary-side DBCA True Cache service configuration. It no longer pushes an inline remote DBCA command from the True Cache container or issues direct `DBMS_SERVICE` changes on the primary from the True Cache pod.

**NOTE:** If you use the hostfile method, mount `/opt/containers/truecache_host_file:/etc/hosts` into both the Primary Database and True Cache containers, and remove the `--add-host` lines from the commands.

The following lines will highlight when the True Cache Database is ready for use:

```bash
#########################
DATABASE IS READY TO USE!
#########################
```

**Note:** In the logs of "truedb" container, the above message will be followed by message confirming the True Cache Services.

### Enterprise Edition Standalone Podman End-to-End Example

The following example shows an Enterprise Edition Primary Database and Enterprise Edition True Cache container on a static Podman network. It uses the explicit blob flow. Replace `IMAGE` with the Enterprise Edition True Cache extension image available in your environment.

```bash
IMAGE=oracle/database-ext-truecache:23.26.0-ee
BASE=/scratch/oradata/truecache-ee-test

sudo podman network exists tc_net || sudo podman network create --subnet 10.89.0.0/24 tc_net

sudo podman rm -f prim-db1 tc-db1 2>/dev/null || true
sudo rm -rf "${BASE}/primdb1" "${BASE}/tcdb1"
sudo mkdir -p "${BASE}/primdb1" "${BASE}/tcdb1"
sudo chown -R 54321:54321 "${BASE}/primdb1" "${BASE}/tcdb1"
sudo chmod 775 "${BASE}/primdb1" "${BASE}/tcdb1"

sudo podman run -td --name prim-db1 \
  --hostname prim-db1 \
  --network tc_net \
  --ip 10.89.0.11 \
  --add-host=tc-db1:10.89.0.12 \
  --secret=oracle_pwd \
  --secret=oracle_pwd_privkey \
  -e ENABLE_ARCHIVELOG=true \
  -e ENABLE_FORCE_LOGGING=true \
  -v "${BASE}/primdb1:/opt/oracle/oradata" \
  "${IMAGE}"

sudo podman logs -f prim-db1
```

Wait until the primary logs show `DATABASE IS READY TO USE!`, then generate and stage the True Cache blob:

```bash
sudo podman exec prim-db1 bash -lc '
  rm -rf /var/tmp/truecache_blob
  mkdir -p /var/tmp/truecache_blob
  /opt/oracle/createBlob.sh /var/tmp/truecache_blob ORCLCDB /opt/oracle/scripts/base/decryptPassword.sh
  ls -l /var/tmp/truecache_blob/blobTestData.tar.gz
'

sudo mkdir -p "${BASE}/blob" "${BASE}/tcdb1"
sudo chown -R 54321:54321 "${BASE}/blob" "${BASE}/tcdb1"
sudo chmod 775 "${BASE}/blob" "${BASE}/tcdb1"

sudo podman cp prim-db1:/var/tmp/truecache_blob/blobTestData.tar.gz "${BASE}/blob/blobTestData.tar.gz"
sudo chown -R 54321:54321 "${BASE}/blob"
sudo ls -l "${BASE}/blob/blobTestData.tar.gz"
```

Start the Enterprise Edition True Cache container with the mounted blob. The primary command maps `tc-db1` and the True Cache command maps `prim-db1`; both mappings are required when the Podman network does not provide container-name DNS.

```bash
sudo podman run -td --name tc-db1 \
  --hostname tc-db1 \
  --network tc_net \
  --ip 10.89.0.12 \
  --add-host=prim-db1:10.89.0.11 \
  --secret=oracle_pwd \
  --secret=oracle_pwd_privkey \
  -e ORACLE_SID=tcdb1 \
  -e PRIMARY_DB_CONN_STR=prim-db1:1521/ORCLCDB \
  -e PRIMARY_DB_NAME=ORCLCDB \
  -e TRUE_CACHE=true \
  -e TRUEDB_UNIQUE_NAME=tcdb1 \
  -e PDB_TC_SVCS="ORCLPDB1:sales1:sales1_tc" \
  -v "${BASE}/blob:/opt/oracle/truecache/blob:ro" \
  -e TRUE_CACHE_BLOB=/opt/oracle/truecache/blob/blobTestData.tar.gz \
  -v "${BASE}/tcdb1:/opt/oracle/oradata" \
  "${IMAGE}"

sudo podman logs -f tc-db1
```

### Free Standalone Podman End-to-End Example

The following example shows a Free Primary Database and Free True Cache container on a static Podman network. It uses the explicit blob flow and a primary host mapping because some Podman networks are created without container-name DNS. Replace `IMAGE` with the Free True Cache extension image available in your environment.

```bash
IMAGE=oracle/database-ext-truecache:23.26.0-free
BASE=/scratch/oradata/truecache-free-test

sudo podman network exists tc_net || sudo podman network create --subnet 10.89.0.0/24 tc_net

sudo podman rm -f prim-db1 tc-db1 2>/dev/null || true
sudo rm -rf "${BASE}/primdb1" "${BASE}/tcdb1"
sudo mkdir -p "${BASE}/primdb1" "${BASE}/tcdb1"
sudo chown -R 54321:54321 "${BASE}/primdb1" "${BASE}/tcdb1"
sudo chmod 775 "${BASE}/primdb1" "${BASE}/tcdb1"

sudo podman run -td --name prim-db1 \
  --hostname prim-db1 \
  --network tc_net \
  --ip 10.89.0.11 \
  --add-host=tc-db1:10.89.0.12 \
  --secret=oracle_pwd \
  --secret=oracle_pwd_privkey \
  -e ENABLE_ARCHIVELOG=true \
  -e ENABLE_FORCE_LOGGING=true \
  -v "${BASE}/primdb1:/opt/oracle/oradata" \
  "${IMAGE}"

sudo podman logs -f prim-db1
```

Wait until the primary logs show `DATABASE IS READY TO USE!`, then generate and stage the True Cache blob:

```bash
sudo podman exec prim-db1 bash -lc '
  rm -rf /var/tmp/truecache_blob
  mkdir -p /var/tmp/truecache_blob
  /opt/oracle/createBlob.sh /var/tmp/truecache_blob FREE /opt/oracle/scripts/base/decryptPassword.sh
  ls -l /var/tmp/truecache_blob/blobTestData.tar.gz
'

sudo mkdir -p "${BASE}/blob" "${BASE}/tcdb1"
sudo chown -R 54321:54321 "${BASE}/blob" "${BASE}/tcdb1"
sudo chmod 775 "${BASE}/blob" "${BASE}/tcdb1"

sudo podman cp prim-db1:/var/tmp/truecache_blob/blobTestData.tar.gz "${BASE}/blob/blobTestData.tar.gz"
sudo chown -R 54321:54321 "${BASE}/blob"
sudo ls -l "${BASE}/blob/blobTestData.tar.gz"
```

Start the Free True Cache container with the mounted blob. The primary command maps `tc-db1` and the True Cache command maps `prim-db1`; both mappings are required when the Podman network does not provide container-name DNS.

```bash
sudo podman run -td --name tc-db1 \
  --hostname tc-db1 \
  --network tc_net \
  --ip 10.89.0.12 \
  --add-host=prim-db1:10.89.0.11 \
  --secret=oracle_pwd \
  --secret=oracle_pwd_privkey \
  -e PRIMARY_DB_CONN_STR=prim-db1:1521/FREE \
  -e PRIMARY_DB_NAME=FREE \
  -e TRUE_CACHE=true \
  -e TRUEDB_UNIQUE_NAME=tcdb1 \
  -e PDB_TC_SVCS="FREEPDB1:sales1:sales1_tc" \
  -v "${BASE}/blob:/opt/oracle/truecache/blob:ro" \
  -e TRUE_CACHE_BLOB=/opt/oracle/truecache/blob/blobTestData.tar.gz \
  -v "${BASE}/tcdb1:/opt/oracle/oradata" \
  "${IMAGE}"

sudo podman logs -f tc-db1
```

### Check Setup

Login to TrueCache container:

```bash
podman exec -i -t truedb /bin/bash
```

Check the Truecache setup at the database level using below:

```bash
sqlplus "/as sysdba" << EOF
    select database_name,open_mode,database_role from v$database ;
EOF
```

Sample Output for a working Truecache setup for above SQL query:

```bash
SQL> select database_name,open_mode,database_role from v$database ;

DATABASE_NAME             OPEN_MODE            DATABASE_ROLE
------------------------- -------------------- ----------------
ORCLCDB                   READ ONLY WITH APPLY TRUE CACHE
```

## Minimal Enterprise Edition deployment with TCPS on primary and True Cache

This section describes a complete standalone Podman deployment with **TCPS client access on both sides**:

- Primary Database container: TCP **1521** and TCPS **2484**
- True Cache container: TCP **1521** and TCPS **2484** (on a single host, map True Cache TCPS to a free host port such as **2485** because primary already uses host **2484**)

Enterprise Edition service names `ORCLCDB` / `ORCLPDB1` are used. Adjust host paths, passwords, image tags, and IP addresses for your environment.

**Note:** Application and admin clients use TCPS to reach each database. The True Cache bootstrap path still uses `PRIMARY_DB_CONN_STR` over **TCP 1521** between the containers (for example `prod:1521/ORCLCDB`). That inter-container setup link is separate from client-facing TCPS endpoints.

### Prerequisites

- Podman 4.2 or later on Oracle Linux 8.7 or later
- Base Single Instance image built (see the [main SIDB README](../../README.md))
- True Cache extension image built, for example:

```bash
./buildExtensions.sh -x truecache -b oracle/database:23.26.0-ee -t oracle/database-ext-truecache:23.26.0-ee
```

### Security material used in this deployment

| Material | Purpose |
| --- | --- |
| Host RSA key pair (`key.pem` / `key.pub`) and encrypted password file | Secure Podman secrets (`oracle_pwd`, `oracle_pwd_privkey`). This is **not** used for TCPS. |
| `ENABLE_TCPS=true` on the **primary** | TCPS listener on container port **2484** and a self-signed server certificate plus client wallet under `/opt/oracle/oradata/clientWallet/$ORACLE_SID` in the primary. |
| `ENABLE_TCPS=true` on the **True Cache** container | Same TCPS setup for True Cache (container port **2484**, client wallet under `/opt/oracle/oradata/clientWallet/$ORACLE_SID` in the True Cache container). |
| Custom `cert.crt` / `client.key` | Optional on either container via `TCPS_CERTS_LOCATION` (see [TCPS in the main README](../../README.md#configuring-tcps-connections-for-oracle-database-supported-from-version-1930-onwards)). |
| True Cache bootstrap to primary | `PRIMARY_DB_CONN_STR` uses **TCP 1521** (for example `prod:1521/ORCLCDB`). |

### 1. Define environment values

```bash
export HOST_DATA_ROOT=/scratch/oradata
export DB_PASSWORD='<your-password>'
export PRIMARY_DB_NAME=ORCLCDB
export IMAGE=oracle/database-ext-truecache:23.26.0-ee
```

### 2. Create host directories

Oracle processes in the image run as UID/GID `54321`. The host data directories must be writable by that user.

```bash
mkdir -p /opt/.secrets
mkdir -p ${HOST_DATA_ROOT}/trueCache/prod
mkdir -p ${HOST_DATA_ROOT}/trueCache/truedb
mkdir -p ${HOST_DATA_ROOT}/trueCache/blob
chown -R 54321:54321 ${HOST_DATA_ROOT}/trueCache
```

### 3. Create an encrypted database password secret

Generate an RSA key pair, encrypt the database password with the public key, and remove the plaintext password file. Create Podman secrets named exactly `oracle_pwd` and `oracle_pwd_privkey` so the container can decrypt the password at runtime.

```bash
cd /opt/.secrets
openssl genrsa -out key.pem 2048
openssl rsa -in key.pem -out key.pub -pubout
printf "%s" "${DB_PASSWORD}" > pwdfile.txt
openssl pkeyutl -in pwdfile.txt -out pwdfile.enc -pubin -inkey key.pub -encrypt
rm -f pwdfile.txt

podman secret rm oracle_pwd 2>/dev/null || true
podman secret rm oracle_pwd_privkey 2>/dev/null || true
podman secret create oracle_pwd /opt/.secrets/pwdfile.enc
podman secret create oracle_pwd_privkey /opt/.secrets/key.pem
```

### 4. Create the Podman network

```bash
podman network create --driver=bridge --subnet=172.20.1.0/24 truecache_pub1_n
```

If the network already exists, keep it and continue. For multi-host setups, use `macvlan` or `ipvlan` as described earlier in this document.

### 5. Start the Primary Database container

Map host ports **1521** (TCP), **5500** (EM Express), and **2484** (TCPS). Enable archivelog and force logging for True Cache. Setting `ENABLE_TCPS=true` configures TCPS with a self-signed certificate inside the container; no host TCPS certificate files are required.

Ensure bidirectional name resolution for the True Cache hostname (for example `--add-host=truedb:172.20.1.98`, DNS, or a shared hosts file).

```bash
podman run -d --name prod --hostname prod --ip 172.20.1.2 \
  --net=truecache_pub1_n \
  -p 1521:1521 -p 5500:5500 -p 2484:2484 \
  --secret=oracle_pwd \
  --secret=oracle_pwd_privkey \
  --add-host="truedb:172.20.1.98" \
  --dns-search=example.com \
  -e DOMAIN=example.com \
  -e ORACLE_SID=ORCLCDB \
  -e ORACLE_PDB=ORCLPDB1 \
  -e ENABLE_ARCHIVELOG=true \
  -e ENABLE_FORCE_LOGGING=true \
  -e ENABLE_TCPS=true \
  -v ${HOST_DATA_ROOT}/trueCache/prod:/opt/oracle/oradata \
  ${IMAGE}
```

Monitor creation until the primary logs show:

```text
#########################
DATABASE IS READY TO USE!
#########################
```

```bash
podman logs -f prod
```

### 6. Generate the True Cache blob from the primary

Run this only after the primary is ready. The helper script writes `blobTestData.tar.gz` and depends on `dbcaUtils.sh` packaged in the True Cache extension image.

```bash
export PRIMARY_DB_NAME=ORCLCDB
mkdir -p ${HOST_DATA_ROOT}/trueCache/blob
podman exec prod bash -c "mkdir -p /var/tmp/truecache_blob && /opt/oracle/createBlob.sh /var/tmp/truecache_blob ${PRIMARY_DB_NAME} /opt/oracle/scripts/base/decryptPassword.sh"
podman cp prod:/var/tmp/truecache_blob/blobTestData.tar.gz ${HOST_DATA_ROOT}/trueCache/blob/blobTestData.tar.gz
chown -R 54321:54321 ${HOST_DATA_ROOT}/trueCache/blob
```

Confirm the host file exists before starting True Cache:

```bash
ls -l ${HOST_DATA_ROOT}/trueCache/blob/blobTestData.tar.gz
```

### 7. Start the True Cache container (TCP + TCPS)

Mount the blob directory read-only and set `TRUE_CACHE_BLOB` to the in-container path. Point `PRIMARY_DB_CONN_STR` at the primary **TCP** listener (`hostname:1521/service`) for bootstrap.

Set `ENABLE_TCPS=true` so True Cache also exposes TCPS on container port **2484**. On a single host where the primary already maps host port **2484**, publish True Cache TCPS as host **2485** → container **2484**. On separate hosts, both sides may use host port **2484**.

```bash
podman run -d --name truedb --hostname truedb --ip 172.20.1.98 \
  --net truecache_pub1_n \
  -p 1522:1521 \
  -p 2485:2484 \
  --secret=oracle_pwd \
  --secret=oracle_pwd_privkey \
  --add-host="prod:172.20.1.2" \
  --dns-search=example.com \
  -e DOMAIN=example.com \
  -e ORACLE_SID=truedb \
  -e PRIMARY_DB_CONN_STR=prod:1521/ORCLCDB \
  -e AUTO_TC_SVC_REGISTRATION=false \
  -e TRUE_CACHE=true \
  -e ENABLE_TCPS=true \
  -e TRUEDB_UNIQUE_NAME=truedb \
  -e PDB_TC_SVCS="ORCLPDB1:sales1:sales1_tc" \
  -v ${HOST_DATA_ROOT}/trueCache/blob:/opt/oracle/truecache/blob:ro \
  -e TRUE_CACHE_BLOB=/opt/oracle/truecache/blob/blobTestData.tar.gz \
  -v ${HOST_DATA_ROOT}/trueCache/truedb:/opt/oracle/oradata \
  ${IMAGE}
```

Monitor until the True Cache database is ready:

```bash
podman logs -f truedb
```

With `AUTO_TC_SVC_REGISTRATION=false`, primary-side service association for entries in `PDB_TC_SVCS` remains a manual step (see the service registration notes later in this document).

**If True Cache was created earlier without TCPS**, enable it on the running database and confirm the listener:

```bash
podman exec truedb /opt/oracle/configTcps.sh
podman exec truedb lsnrctl status
```

Then ensure host port **2485** (or your chosen mapping) is published to container **2484**. Adding a new publish mapping requires recreating the container with the same data volume and `-p 2485:2484` (or connect to the container IP on the Podman network, for example `172.20.1.98:2484`).

### 8. Verify connectivity

Confirm both listeners include TCPS:

```bash
podman exec prod lsnrctl status
podman exec truedb lsnrctl status
```

Expected endpoints (container side):

- Primary: TCP `1521` and TCPS `2484`
- True Cache: TCP `1521` and TCPS `2484`

**TCP smoke test** (from a host with Instant Client, or use the mapped ports):

```bash
sqlplus sys/<your-password>@//localhost:1521/ORCLCDB as sysdba
sqlplus sys/<your-password>@//localhost:1522/truedb as sysdba
```

#### Recommended ways to test TCPS

The client wallet `sqlnet.ora` uses `WALLET_LOCATION` with `DIRECTORY = ./`. You **must** `cd` into the wallet directory before connecting so the wallet resolves. Setting only `TNS_ADMIN` to an absolute path without changing the working directory fails (often as `ORA-01017`).

Copy the wallet from the target container. Directory name matches `ORACLE_SID` (True Cache is typically `TRUEDB`):

```bash
podman cp prod:/opt/oracle/oradata/clientWallet/ORCLCDB /tmp/clientWallet-prod
podman cp truedb:/opt/oracle/oradata/clientWallet/TRUEDB /tmp/clientWallet-truedb
```

In `tnsnames.ora`, confirm `(PROTOCOL=TCPS)`. For host access in the single-host example, use `HOST=127.0.0.1` and `PORT=2484` (primary) or `PORT=2485` (True Cache host mapping).

**Method 1 — `cd` + `TNS_ADMIN` + net service name (recommended)**

```bash
cd /tmp/clientWallet-prod
export TNS_ADMIN=$(pwd)
sqlplus sys/<your-password>@ORCLCDB as sysdba
```

True Cache:

```bash
cd /tmp/clientWallet-truedb
export TNS_ADMIN=$(pwd)
# ensure tnsnames.ora PORT matches the host mapping (2485 on single host)
sqlplus sys/<your-password>@TRUEDB as sysdba
```

**Method 2 — Full connect descriptor (still `cd` into the wallet first)**

```bash
cd /tmp/clientWallet-prod
export TNS_ADMIN=$(pwd)
sqlplus sys/<your-password>@'(DESCRIPTION=(ADDRESS=(PROTOCOL=TCPS)(HOST=127.0.0.1)(PORT=2484))(CONNECT_DATA=(SERVICE_NAME=ORCLCDB)))' as sysdba
```

**Method 3 — From inside the container**

```bash
podman exec -it prod bash
cd /opt/oracle/oradata/clientWallet/ORCLCDB
export TNS_ADMIN=$(pwd)
sqlplus sys/<your-password>@ORCLCDB as sysdba
```

```bash
podman exec -it truedb bash
cd /opt/oracle/oradata/clientWallet/TRUEDB
export TNS_ADMIN=$(pwd)
sqlplus sys/<your-password>@TRUEDB as sysdba
```

### Using your own TCPS certificates

To replace self-signed TCPS material on the primary and/or True Cache:

1. Provide `cert.crt` (certificate chain) and `client.key` on the host for that container.
2. Mount the directory into the container and set `TCPS_CERTS_LOCATION` to the in-container path.
3. Keep `ENABLE_TCPS=true` and publish container port **2484** (host **2484** for primary; host **2485** or another free port for True Cache on the same machine).

Do not use the password-encryption files under `/opt/.secrets/key.pem` as TCPS certificates. Full TCPS options are documented in the [main SIDB README](../../README.md#configuring-tcps-connections-for-oracle-database-supported-from-version-1930-onwards).

---

## Environment Variables Explained

**For Truecache Container:**

**NOTE:** Primary-side service creation, startup, and True Cache association for these mappings are manual steps by default.

When `AUTO_TC_SVC_REGISTRATION="true"`, the container invokes a primary-host script through `DBMS_SCHEDULER`. In the supported extension-image workflow, that helper is already prebaked at `/home/oracle/configure-primary-truecache-service.sh` in the image used for both the primary and True Cache pods. If the primary host is outside that workflow, copy [samples/truecache/configure-primary-truecache-service.sh](../../samples/truecache/configure-primary-truecache-service.sh) to `/home/oracle/configure-primary-truecache-service.sh` on the primary host and make it executable by the Oracle software owner, or set `PRIMARY_TC_SERVICE_SCRIPT_PATH` to the custom location chosen by the primary administrator. That helper script is responsible for creating and starting the primary service before it runs the primary-side DBCA association step.

| Parameter or option | Enterprise Edition usage | Free usage | Description | Mandatory/Optional |
| --- | --- | --- | --- | --- |
| `--secret=oracle_pwd` | Use in Primary and True Cache container commands | Use in Primary and True Cache container commands | Supplies the primary SYS password used for primary SQL connectivity, automatic blob generation, and service registration when password-based authentication is used. | Mandatory for password-based flow |
| `--secret=oracle_pwd_privkey` | Use in Primary and True Cache container commands when `oracle_pwd` is encrypted | Use in Primary and True Cache container commands when `oracle_pwd` is encrypted | Decrypts the encrypted `oracle_pwd` secret inside the container. Omit when `oracle_pwd` is a plain Podman secret. | Conditional |
| `DOMAIN` | Example: `example.com` | Example: `example.com` | Domain name used by the container host name and service examples. | Mandatory |
| `ORACLE_SID` | Set for the Enterprise Edition True Cache database, for example `truedb` | Do not set for Free; Free uses `FREE` internally | DB_NAME or SID for the True Cache database. | Mandatory for Enterprise Edition, not used for Free |
| `TRUEDB_UNIQUE_NAME` | Example: `truedb` | Example: `truedb` | DB_UNIQUE_NAME for the True Cache database. | Mandatory |
| `--add-host` | Use on both Primary and True Cache container commands when DNS is unavailable and a shared hostfile is not mounted | Use on both Primary and True Cache container commands when DNS is unavailable and a shared hostfile is not mounted | Adds static hostname-to-IP mappings. The True Cache container must resolve the primary hostname in `PRIMARY_DB_CONN_STR`, and the Primary Database container must resolve the True Cache hostname used by the callback/service connection. Do not use this option when `/opt/containers/truecache_host_file` is mounted as `/etc/hosts`. | Conditional |
| `PRIMARY_DB_CONN_STR` | Example: `prod:1521/ORCLCDB` | Example: `prod:1521/FREE` | Primary DB connection string in `hostname:port/Primary CDB service name` format. Automatic blob generation uses this connection to reach the Primary Database. | Mandatory |
| `PRIMARY_DB_NAME` | Optional when the primary DB_NAME differs from the service name | Set to `FREE` | Primary source DB_NAME override. For Free standalone Podman, set this to `FREE`. | Optional for Enterprise Edition, recommended for Free |
| `TRUE_CACHE` | Set to `true` | Set to `true` | Enables True Cache database creation. | Mandatory |
| `ENABLE_TCPS` | Set to `true` on primary and on True Cache for client TCPS on container port `2484` | Set to `true` on primary and on True Cache when TCPS client access is required | Enables the TCPS listener and creates a self-signed wallet under `/opt/oracle/oradata/clientWallet/$ORACLE_SID` at database create time. On an existing database, run `/opt/oracle/configTcps.sh` inside the container. On one host, map primary `2484:2484` and True Cache `2485:2484` (or another free host port). | Optional for TCP-only clients; required for end-to-end TCPS client access |
| `PDB_TC_SVCS` | Use `ORCLPDB1:<primary_service>:<truecache_service>` entries | Use `FREEPDB1:<primary_service>:<truecache_service>` entries | Semicolon-separated list of `Primary PDB:Primary Service Name:True Cache Service Name` mappings. Primary-side service creation and association are manual by default. | Mandatory |
| `TRUE_CACHE_BLOB` | In-container path to the mounted blob generated from the Primary Database | In-container path to the mounted blob generated from the Primary Database | In-container path to a True Cache blob `.tar.gz` created from the Primary Database. For portable standalone Podman setup, generate the blob before starting the True Cache container, mount it into the container, and set this variable. | Conditional for True Cache |
| `PRIMARY_DB_PWD_FILE` | Not typically used | Alternative to `TRUE_CACHE_BLOB` for Free | Path inside the True Cache container to a mounted copy of the primary database password file. For Free, provide either `TRUE_CACHE_BLOB` or `PRIMARY_DB_PWD_FILE` as the DBCA bootstrap input. | Conditional for Free |
| `TRUE_CACHE_DB_CREDENTIAL_WALLET_DIR` | Optional | Optional | Mounted wallet directory containing the primary DB credential wallet files used by `dbca -createTrueCacheInstance`. This covers the True Cache DBCA create step regardless of whether primary-side service registration is manual or automatic. | Optional |
| `AUTO_TC_SVC_REGISTRATION` | Optional, default `false` | Optional, default `false` | Opt-in parameter to automatically run the primary-side True Cache service registration flow. When set to `true`, the primary-side helper script must already be present on the primary host and executable by the Oracle software owner. | Optional |
| `PRIMARY_TC_SERVICE_SCRIPT_PATH` | Optional | Optional | Path on the primary host that DBMS_SCHEDULER should execute for automatic primary-side True Cache service registration. Default is `/home/oracle/configure-primary-truecache-service.sh`. | Optional |
| `PRIMARY_TC_SERVICE_WALLET_PATH` | Optional | Optional | Primary-host path to a mkstore wallet directory that DBCA should use for the primary-side True Cache service-configuration step. When set, the helper prefers this wallet over raw password stdin. | Optional |

## Support

Oracle True Cache is supported from version 23ai and later releases.

## License

To download and run Oracle True Cache, regardless whether inside or outside a Container, ensure to download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project docker-images/OracleDatabase repository required to build the Docker and Podman images are, unless otherwise noted, released under UPL 1.0 license.

## Copyright

Copyright (c) 2022 - 2024 Oracle and/or its affiliates.
Released under the Universal Permissive License v1.0 as shown at [https://oss.oracle.com/licenses/upl/](https://oss.oracle.com/licenses/upl/)
