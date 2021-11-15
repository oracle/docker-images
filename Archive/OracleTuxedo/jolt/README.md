
Tuxedo Jolt sample on Docker
===============

## How to run
1. Build Tuxedo 12.2.2 Docker image by following the [TuxedoCore 12.2.2](../core/dockerfiles) for 12.2.2.
2. Execute: `buildDockerImage.sh` 
   Or: `docker build -t oracle/tuxedojolt .`

You can then start the image in a new container with:  
docker run -d -h jolthost -p 11304:1304 -v \${LOCAL_DIR}:/u01/oracle/user_projects --name tuxedojolt oracle/tuxedojolt

Note: \${LOCAL_DIR} is a local dir which used in docker image as external storage, it can be any dir in host machine, permission of this dir should be set like this:
    $ docker run -ti --rm --entrypoint="/bin/bash" oracle/tuxedojolt -c "whoami && id" tuxedojolt
      oracle
      uid=1000(oracle) gid=1000(oracle) groups=1000(oracle)
    $ sudo chown -R 1000 \${LOCAL_DIR}

In the container, it starts the tuxedo jolt domain. To run a jolt client outside the container, you can:
1. Into a empty dir, compose your own joltclient 'joltclient.java' to call service 'TOUPPER', and update the APPADDRESS to:
          sattr.setString(sattr.APPADDRESS, "//$host_machine:11304");  //$host_machine is the machine name of the docker host machine
2. Set environment variable, 
   $ source $TUXDIR/tux.env
3. Set CLASSPATH
   $ export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar:$TUXDIR/udataobj/jolt/jolt.jar:$TUXDIR/udataobj/jolt/joltadmin.jar
4. Build the client
   $ javac joltclient.java
5. Run the client
   $ java joltclient

