#!/bin/sh
cp 12.2.2/* .
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

docker build $PROXY_SETTINGS -t oracle/tuxedoall .

echo "To run the Tuxedo + SALT + TSAM agent container, use:"
echo "docker run -ti -v \${LOCAL_DIR}:/u01/oracle/user_projects oracle/tuxedoall /bin/bash"
echo "Note: \${LOCAL_DIR} is a local dir which used in docker image as external storage, it can be any dir."
