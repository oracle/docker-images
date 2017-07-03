#!/bin/sh

# Proxy settings
PROXY_SETTINGS=""
if [ "${http_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg http_proxy=${http_proxy}"
fi

if [ "${https_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg https_proxy=${https_proxy}"
fi

if [ "${ftp_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg ftp_proxy=${ftp_proxy}"
fi

if [ "${no_proxy}" != "" ]; then
  PROXY_SETTINGS="$PROXY_SETTINGS --build-arg no_proxy=${no_proxy}"
fi

if [ "$PROXY_SETTINGS" != "" ]; then
  echo "Proxy settings were found and will be used during build."
fi

docker build $PROXY_SETTINGS -t oracle/tuxedotmasample:12.2.2 .

echo "To run the sample, use:"
echo "docker run -ti -v \${LOCAL_DIR}:/u01/oracle/user_projects oracle/tuxedotmasample:12.2.2 tmasna_runme.sh"
echo "or"
echo "docker run -ti -v \${LOCAL_DIR}:/u01/oracle/user_projects oracle/tuxedotmasample:12.2.2 tmatcp_runme.sh"
