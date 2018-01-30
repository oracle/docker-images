WebCenter Sites: Automated Installation Scripts
===============================================

Database
========
Automated Install Scripts doesn't install the database software but can work with Oracle database.


Weblogic
========
- Automated Install Scripts can configure the WebLogic environment including RCU, Config Wizard and Sites Configuration steps.

Modify scripts inside wcs-wls-docker-install/src/main/groovy/com/oracle/wcsites/install/
	
Then build the jar using wcs-wls-docker-install/pom.xml by running command "mvn install"
	
This will create jar in wcs-wls-docker-install/target/wcsites-wls-install.jar
	
Replace the modified jar file from wcs-wls-docker-install/target/wcs-wls-docker-install.jar to wcs-wls-docker-install/wcs-wls-docker-install.jar
