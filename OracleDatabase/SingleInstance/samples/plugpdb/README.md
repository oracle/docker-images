Example of how to plug a PDB into a Container Database inside a Docker container
================================================================================
This example demonstrates how to plug a PDB into a Container Database (CDB) inside a Docker container.
Plugging a PDB into a CDB allows you to open an already existing PDB in another CDB.
This approach gives you great flexibility of moving databases (PDBs) around.
Note that the CDB can reside inside a Docker container but does not have to!

Also have a look at [samples/unplugpdb](../unplugpdb) for how to unplug a PDB inside a Docker container.

# How to build and run
First make sure you have started a container using the **oracle/database:12.2.0.1-ee** image
(you can substitue the image for the version you want):

    docker run --name plugpdb \
    -p 1521:1521 -p 5500:5500 \
    -e ORACLE_SID=DEVOPSUATCDB \
    -v /home/oracle/oradata:/opt/oracle/oradata \
    oracle/database:12.2.0.1-ee

Then change the password of the admin accounts:

    docker exec plugpdb ./setPassword.sh plug

As a next steps you have to copy/move the PDB data files into the volumes mount point
(see -v option above) in order for the Docker container and CDB to see it:

    [oracle@localhost ~]$ mv MYPDB /home/oracle/oradata/DEVOPSUATCDB/
    [oracle@localhost ~]$ ls -al /home/oracle/oradata/DEVOPSUATCDB/
	[oracle@localhost ~]$ sudo ls -al /home/oracle/oradata/DEVOPSUATCDB/
    total 2000808
    drwxr-x---. 5    500    500      4096 Mar  6 12:41 .
    drwxrwxrwx. 8 oracle oracle      4096 Mar  6 12:00 ..
    -rw-r-----. 1    500    500  18726912 Mar  6 12:41 control01.ctl
    drwxrwxrwx. 2    500    500        98 Mar  6 11:55 MYPDB
    drwxr-x---. 2    500    500        99 Mar  6 12:08 ORCLPDB1
    drwxr-x---. 2    500    500      4096 Mar  6 12:03 pdbseed
    -rw-r-----. 1    500    500 209715712 Mar  6 12:07 redo01.log
    -rw-r-----. 1    500    500 209715712 Mar  6 12:41 redo02.log
    -rw-r-----. 1    500    500 209715712 Mar  6 12:07 redo03.log
    -rw-r-----. 1    500    500 482353152 Mar  6 12:38 sysaux01.dbf
    -rw-r-----. 1    500    500 838868992 Mar  6 12:27 system01.dbf
    -rw-r-----. 1    500    500  34611200 Mar  6 12:04 temp01.dbf
    -rw-r-----. 1    500    500  73408512 Mar  6 12:38 undotbs01.dbf
    -rw-r-----. 1    500    500   5251072 Mar  6 12:07 users01.dbf

Now you can plug the already existing PDB called `MYPDB` into the CDB:
	
    sql sys/plug@//localhost:1521/DEVOPSUATCDB as sysdba
    
    SQLcl: Release 4.2.0 Production on Mon Mar 06 12:43:29 2017
    
    Copyright (c) 1982, 2017, Oracle.  All rights reserved.
    
    Connected to:
    Oracle Database 12c Enterprise Edition Release 12.2.0.1.0 - 64bit Production
	
    SQL> CREATE PLUGGABLE DATABASE MYPDB USING '/opt/oracle/oradata/DEVOPSUATCDB/MYPDB/mypdb.xml'
	  2  SOURCE_FILE_DIRECTORY='/opt/oracle/oradata/DEVOPSUATCDB/MYPDB'
	  3  NOCOPY;
    	
    Pluggable database MYPDB created.
    
    SQL> ALTER PLUGGABLE DATABASE MYPDB OPEN;
    
    Pluggable database MYPDB altered.
    
    SQL> ALTER PLUGGABLE DATABASE MYPDB SAVE STATE;
    
    Pluggable database MYPDB altered.
	
Once the PDB is plugged in and open you can connect to it:
	
    sql pdbadmin/unplug@//localhost:1521/MYPDB
    
    SQLcl: Release 4.2.0 Production on Mon Mar 06 12:45:31 2017
    
    Copyright (c) 1982, 2017, Oracle.  All rights reserved.
    
    Connected to:
    Oracle Database 12c Enterprise Edition Release 12.2.0.1.0 - 64bit Production
    
    SQL> exit;
    
    Disconnected from Oracle Database 12c Enterprise Edition Release 12.2.0.1.0 - 64bit Production

The above scenario demonstrates how you can plug an existing PDB
into the Container Database inside a Docker container.

# Copyright
Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
