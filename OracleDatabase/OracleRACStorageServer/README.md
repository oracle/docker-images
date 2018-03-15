Oracle ASM on NFS Server for RAC testing
=======================================

Sample Docker build files to facilitate installation, configuration, and environment setup for DevOps users.

IMPORTANT: This image can be used to setup ASM on NFS for RAC. You can skip if you have physical block devices or NAS server for Oracle RAC and Grid. You need to make sure that NFS server container must be up and running for RAC functioning. This image is for only testing purpose.

You need to make sure that you have enough space available for container.

	Note: If you are behind the proxy, you need to set http_proxy env variable based on your enviornment before building the image.

- Change your directory to (DOCKER_RAC_IMAGE)/dockerfile folder and execute following command:

 	 #./buildDockerImage.sh -v (Software Version)

	 #./buildDockerImage.sh -v 12.2.0.1

	 For detailed usage of command, please execute folowing command:
	[oracle@localhost dockerfiles]$ ./buildDockerImage.sh -h

- Before creating container, create the bridge for NFS storage container. Also, replace IP according to your environment.

         #docker network create --driver=bridge --subnet=192.168.17.0/24 rac_priv1_nw
       
- SELINUX must be in permissive mode.

- Create Containers. We are creating container in non-priv mode.

        #docker run -d -t --hostname racnode-storage \
        --dns-search=example.com  --cap-add SYS_ADMIN \
        --volume /docker_volumes/asm_vol/$ORACLE_SID:/oradata --init \
        --network=rac_priv1_nw --ip=192.168.17.25 --tmpfs=/run  \
        --volume /sys/fs/cgroup:/sys/fs/cgroup:ro \
        --name racnode-storage oracle/rac-storage-server:12.2.0.1

	Note: During the container startup 5 files named as asm_disk0[1-5].img will be created under /oradata.If the files are already present, they will not be recreated.These files can be used for ASM storage in RAC containers.

- Expose directory to container which has enough space. In the above example, we are using /docker_volumes/asm_vol/$ORACLE_SID and you need to change to according to your env. Inside container, it will be /oradata and do not change this.

- In the above example, we used 192.168.17.0/24 subnet for NFS server.

- To check the racstorage container/services creation logs , please tail docker logs. It will take 10 minutes to create the racnode-storage container service. docker logs -f racnode-storage you should see following in docker logs output:

 ####################################################

        runOracle.sh: NFS Server is up and running

         Create NFS volume for /oradata

 ####################################################

IMPORTANT: The NFS volume must be /oradata which you will export to RAC containers for ASM storage. It will take 10 minutes for setting up NFS server.

- Create NFS volume using following command:

         #docker volume create --driver local \
        --opt type=nfs \
        --opt   o=addr=192.168.17.25,rw,bg,hard,tcp,vers=3,timeo=600,rsize=32768,wsize=32768,actimeo=0 \
         --opt device=:/oradata \
                racstorage

- You need to change addr= based on your enviornment.
