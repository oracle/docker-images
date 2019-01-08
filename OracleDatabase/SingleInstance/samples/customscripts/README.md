Example of automatically executing custom scripts after database setup/startup
=================================================
This example shows how to automatically execute custom scripts after the database is started.
The this done in both cases, once the database is setup and started, or once the container is restarted
with an already existing database.  
The container is aware of the location `/opt/oracle/scripts/setup` and `/opt/oracle/scripts/startup`
(`/u01/app/oracle/scripts/setup` and `/u01/app/oracle/scripts/startup` for XE) and will
automatically search for shell (*.sh) and SQL (*.sql) scripts.
If found, the container will execute them either after the setup or the startup of the database.
All the user has to do is to map a volume including those scripts to that location.  
SQL scripts will be executed as sysdba, shell scripts will be executed as the current user.
To ensure proper order it is recommended to prefix your scripts with a number. For example 
`01_users.sql`, `02_permissions.sql`, etc.  
This example creates a new user `TEST` within the `CUSTOMSCRIPTS` PDB, creates a new table called `PEOPLE` and add some data.

# How to build and run
Just start a container using the **oracle/database:12.2.0.1-ee** image and exposing the custom scripts folder using the `-v` parameter:

```
docker run --name customscripts \
-p 1521:1521 -p 5500:5500 \
-e ORACLE_SID=ORCLSCRIPT \
-e ORACLE_PDB=CUSTOMSCRIPTS \
-v /home/oracle/oradata:/opt/oracle/oradata \
-v /home/oracle/docker/samples/customscripts:/opt/oracle/scripts/setup \
oracle/database:12.2.0.1-ee
```

Once the database is setup you will see the following in the output:

```
Executing user defined scripts
/opt/oracle/runOracle.sh: running /opt/oracle/scripts/setup/01_shellExample.sh
Environment: Linux 51f09a648c8e 4.1.12-94.3.8.el7uek.x86_64 #2 SMP Fri Jun 30 10:40:13 PDT 2017 x86_64 x86_64 x86_64 GNU/Linux

/opt/oracle/runOracle.sh: running /opt/oracle/scripts/setup/02_createUser.sql

Session altered.


User created.


Grant succeeded.


User altered.



/opt/oracle/runOracle.sh: running /opt/oracle/scripts/setup/03_addTable.sql

Table created.


1 row created.


1 row created.


1 row created.


Commit complete.



/opt/oracle/runOracle.sh: ignoring /opt/oracle/scripts/setup/README.md

DONE: Executing user defined scripts
```

Now you can connect with the `TEST` user and query the table `PEOPLE`:

```
sql test/test@//localhost:1521/CUSTOMSCRIPTS

SQLcl: Release 4.2.0 Production on Mon Jul 10 08:31:37 2017

Copyright (c) 1982, 2017, Oracle.  All rights reserved.

Connected to:
Oracle Database 12c Enterprise Edition Release 12.2.0.1.0 - 64bit Production


SQL> SELECT name FROM people;

NAME
----------
Larry
Bruno
Gerald

SQL> exit

Disconnected from Oracle Database 12c Enterprise Edition Release 12.2.0.1.0 - 64bit Production
```

The above scenario from this sample will setup or start a database and run your custom scripts afterwards.

# Copyright
Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
