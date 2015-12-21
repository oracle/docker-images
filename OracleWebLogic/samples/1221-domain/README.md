Example of Image with WLS Domain
================================
This Dockerfile extends the Oracle WebLogic image by creating a sample empty domain.

Util scripts are copied into the image enabling users to plug NodeManager automatically into the AdminServer running on another container.

# How to build and run
First make sure you have built **oracle/weblogic:12.2.1-dev**. Now to build this sample, run:

        $ docker build -t 1221-domain .

To start the Admin Server, run:

        $ docker run -d --name wlsadmin --hostname wlsadmin -p 8001:8001 1221-domain

To start a Managed Server to self-register with the Admin Server above, run:

        $ docker run -d --link wlsadmin:wlsadmin -p 7001:7001 1221-domain createServer.sh

