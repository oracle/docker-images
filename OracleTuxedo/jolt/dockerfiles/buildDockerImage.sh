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

docker build $PROXY_SETTINGS -t oracle/tuxedojolt .

echo "To run the Tuxedo jolt sample container, use:"
echo "docker run -d -h jolthost -p 11304:1304 -v \${LOCAL_DIR}:/u01/oracle/user_projects --name tuxedojolt oracle/tuxedojolt"
echo "Note: \${LOCAL_DIR} is a local dir which used in docker image as external storage, it can be any dir."
