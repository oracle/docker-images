Example of a container including Starter Set data
=================================================
This example shows how to create starter set data in the Oracle Database inside a Docker container.
The starterset.sql file contains the desired SQL commands to be executed.
This example creates a new user `TEST` within the `STARTERSET` PDB, creates a new table called `PEOPLE` and add some data.

# How to build and run
First make sure you have started a container using the **oracle/database:12.1.0.2-ee** image:

	docker run --name starterset \
	-p 1521:1521 -p 5500:5500 \
	-e ORACLE_PDB=STARTERSET \
	-v /home/oracle/oradata:/opt/oracle/oradata \
	oracle/database:12.1.0.2-ee

Then change the password of the admin accounts:

	docker exec starterset ./setPassword.sh LetsDocker

Now you can just execute the starterset.sql file outside the container:

	sql sys/LetsDocker@//localhost:1521/STARTERSET as sysdba @starterset.sql

And then connect with the `TEST` user and query the table `PEOPLE`:

	sql test/test@//localhost:1521/STARTERSET

	SQLcl: Release 4.2.0.16.175.1027 RC on Tue Aug 23 11:00:04 2016

	Copyright (c) 1982, 2016, Oracle.  All rights reserved.

	Connected to:
	Oracle Database 12c Enterprise Edition Release 12.1.0.2.0 - 64bit Production
	With the Partitioning, OLAP, Advanced Analytics and Real Application Testing options


	SQL> SELECT name FROM people;

	NAME
	----------
	Larry
	Bruno
	Gerald

	SQL> exit
	Disconnected from Oracle Database 12c Enterprise Edition Release 12.1.0.2.0 - 64bit Production
	With the Partitioning, OLAP, Advanced Analytics and Real Application Testing options

The above scenario from this sample will give you a starter set within the Oracle Database Docker image.

# Copyright
Copyright (c) 2014-2016 Oracle and/or its affiliates. All rights reserved.
