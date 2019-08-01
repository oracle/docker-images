#!/usr/bin/env bash
#
# LICENSE UPL 1.0
#
# Copyright (c) 2015 Oracle and/or its affiliates. All rights reserved.
#

$JAVA_HOME/bin/gu "${@}"
RT=$?
if [ $RT -ne 0 ]; then
  exit $RT
fi

# Only run on *install operations
if [[ "$@" == *"install"* ]]; then

  # Add new links for newly installed components
  for bin in "$JAVA_HOME/bin/"*; do
    base="$(basename "$bin")";
    if [[ ! -e "/usr/bin/$base" ]]; then
      alternatives --install "/usr/bin/$base" "$base" "$bin" 20000;
    fi
  done;

  # Remove dead links from uninstalled components
  find /usr/bin -xtype l -delete

  echo "Refreshed alternative links in /usr/bin/"
fi

