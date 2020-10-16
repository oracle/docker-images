
# Confd Image

## Overview

This container builds on the `runit` image and  includes a demonstrable
"hello world" for the use of `confd` and Container Cloud Service.

## Usage

The following environment variables are required to run this image:

* `KV_IP` - the IP address which provides the key/value endpoint, when using this image with a stack the docker0 IP address can be used, e.g. 172.17.0.1
* `KV_PORT` - the port on which the key/value endpoint is listening, when using this image with a stack, `9109` should be used
* `OCCS_API_TOKEN` - the token used to authenticate with the key/value store endpoint

## Example

Confd is configured in `/etc/confd/conf.d`. Add a template resource by creating a file with the `.toml` extension. For example, create the `hello-world.toml` (below) and add it to the image in `/etc/confd/conf.d/hello-world.toml`:

```
[template]
src = "hello-world.conf.template"
dest = "/hello-world.conf"

# The key below must be changed to match how you named your
# service in Container Cloud Service.
keys = [
"apps/hello-world/containers"
]
```

Create the template file, `hello-world.conf.template` and place the file in `/etc/confd/templates/hello-world.conf.template`.

```
database:
  cluster:
    targets:
        [ {{$service := "/apps/hello-world/containers/*"}}
        {{range gets (print $service)}}
        '{{.Value}}',{{end}}
        ]
```

When confd runs, it will watch for changes in the key/value store for keys matching the `apps/hello-world/containers/*` pattern. When changes are found, the template will be updated and written to `/hello-world.conf` (defined in the template resource).

Add the following keys to the key/value store:

```
apps/hello-world/containers/one=10.9.1.2:32270
apps/hello-world/containers/two=10.9.1.2:32271
```

Confd will recognize the new keys, update `/hello-world.conf`, and the generated file will look like:

```
database:
  cluster:
    targets:
        [
        gratuitous text = <no value>

        '10.9.1.2:32770',
        '10.9.1.2:32771',
        ]
```

To view that file, connect to the container:

```
# assuming your container is named foo
docker exec -it foo /bin/sh
```

Now, inspect the configuration inside the container:

```
cat /hello-world.conf
```

## Resources

To learn more about confd template resources, see https://github.com/kelseyhightower/confd/blob/master/docs/template-resources.md.
