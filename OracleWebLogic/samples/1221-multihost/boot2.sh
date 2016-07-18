#!/bin/sh
# Create overlay Docker Multihost Network and set Docker environment pointing to Machine
. ./setenv.sh

# Save existing defined image to a file to be loaded later into the registry created above
eval "$(docker-machine env -u)"
docker save $image > _tmp_docker.img
echo "image saved to tmp_docker.img"

# Load, tag, and publish the image set in setenv.sh
eval "$(docker-machine env $orchestrator)"
docker load -i _tmp_docker.img && rm _tmp_docker.img
docker tag $image 127.0.0.1:5000/$image
docker push 127.0.0.1:5000/$image
echo "image hed to repository"


# Call post-bootstrap.sh if present and executable
if [ -x ./post-bootstrap.sh ]; then
  . ./post-bootstrap.sh
fi

