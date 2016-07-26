Example of Image with Starter set data
================================
This Dockerfile extends the Oracle Database image by creating a sample starter set.

The starterset.sql file is copied into the image which contains the commands for creating the starter set.
This example creates a new user TEST within the ORCLPDB1 PDB and then adds a new table called COOL_PEOPLE.

# How to build and run
First make sure you have built **oracle/database:12.1.0.2-ee**. Now, to build this sample, run:

        docker build --build-arg ORACLE_PWD=<Your DB password> -t example/starterset .

To start the containerized Oracle Database, run:

        docker run --name starterset -p 1521:1521 example/starterset

After the container is up and running, you can connect with the TEST user and query the table COOL_PEOPLE:

        sql test/test@//localhost:1521/ORCLPDB1

        SQLcl: Release 4.2.0.16.175.1027 RC on Mon Jul 25 22:42:52 2016

        Copyright (c) 1982, 2016, Oracle.  All rights reserved.

        Connected to:
        Oracle Database 12c Enterprise Edition Release 12.1.0.2.0 - 64bit Production
        With the Partitioning, OLAP, Advanced Analytics and Real Application Testing options


        SQL> SELECT name FROM cool_people;

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
