#!/bin/sh

usage() {
cat << EOF

Usage: buildDockerImage.sh -p tuxedo_rp
Builds a Docker Image for Oracle Tuxedo TMA.

Parameters:
   -p: Tuxedo RP003 or higher installer is required.
LICENSE CDDL 1.0 + GPL 2.0

Copyright (c) 2016-2017 Oracle and/or its affiliates. All rights reserved.

EOF
exit 0
}

TUXRP=
while getopts "h:p:" optname; do
  case "$optname" in
    "h")
      usage
      ;;
    "p")
     TUXRP="$OPTARG"
      ;;
    *)
    # Should not occur
      echo "Unknown error while processing options inside buildDockerImage.sh"
      ;;
  esac
done

if [ -z "$TUXRP" ]; then   # -p option is a MUST
    echo "You must specify tuxedo rp installer with -p option"
    exit
fi

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

# Fix up the locations of things
cp 12.2.2/* .

docker build $PROXY_SETTINGS --build-arg tuxedo_rp=$TUXRP -t oracle/tuxedoartrttma:12.2.2 .
rm -f *.rsp Dockerfile install_*.sh
