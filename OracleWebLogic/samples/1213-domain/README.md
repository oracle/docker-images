Example of Image with WLS Domain
================================

You can build this image with a simple '$ docker build -t mywlsimage .' command.

To run a single host cluster, you can use these two commands:

1. Create the AdminServer

        # docker run --name wlsadmin -d mywlsimage startWebLogic.sh

2. Create a containerized Machine with a Managed Server

        # docker run --link wlsadmin:wlsadmin -d mywlsimage createServer.sh

3. Call commnad on (2) multiple times for more servers

4. Access the WebLogic Admin Console on the AdminServer container (port 8001) and create a cluster
