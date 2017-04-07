Example of Image with WLS Domain
================================
This Dockerfile extends the Oracle WebLogic image built under 1221-domain with tag name '1221-domain'

WLST Offline script are used during Docker image build phase to deploy the 

- JDBC Data Source (Derby database information is picked up from the datasource.properties file)
- JMS artifacts (JMS Server, Queue etc). 

# How to build and run
First make sure you have built sample image inside **1221-domain**. Now to build this sample, run:

        $ docker build -t 1221-domain-with-resources .

To start the Admin Server with the application automatically deployed, run:

        $ docker run -d -p 7001:7001 1221-domain-with-resources

You should now be able to see the Data Source and the JMS components

When configured to do JMS Persistance the persistent store should be mapped to a volume on the host. Map the data volume in the container to a volume on the host to preserve the store in case the container fails, this allows for a new JMS Server recover messages. To map the data volumes use this docker run sample:

        $ docker run -d -v host-volume:/u01/oracle/user_projects/domains/base_domain/PersistentStore-directory -p 7001:7001 1221-domain-with-resources


# Copyright
Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
