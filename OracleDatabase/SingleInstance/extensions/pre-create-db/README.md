#  Pre-Create Database

This extension adds a layer on top of a base Oracle image with a pre-created
database in a multitenant configuration with one pluggable database and 
a pre-set password. This can save 10-15 minutes of database creation time in
some simple workflows, like making first steps,
conducting experiments, or running tests.

*The database files are created on the image filesystem itself, 
which means you can not use a separate volume for oradata anymore*

Once you have created the base image, go into the **extension/pre-create-db** folder and build a new extended image as follows:

    [oracle@localhost dockerfiles]$ docker build -t <new image name> . \
        --build-arg BASE_IMAGE=<base image> \
        --build-arg PRE_CREATE_ORACLE_SID=<your CDB name> \
        --build-arg PRE_CREATE_ORACLE_PDB=<your PDB name> \
        --build-arg PRE_CREATE_ORACLE_PWD=<your password>

Example

    docker build -t oracle/database:ext . \
        --build-arg BASE_IMAGE=oracle/database:12.2.0.1-ee \
        --build-arg PRE_CREATE_ORACLE_SID=MYCDB \
        --build-arg PRE_CREATE_ORACLE_PDB=MYPDB \
        --build-arg PRE_CREATE_ORACLE_PWD=Welcome1

The resulting image will contain a MYCDB database in a
multitenant configuration with one pluggable database MYPDB.

The new image can then be started like this:

    docker run --name mydb \
        -p 1521:1521 -p 5500:5500 \
        -e ORACLE_SID=MYCDB \
        oracle/database:ext