#!/bin/sh
DISTRIBUTION="weblogic12c-generic"

if [ -z "$IMAGE_NAME" ]; then
	IMAGE_NAME="oracle/weblogic:12.1.3"
fi

TIMESTAMP=`date +%s`
NM_CONTAINER_NAME="nodemanager${TIMESTAMP}"
ADMIN_CONTAINER_NAME="wlsadmin"
ATTACH_ADMIN_TO=7001

# JAVA PACKAGE CHECK
JAVA_VERSION="8u25"
JAVA_PKG="jdk-${JAVA_VERSION}-linux-x64.rpm"
JAVA_PKG_MD5="6a8897b5d92e5850ef3458aa89a5e9d7"

# WEBLOGIC 12.1.3 GENERIC
WLS_PKG="fmw_12.1.3.0.0_wls.jar"
WLS_PKG_MD5="8378fe936b476a6f4ca5efa465a435e3"
 
setup_developer() {
	IMAGE_NAME="oracle/weblogic:12.1.3-dev"
	echo "Configuration for developer distribution enabled."
        DISTRIBUTION="weblogic12c-developer"
        WLS_PKG="wls1213_dev.zip"
        WLS_PKG_MD5="0a9152e312997a630ac122ba45581a18"
}

#
# Function to check MD5 of $1 against expected value $2
#
check_md5() {
  MD5="MD5 ($1) = $2"
  if [[ "`uname`" == 'Darwin' ]]; then
    MD5_CHECK=`md5 "$1"`
  else 
    MD5_CHECK="$(md5sum --tag $1)"
  fi
    
  if [[ "$MD5" == "$MD5_CHECK" ]]; then 
    return 0 
  else
    return 1
  fi
}


