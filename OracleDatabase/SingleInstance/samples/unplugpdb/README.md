Example of how to unplug a PDB from a Docker container
======================================================
This example demonstrates how to unplug a PDB inside a Docker container.
Unplugging a PDB allows you to move the PDB from a Container Database (CDB) to another.
The other CDB can reside either in another Docker container or outside.

Also have a look at [samples/plugpdb](../plugpdb) for how to plug a PDB into a CDB inside a Docker container.

# How to build and run
First make sure you have started a container using the **oracle/database:12.2.0.1-ee** image
(you can substitue the image for the version you want):

	docker run --name unplugpdb \
	-p 1521:1521 -p 5500:5500 \
	-e ORACLE_SID=DEVOPSCDB \
	-e ORACLE_PDB=MYPDB \
	-v /home/oracle/oradata:/opt/oracle/oradata \
	oracle/database:12.2.0.1-ee

Then change the password of the admin accounts:

	docker exec unplugpdb ./setPassword.sh unplug

Now you can unplug the PDB called `MYPDB`:

    sql sys/unplug@//localhost:1521/DEVOPSCDB as sysdba
    
    SQLcl: Release 4.2.0 Production on Mon Mar 06 11:54:13 2017
    
    Copyright (c) 1982, 2017, Oracle.  All rights reserved.
    
    Connected to:
    Oracle Database 12c Enterprise Edition Release 12.2.0.1.0 - 64bit Production
    
    SQL> ALTER PLUGGABLE DATABASE MYPDB CLOSE IMMEDIATE;
    
    Pluggable database MYPDB altered.
    
    SQL> ALTER PLUGGABLE DATABASE MYPDB UNPLUG INTO '/opt/oracle/oradata/DEVOPSCDB/MYPDB/mypdb.xml';
    
    Pluggable database MYPDB altered.
    
    SQL> DROP PLUGGABLE DATABASE MYPDB KEEP DATAFILES;
    
    Pluggable database MYPDB dropped.
    
    SQL> exit;
    
    Disconnected from Oracle Database 12c Enterprise Edition Release 12.2.0.1.0 - 64bit Production

Once the PDB is unplugged you can copy/move it from the volume mount point (see -v option above):

    [oracle@localhost ~]$ ls -al /home/oracle/oradata/DEVOPSCDB/MYPDB/
    total 711724
    drwxrwxrwx. 2 500 500        98 Mar  6 11:55 .
    drwxrwxrwx. 4 500 500      4096 Mar  6 11:46 ..
    -rwxrwxrwx. 1 500 500      7344 Mar  6 11:55 mypdb.xml
    -rwxrwxrwx. 1 500 500 356524032 Mar  6 11:55 sysaux01.dbf
    -rwxrwxrwx. 1 500 500 262152192 Mar  6 11:55 system01.dbf
    -rwxrwxrwx. 1 500 500 104865792 Mar  6 11:55 undotbs01.dbf
    -rwxrwxrwx. 1 500 500   5251072 Mar  6 11:55 users01.dbf
	
    [oracle@localhost ~]$ mv /home/oracle/oradata/DEVOPSCDB/MYPDB .

The above scenario demonstrates how you can unplug a PDB inside a Docker container.

# Copyright
Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
