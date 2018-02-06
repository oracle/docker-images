WebCenter Sites: Automated Installation Scripts
===============================================

Database
========
Automated Install Scripts doesn't install the database software but can work with Oracle database.


Weblogic & Sites
================
Automated Install Scripts can configure the WebLogic environment including RCU, Config Wizard and Sites Configuration steps.

For customization modify scripts inside `wcs-wls-docker-install/src/main/groovy/com/oracle/wcsites/install/`

Make sure you have maven installed before you start building jar.	

Build the jar using wcs-wls-docker-install/pom.xml by running command `mvn install`

This will create jar in `wcs-wls-docker-install/target/wcsites-wls-docker-install.jar`
	
Copy jar file from `wcs-wls-docker-install/target/wcs-wls-docker-install.jar` to `wcs-wls-docker-install/wcs-wls-docker-install.jar`

For Pre-build-WebCenter Sites: Automated Installation Scripts
=============================================================
1. Download WebCenter Sites: Automated Installation Scripts binary.

    For Existing Oracle Customers download binary from [https://support.oracle.com](https://support.oracle.com)

    a. Click **Sign In > Patches and Updates** and enter patch number as **27491932**, and then click **Search**.
    
    b. Click the patch link to download the patch.
    
    c. Extract `wcs-wls-docker-install.jar` from the downloaded zip.
2. Save the WebCenter Sites: Automated Installation Scripts binary `wcs-wls-docker-install.jar` at this location: `../docker-images/OracleWebCenterSites/dockerfiles/12.2.1.3/wcs-wls-docker-install/`.