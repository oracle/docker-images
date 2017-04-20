#!/bin/powershell
#
# Cleanup docker files: untagged containers and images.
#
# Use `docker-cleanup -n` for a dry run to see what would be deleted.
#
# Copyright (c) 2017 Francisco Javier Horrillo Sancho. All rights reserved.

function untagged_containers($1) {
  # Print containers using untagged images: $1 is used with awk's print: 0=line, 1=column 1.
  if ($1 -eq 0) { docker ps -a } else { docker ps -a -q }
}

function untagged_images($1) {
  # Print untagged images: $1 is used with awk's print: 0=line, 3=column 3.
  # NOTE: intermediate images (via -a) seem to only cause
  # "Error: Conflict, foobarid wasn't deleted" messages.
  # Might be useful sometimes when Docker messed things up?!
  if ($1 -eq 0) { docker images } else { docker images -q }
}

# Dry-run.
if ( $args[0] -eq "-n" ) {
  echo "=== Containers with uncommitted images: ==="
  untagged_containers 0
  echo ""

  echo "=== Uncommitted images: ==="
  untagged_images 0

  exit
}

# Remove containers with untagged images.
echo "Removing containers:"
docker rm --volumes=true $(untagged_containers 1)

# Remove untagged images
echo "Removing images:"
docker rmi $(untagged_images 3)
