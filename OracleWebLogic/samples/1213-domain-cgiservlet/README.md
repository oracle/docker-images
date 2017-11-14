Oracle WebLogic with CGIServlet
================================
This Dockerfile extends the Oracle WebLogic image **oracle/weblogic:12.1.3-developer**. It creates a domain based on the **$MW_HOME/wl_server/common/templates/wls/wls.jar**, instantiates a [CGIServlet application](https://docs.oracle.com/middleware/1213/wls/WBAPP/configureresources.htm#WBAPP223) and deploy it in the **AdminServer**. The purpose of this image is to help devops engineers to debug their CGIServlet installations on WebLogic.

The [Dockerfile](Dockerfile) installs the domain and creates the **CGI_APP_HOME** creating a **.war** that declares a **CGIServlet** on its [web.xml](web.xml) deployment descriptor. The .war file is [autodeploy](https://docs.oracle.com/middleware/1213/wls/DEPGD/autodeploy.htm#DEPGD254) in the WLS AdminServer.  

# How to build and run

## Build
Just run the build command with the below **--build-arg** parameters:

      $ docker build -t 1213-domain --build-arg ADMIN_PASSWORD=welcome1 --build-arg CGI_DIR_VALUE=/u01/oracle/cgi-scripts build-arg CGI_EXTENSION_MAPPING=*.sh --build-arg CGI_INTERPRETER=/bin/sh --build-arg CGI_APP_NAME=cgi-app --build-arg CGI_SERVLET_URL_PATTERN=/cgi-bin/* .

- CGI_DIR_VALUE: directory of your cgi scripts
- CGI_EXTENSION_MAPPING: extension of your scripts
- CGI_INTERPRETER: script interpreter
- CGI_APP_NAME: defines the context of the web application (url path)
- CGI_SERVLET_URL_PATTERN: url pattern of the CGIServlet class  

## Run
Simply

      $ docker run --name wls_cgi -p 7001:7001 1213-domain-cgiservlet

#Test your installation

Request

      http://localhost:7001/cgi-app/cgi-bin/test.sh?p1=v1&p2=v2&p3=v3

# Copyright
Copyright (c) 2017 CERN
