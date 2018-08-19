#!/bin/sh
#
# Cleanup docker files: untagged containers and images.
#
# Use `docker-cleanup -n` for a dry run to see what would be deleted.
#
# Copyright (c) 2014-2018 Oracle and/or its affiliates. All rights reserved.

untagged_containers() {
  # Print containers using untagged images: $1 is used with awk's print: 0=line, 1=column 1.
  docker ps -a | awk '$2 ~ "[0-9a-f]{12}" {print $'$1'}'
}

untagged_images() {
  # Print untagged images: $1 is used with awk's print: 0=line, 3=column 3.
  # NOTE: intermediate images (via -a) seem to only cause
  # "Error: Conflict, foobarid wasn't deleted" messages.
  # Might be useful sometimes when Docker messed things up?!
  # docker images -a | awk '$1 == "<none>" {print $'$1'}'
  docker images | tail -n +2 | awk '$1 == "<none>" {print $'$1'}'
}

# Dry-run.
if [ "$1" = "-n" ]; then
  echo "=== Containers with uncommitted images: ==="
  untagged_containers 0
  echo

  echo "=== Uncommitted images: ==="
  untagged_images 0

  exit
fi

# Remove containers with untagged images.
echo "Removing containers:" >&2
untagged_containers 1 | xargs --no-run-if-empty docker rm --volumes=true

# Remove untagged images
echo "Removing images:" >&2
untagged_images 3 | xargs --no-run-if-empty docker rmi
