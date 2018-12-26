# Oracle ASM on NFS Server for RAC testing
Sample Docker build files to facilitate installation, configuration, and environment setup for DevOps users.

**IMPORTANT:** This image can be used to setup ASM on NFS for RAC. You can skip if you have physical block devices or NAS server for Oracle RAC and Grid. You need to make sure that NFS server container must be up and running for RAC functioning. This image is for only testing purpose.

## How to build and run
You need to make sure that you have atleast 60GB space available for container to create the files for RAC storage.

**IMPORTANT:** If you are behind the proxy, you need to set http_proxy env variable based on your enviornment before building the image.

To assist in building the images, you can use the [buildDockerImage.sh](dockerfiles/buildDockerImage.sh) script. See below for instructions and usage.

The `buildDockerImage.sh` script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call `docker build` with their prefered set of parameters. Go into the **dockerfiles** folder and run the **buildDockerImage.sh** script:

```
./buildDockerImage.sh -v (Software Version)
./buildDockerImage.sh -v 18.3.0
```

**NOTE**: To build RACStorage Image for 18.3.0, pass the version 18.3.0 to buildDockerImage.sh

For detailed usage of command, please execute folowing command:
```
./buildDockerImage.sh -h
```

### Create Bridge
Before creating container, create the bridge for NFS storage container.

```
docker network create --driver=bridge --subnet=192.168.17.0/24 rac_priv1_nw
```

**Note:** You can change subnet according to your environment.

### Disable SELINUX
SELINUX must be disabled or in permissive mode.

### NFS Server installation on Docker Host
You must install NFS server rpms on docker host to utilize NFS volumes in containers.

```
yum -y install nfs-utils
```

### Running RACStorageServer Docker container
Execute following command to create the container:

```
docker run -d -t --hostname racnode-storage \
--dns-search=example.com  --cap-add SYS_ADMIN \
--volume /docker_volumes/asm_vol/$ORACLE_SID:/oradata --init \
--network=rac_priv1_nw --ip=192.168.17.25 --tmpfs=/run  \
--volume /sys/fs/cgroup:/sys/fs/cgroup:ro \
--name racnode-storage oracle/rac-storage-server:18.3.0
```

**IMPORTANT:** During the container startup 5 files named as asm_disk0[1-5].img will be created under /oradata.If the files are already present, they will not be recreated.These files can be used for ASM storage in RAC containers.

**NOTE**: Expose directory to container which has atleast 60GB. In the above  example, we are using /docker_volumes/asm_vol/$ORACLE_SID and you need to change values according to your env. Inside container, it will be /oradata and do not change this.

In the above example, we used **192.168.17.0/24** subnet for NFS server. You can change the subnet values according to your environment.

To check the racstorage container/services creation logs , please tail docker logs. It will take 10 minutes to create the racnode-storage container service.

```
docker logs -f racnode-storage
```

you should see following in docker logs output:

```
#################################################
runOracle.sh: NFS Server is up and running
Create NFS volume for /oradata
#################################################
```
**IMPORTANT:** The NFS volume must be /oradata which you will export to RAC containers for ASM storage. It will take 10 minutes for setting up NFS server.

### NFS Volume
Create NFS volume using following command:

```
docker volume create --driver local \
--opt type=nfs \
--opt   o=addr=192.168.17.25,rw,bg,hard,tcp,vers=3,timeo=600,rsize=32768,wsize=32768,actimeo=0 \
--opt device=:/oradata \
racstorage
```

**IMPORTANT:** If you are not using 192.168.17.0/24 subnet then you need to change **addr=192.168.17.25** based on your environment.
