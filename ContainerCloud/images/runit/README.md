# Runit Image

## Overview

This image is the basis for multiprocess images for custom stacks used in Container Cloud Service.

Upon choosing [`runit`](http://smarden.org/runit/index.html) as the init system for the image, the assumption is that runit will need to be started.
Other services will be configured in init scripts in `/etc/sv/<service-name>`.

## Building from this Image

```Dockerfile
FROM occs/runit:0.1
# Lot's of cool stuff here
```

*NOTE*: this assumes `occs` is the private registry name, or the name of your Docker Hub account.

## Developing Interactively with this Image

If you would like to build your own multi-process container from this image or play directly with `runit` run a detached container and connect to it.

```
docker run -d --name good_idea occs/runit:0.1
docker exec -it good_idea sh
```

A typical workflow might be to:

* install a process like HAProxy, NGINX, or Prometheus manually with the
  `apk` package manager
* get the init script correct for starting, stopping and reloading the process
* ensure that the logging is done properly (e.g. STDOUT and STDERR) so that `docker logs` is the single source of truth for process information
* ensure that when the process fails the container dies (i.e. avoids the "zombie container" problem)
* Write a Dockerfile from this research, build and test it
