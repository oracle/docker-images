Example of how to plug a PDB into a Container Database inside a Docker container
================================================================================
This example demonstrates how to plug a PDB into a Container Database (CDB) inside a Docker container.
Plugging a PDB into a CDB allows you to open an already existing PDB in another CDB.
This approach gives you great flexibility of moving databases (PDBs) around.
Note that the CDB can reside inside a Docker container but does not have to!

Also have a look at [samples/unplugpdb](../unplugpdb) for how to unplug a PDB inside a Docker container.

# How to build and run
First make sure you have started a container using the **oracle/database:12.1.0.2-ee** image:

	docker run --name plugpdb \
	-p 1521:1521 -p 5500:5500 \
	-e ORACLE_SID=DEVOPSUATCDB \
	-v /home/oracle/oradata:/opt/oracle/oradata \
	oracle/database:12.1.0.2-ee

Then change the password of the admin accounts:

	docker exec plugpdb ./setPassword.sh LetsDocker

As a next steps you have to copy/move the PDB data files into the volumes mount point
(see -v option above) in order for the Docker container and CDB to see it:

	[oracle@localhost ~]$ mv MYPDB /home/oracle/oradata/DEVOPSUATCDB/
	[oracle@localhost ~]$ ls -al /home/oracle/oradata/DEVOPSUATCDB/
	total 1892876
	drwxr-x--- 5 oracle    500      4096 Oct 24 15:39 .
	drwxrwxr-x 8 oracle oracle       105 Oct 24 15:39 ..
	-rw-r----- 1 oracle    500  17973248 Oct 24 15:39 control01.ctl
	drwxr-x--- 2 oracle    500        84 Oct 24 14:23 MYPDB
	drwxr-x--- 2 oracle    500       110 Oct 24 14:45 ORCLPDB1
	drwxr-x--- 2 oracle    500        91 Oct 24 14:37 pdbseed
	-rw-r----- 1 oracle    500  52429312 Oct 24 14:45 redo01.log
	-rw-r----- 1 oracle    500  52429312 Oct 24 14:46 redo02.log
	-rw-r----- 1 oracle    500  52429312 Oct 24 15:39 redo03.log
	-rw-r----- 1 oracle    500 671096832 Oct 24 15:35 sysaux01.dbf
	-rw-r----- 1 oracle    500 828383232 Oct 24 15:35 system01.dbf
	-rw-r----- 1 oracle    500 206577664 Oct 24 15:06 temp01.dbf
	-rw-r----- 1 oracle    500 256909312 Oct 24 15:35 undotbs01.dbf
	-rw-r----- 1 oracle    500   5251072 Oct 24 14:51 users01.dbf

Now you can plug the already existing PDB called `MYPDB` into the CDB:
	
	sql sys/LetsDocker@//localhost:1521/DEVOPSUATCDB as sysdba
	
	SQLcl: Release 4.2.0.16.175.1027 RC on Mon Oct 24 15:40:32 2016
	
	Copyright (c) 1982, 2016, Oracle.  All rights reserved.
	
	Connected to:
	Oracle Database 12c Enterprise Edition Release 12.1.0.2.0 - 64bit Production
	With the Partitioning, OLAP, Advanced Analytics and Real Application Testing options
	
	SQL> CREATE PLUGGABLE DATABASE MYPDB USING '/opt/oracle/oradata/DEVOPSUATCDB/MYPDB/mypdb.xml'
	  2  SOURCE_FILE_DIRECTORY='/opt/oracle/oradata/DEVOPSUATCDB/MYPDB'
	  3  NOCOPY;
	
	Pluggable database MYPDB created.
	
	SQL> ALTER PLUGGABLE DATABASE MYPDB OPEN;
	
	Pluggable database MYPDB altered.
	
	SQL> ALTER PLUGGABLE DATABASE MYPDB SAVE STATE;
	
	Pluggable database MYPDB altered.
	
Once the PDB is plugged in and open you can connect to it:
	
	sql pdbadmin/LetsDocker@//localhost:1521/MYPDB
	
	SQLcl: Release 4.2.0.16.175.1027 RC on Mon Oct 24 15:45:42 2016
	
	Copyright (c) 1982, 2016, Oracle.  All rights reserved.
	
	Connected to:
	Oracle Database 12c Enterprise Edition Release 12.1.0.2.0 - 64bit Production
	With the Partitioning, OLAP, Advanced Analytics and Real Application Testing options
	
	SQL> exit;
	
	Disconnected from Oracle Database 12c Enterprise Edition Release 12.1.0.2.0 - 64bit Production
	With the Partitioning, OLAP, Advanced Analytics and Real Application Testing options

The above scenario demonstrates how you can plug an existing PDB
into the Container Database inside a Docker container.

# Copyright
Copyright (c) 2014-2016 Oracle and/or its affiliates. All rights reserved.
