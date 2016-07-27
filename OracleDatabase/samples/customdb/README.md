Example of Image for creating custom database
=============================================
This Dockerfile extends the Oracle Database image by creating a custom database.

This example drops the provided database and creates a new one with a different name.
This example is provided because a lot of people have their own naming conventions and
would like to use them rather than having a predefined database name.

# How to build and run
First make sure you have built **oracle/database:12.1.0.2-ee**. Now, to build this sample, run:

        docker build \
        --build-arg DB_PWD=<Original DB SYS password> \
        --build-arg DB_PWD_NEW=<New DB password> \
        --build-arg SID=<Database SID> \
        --build-arg PDB=<PDB name> \
        -t example/customdb .

Following parameters are passed on:
* DB_PWD: The password of the originally created database (the one used for building the base image)
* DB_PWD_NEW: The new password that should be used (remains unchanged by default)
* SID: The new database SID that should be used (i.e. CDB name)
* PDB: The new PDB name that should be used

To start the containerized Oracle Database, run:

        docker run --name customdb -p 1521:1521 example/customdb

After the container is up and running you can connect to the new database:

        sql system/<your new db password>@//localhost:1521/<your new SID/PDB name>

The above scenario from this sample will give you a new custom database within the Oracle Database Docker image.

# Copyright
Copyright (c) 2014-2016 Oracle and/or its affiliates. All rights reserved.
