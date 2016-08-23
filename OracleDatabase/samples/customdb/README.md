Example of creating a custom database
=============================================
Once you have built your image you can create a database with a custom name by passing on two environment variables.

# How to start the container
First make sure you have built **oracle/database:12.1.0.2-ee**. Now start the container as follow:

	docker run --name customdb \
	-p 1521:1521 -p 5500:5500 \
	-e ORACLE_SID=<your SID> \
	-e ORACLE_PDB=<your PDB name> \
	oracle/database:12.1.0.2-ee

Following parameters are passed on:
* ORACLE_SID: The Oracle SID and container database name
* ORACLE_PDB: The Oracle PDB name

After the container is up and running you can connect to the new database.
Remember that the database uses an automatically generated password for the admin accounts.
If you want to change the password refer to [Changing the admin accounts passwords](https://github.com/gvenzl/docker-images/tree/master/OracleDatabase#changing-the-admin-accounts-passwords):

	sql system/<your new db password>@//localhost:1521/<your new SID/PDB name>

The above scenario from this sample will give you a new custom database within the Oracle Database Docker image.

# Copyright
Copyright (c) 2014-2016 Oracle and/or its affiliates. All rights reserved.
