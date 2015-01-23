#!/bin/sh
DOCKER_IMAGE_NAME="oracle/coherence:12.1.3"

SCRIPTS_DIR="$( cd "$( dirname "$0" )" && pwd )"

if [ "$1" = "" ] || [ "$1" = "-h" ]; then
  MAY_SHOW_USAGE="true"
fi

if [ "$DOCKING" != "false" ] && [ "$MAY_SHOW_USAGE" = "true" ]; then
  echo ""
  echo "Oracle Coherence 12c on Docker"
  echo "------------------------------"
  echo "Usage: $0 <full-path-cache-config-folder>"
  echo ""
  echo "You must point a folder containing 'tangosol-coherence-override.xml' and your Cache configuration files."
  echo "Example: # $0 $SCRIPTS_DIR/../example-grid"
  echo ""
  exit 0
fi
