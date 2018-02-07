Oracle WebCenter Sites: Automated Installation Scripts
===============================================

Automated Install Scripts can configure the WebLogic environment including RCU, Config Wizard and Sites Configuration steps.

For customization, modify scripts inside `wcs-wls-docker-install/src/main/groovy/com/oracle/wcsites/install/`

Remove running sites containers if already created. Eg: docker rm -f WCSitesAdminContainer WCSitesManagedContainer **Alert:** All previous data in Sites instance will be lost. 

Remove Oracle WebCenter Site Image if already created. Eg: docker rmi oracle/wcsites:12.2.1.3

Follow creating Oracle WebCenter Site Image refer section [Building Oracle WebCenter Sites Docker Images ](../../../README.md#5-building-oracle-webcenter-sites-docker-images-1)