WebCenter Sites: Automated Installation Scripts
===============================================

Database
========
Automated Install Scripts doesn't install the database software but can work with Oracle database.


Weblogic + Sites
================
Automated Install Scripts can configure the WebLogic environment including RCU, Config Wizard and Sites Configuration steps.

Modify scripts inside wcs-wls-docker-install/src/main/groovy/com/oracle/wcsites/install/
	
Then build the jar using wcs-wls-docker-install/pom.xml by running command "mvn install"

Also have dependency jars from pom.xml available in maven repository.
	
This will create jar in wcs-wls-docker-install/target/wcsites-wls-install.jar
	
Replace the modified jar file from wcs-wls-docker-install/target/wcs-wls-docker-install.jar to wcs-wls-docker-install/wcs-wls-docker-install.jar

For Pre-build-WebCenter Sites: Automated Installation Scripts
=============================================================
- Download WebCenter Sites: Automated Installation Scripts binary from [Oracle Technology Network](http://www.oracle.com/technetwork/middleware/webcenter/sites/downloads/index.html).

- Save the WebCenter Sites: Automated Installation Scripts binary at this location: `../docker-images/OracleWebCenterSites/dockerfiles/12.2.1.3/wcs-wls-docker-install/`.