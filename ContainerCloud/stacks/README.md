# Stacks

# What is a Stack?

A stack is composed of one or more Docker images. It is defined using a YML file, much like a Docker Compose file, which lists the services, environment variables, and other configuration required to function properly.

See "Getting Started" in the top-level [../README.md] for how to build all the stacks at once or build an individual stack.

## Additional Details About How a Stack is Built

Make is a tool used to build and generate executables from source files. See https://www.gnu.org/software/make/ for more information about make.

Running `make` with the default rule in a particular stack directory, e.g. `haproxy-lb-to-nginx`, is equivalent to running `make stack` (and that is equivalent to `make images generate-stack-yml`) on the command line. The following things happen as part of this build:

* The Docker image is created
* The Docker image is pushed to a registry (you must first do a `docker login` to login to Docker Hub)
* The name and version of the Docker image are inserted into the template for the stack's YML and stored as `stack.yml` in the stack's directory

The registry, name, and version tag are controlled with variables in specific makefiles.

* `images/build/vars.mk` - defines the version tag for each image and the registry name to push the image to
* `images/IMAGE_NAME/Makefile` - defines the name of the image
* `stacks/STACK_NAME/Makefile` - defines the dependent images for the stack
