IMAGES=apache-backend haproxy

# Include the common makefile which provides the following targets:
# stack (default):    runs images, publish, and generate-stack-yml targets
# images:             builds the dependent docker images
# publish:            pushes the built images to the registry
# generate-stack-yml: generates the stack.yml from the template
include ../../images/build/vars.mk
include ../build/common.mk
