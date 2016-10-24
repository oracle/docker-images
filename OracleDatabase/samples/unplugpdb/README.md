Example of how to unplug a PDB from a Docker container
======================================================
This example demonstrates how to unplug a PDB inside a Docker container.
Unplugging a PDB allows you to move the PDB from a Container Database (CDB) to another.
The other CDB can reside either in another Docker container or outside.

Also have a look at `samples/plugpdb` for how to plug a PDB into a CDB inside a Docker container.

# How to build and run
First make sure you have started a container using the **oracle/database:12.1.0.2-ee** image:

	docker run --name unplugpdb \
	-p 1521:1521 -p 5500:5500 \
	-e ORACLE_SID=DEVOPSCDB \
	-e ORACLE_PDB=MYPDB \
	-v /home/oracle/oradata:/opt/oracle/oradata \
	oracle/database:12.1.0.2-ee

Then change the password of the admin accounts:

	docker exec unplugpdb ./setPassword.sh LetsDocker

Now you can unplug the PDB called `MYPDB`:

	sql sys/LetsDocker@//localhost:1521/DEVOPSCDB as sysdba
	
	SQLcl: Release 4.2.0.16.175.1027 RC on Mon Oct 24 14:21:45 2016
	
	Copyright (c) 1982, 2016, Oracle.  All rights reserved.
	
	Connected to:
	Oracle Database 12c Enterprise Edition Release 12.1.0.2.0 - 64bit Production
	With the Partitioning, OLAP, Advanced Analytics and Real Application Testing options
	
	SQL> ALTER PLUGGABLE DATABASE MYPDB CLOSE IMMEDIATE;
	
	Pluggable database MYPDB altered.
	
	SQL> ALTER PLUGGABLE DATABASE MYPDB UNPLUG INTO '/opt/oracle/oradata/DEVOPSCDB/MYPDB/mypdb.xml';
	
	Pluggable database MYPDB altered.
	
	SQL> DROP PLUGGABLE DATABASE MYPDB KEEP DATAFILES;
	
	Pluggable database MYPDB dropped.
	
	SQL> exit;
	
	Disconnected from Oracle Database 12c Enterprise Edition Release 12.1.0.2.0 - 64bit Production
	With the Partitioning, OLAP, Advanced Analytics and Real Application Testing options

Once the PDB is unplugged you can copy/move it from the volume mount point (see -v option above):

	[oracle@localhost ~]$ ls -al /home/oracle/oradata/DEVOPSCDB/MYPDB/
	total 844836
	drwxr-x--- 2 oracle 500        84 Oct 24 14:23 .
	drwxr-x--- 4 oracle 500      4096 Oct 24 13:48 ..
	-rw-r----- 1 oracle 500   5251072 Oct 24 14:22 MYPDB_users01.dbf
	-rw-r--r-- 1 oracle 500      5351 Oct 24 14:22 mypdb.xml
	-rw-r----- 1 oracle 500 597696512 Oct 24 14:22 sysaux01.dbf
	-rw-r----- 1 oracle 500 262152192 Oct 24 14:22 system01.dbf
	
	[oracle@localhost ~]$ mv /home/oracle/oradata/DEVOPSCDB/MYPDB .

The above scenario demonstrates how you can unplug a PDB inside a Docker container.

# Copyright
Copyright (c) 2014-2016 Oracle and/or its affiliates. All rights reserved.
