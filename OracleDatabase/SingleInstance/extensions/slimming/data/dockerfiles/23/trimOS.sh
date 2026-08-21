#!/bin/sh
#
# $Header: rdbms/src/server/nanovos/container/podman/base/data/dockerfiles/trimOS.sh /main/1 2025/06/21 05:30:43 mamannam Exp $
#
# trimOS.sh
#
# Copyright (c) 2025, Oracle and/or its affiliates. 
#
#    NAME
#      trimOS.sh - Trim OS image files
#
#    DESCRIPTION
#      Script to remove non-essential files from Oracle Linux OS image
#
#    NOTES
#
#    MODIFIED   (MM/DD/YY)
#    mamannam    06/13/25 - Creation
#
removeFiles()
{
  local input_file="/root/os_trim.dat"

  while IFS= read -r line; do
    # Trim leading/trailing whitespace
    line="${line#"${line%%[![:space:]]*}"}"   # remove leading space
    line="${line%"${line##*[![:space:]]}"}"   # remove trailing space

    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^# ]] && continue

    rm -r "$line"
  done < "$input_file"
  rm "$input_file"
}

removeFiles
echo "OS IMAGE TRIM COMPLETE"
while true; do sleep 2; done
