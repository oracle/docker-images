Running Oracle TSAM Plus with oracle/database:11.2.0.2-xe image
=============================
You can run the TSAM container with the `oracle/database:11.2.0.2-xe` image provided on [GitHub](https://github.com/oracle/docker-images/tree/master/OracleDatabase).

Due to the `oracle/database:11.2.0.2-xe` container creates new database and generates random `sys` user password on startup, a little "hacking" is needed here to make the `sys` password fixed.

Basically this is done by overriding the default command `runOracle.sh` with this [modified one](cmd/runOracle.sh) in the `cmd` folder. The `docker-compose.yml` file to start the containers will look like below:

```yaml
version: "2"
services:
  db:
    image: oracle/database:11.2.0.2-xe
    hostname: db.box
    shm_size: 1g
    environment:
      - DBA_PASSWD=welcome1
    volumes:
      - ./cmd:/tmp/cmd
    ports:
      - 1521/tcp
      - 22/tcp
    command: "bash -c 'cp -f /tmp/cmd/runOracle.sh /u01/app/oracle && /u01/app/oracle/runOracle.sh'"
  tsam:
    image: oracle/tsam:12.2.2.1
    hostname: tsam.docker
    ports:
      - 7001/tcp
      - 22/tcp
    privileged: true
    environment:
      - "DB_CONNSTR=db.box:1521/orcl"
      - "DB_TSAM_USER=tsam"
      - "DB_TSAM_PASSWD=tsam"
      - "TSAM_CONSOLE_ADMIN_PASSWD=admin1"
      - "DBA_USER=sys"
      - "DBA_PASSWD=welcome1"
      - "DB_TSAM_TBLSPACE=users"
      - "WLS_PW=weblogic1"
    links:
      - db:db.box
```
