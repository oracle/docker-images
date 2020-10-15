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

docker build $PROXY_SETTINGS -t oracle/tuxedoperfpack .

echo "To run the Tuxedo performance pack sample container, use:"
echo "docker run -d -h tuxhost -v \${LOCAL_DIR}:/u01/oracle/user_projects oracle/tuxedoperfpack"
echo "Note: \${LOCAL_DIR} is a local dir which used in docker image as external storage, it can be any dir."
echo ""
cat <<EOF
All of the features in Tuxedo Advanced Performance Pack are enabled
if the OPTIONS parameter in RESOURES in UBBCONFIG is set to XPP.
    OPTIONS             XPP
And each of these features can be individually disabled if needed:
    OPTIONS        NO_AA,XPP,NO_RDONLY1PC,NO_SHMQ
    RMOPTIONS      NO_XAAFFINITY,SINGLETON,NO_FAN,NO_COMMONXID

EOF

