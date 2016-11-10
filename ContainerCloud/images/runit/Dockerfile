FROM alpine:3.4

RUN apk upgrade && \
    apk update && \
    apk add runit \
      --update-cache \
      --repository http://dl-3.alpinelinux.org/alpine/edge/community/ \
      --allow-untrusted

# Lay out the directory structure for how runit expects to find it's file
# and configuration.
RUN mkdir -pv /etc/sv && \
    mkdir -pv /etc/service && \
    ln -sv /etc/service /service

# If you are using this base image then you want runit to start.  The rest
# is in configuration.
ENTRYPOINT ["/sbin/runsvdir", "/service"]
