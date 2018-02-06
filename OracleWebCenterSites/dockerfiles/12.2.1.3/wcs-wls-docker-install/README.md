WebCenter Sites: Automated Installation Scripts
===============================================

Automated Install Scripts can configure the WebLogic environment including RCU, Config Wizard and Sites Configuration steps.

For customization, modify scripts inside `wcs-wls-docker-install/src/main/groovy/com/oracle/wcsites/install/`

To access external registries, set up environment variables for proxy server as below:
```
   export http_proxy=http://www-yourcompany.com:80 
   export https_proxy=http://www-yourcompany.com:80 
   export HTTP_PROXY=http://www-yourcompany.com:80 
   export HTTPS_PROXY=http://www-yourcompany.com:80 
   export NO_PROXY=localhost,.yourcompany.com 
```

Run `packagejar.sh` file which will generate required `wcs-wls-docker-install.jar`

If `packagejar.sh` is taking long time to execute please make sure proxies are set correctley.