# Oracle Linux developer images

These are developer-oriented images designed to be used as the base image and
extended to include application code.

Each of the language and version variants are based off either the
`oraclelinux:7-slim` or `oraclelinux:8` base images with as minimal a
package set as possible. If your application requires additional modules or
packages, they should be installed as part of your downstream `Dockerfile`.

## Usage of the binary images

All the [published Oracle Linux Developer images][1] use publicly available
packages from the [Oracle Linux yum server][2]. No login, Oracle SSO account or
permission is required to build, extend, use or distribute these images.

## Oracle Database support

The `-oracledb` variants include the language-specific driver for connecting to
Oracle Database along with the appropriate Oracle Instant Client packages.

## Oracle Linux 7 based images

### Go

* [`oraclelinux7-golang:1.16`](oraclelinux7/golang/1.16/Dockerfile)
* [`oraclelinux7-golang:1.17`](oraclelinux7/golang/1.17/Dockerfile)

### Node.js

* [`oraclelinux7-nodejs:12`](oraclelinux7/nodejs/12/Dockerfile)
* [`oraclelinux7-nodejs:12-oracledb`](oraclelinux7/nodejs/12-oracledb/Dockerfile)
* [`oraclelinux7-nodejs:14`](oraclelinux7/nodejs/14/Dockerfile)
* [`oraclelinux7-nodejs:14-oracledb`](oraclelinux7/nodejs/14-oracledb/Dockerfile)

### PHP

* [`oraclelinux7-php:7.4-apache`](oraclelinux7/php/7.4-apache/Dockerfile)
* [`oraclelinux7-php:7.4-apache-oracledb`](oraclelinux7/php/7.4-apache-oracledb/Dockerfile)
* [`oraclelinux7-php:7.4-cli`](oraclelinux7/php/7.4-cli/Dockerfile)
* [`oraclelinux7-php:7.4-cli-oracledb`](oraclelinux7/php/7.4-cli-oracledb/Dockerfile)
* [`oraclelinux7-php:7.4-fpm`](oraclelinux7/php/7.4-fpm/Dockerfile)
* [`oraclelinux7-php:7.4-fpm-oracledb`](oraclelinux7/php/7.4-fpm-oracledb/Dockerfile)

### Python

* [`oraclelinux7-python:3.6`](oraclelinux7/python/3.6/Dockerfile)
* [`oraclelinux7-python:3.6-oracledb`](oraclelinux7/python/3.6-oracledb/Dockerfile)

### Ruby

To install Ruby on Rails, extend one of the images tagged `-nodejs` and add the
following directive to your `Dockerfile`:

```dockerfile
RUN npm install -g yarn && \
    gem install rails
```

You should then be able to create a new Ruby on Rails application.

* [`oraclelinux7-ruby:2.6`](oraclelinux7/ruby/2.6/Dockerfile)
* [`oraclelinux7-ruby:2.7`](oraclelinux7/ruby/2.7/Dockerfile)
* [`oraclelinux7-ruby:2.7-nodejs`](oraclelinux7/ruby/2.7-nodejs/Dockerfile)
* [`oraclelinux7-ruby:3.0`](oraclelinux7/ruby/3.0/Dockerfile)
* [`oraclelinux7-ruby:3.0-nodejs`](oraclelinux7/ruby/3.0-nodejs/Dockerfile)

## Oracle Linux 8 based images

### Go Toolset module

* [`oraclelinux8-golang:ol8`](oraclelinux8/golang/ol8/Dockerfile)

### NGINX module

* [`oraclelinux8-nginx:1.14`](oraclelinux8/nginx/1.14/Dockerfile)
* [`oraclelinux8-nginx:1.16`](oraclelinux8/nginx/1.16/Dockerfile)
* [`oraclelinux8-nginx:1.18`](oraclelinux8/nginx/1.18/Dockerfile)
* [`oraclelinux8-nginx:1.20`](oraclelinux8/nginx/1.20/Dockerfile)

### Node.js module

* [`oraclelinux8-nodejs:12`](oraclelinux8/nodejs/12/Dockerfile)
* [`oraclelinux8-nodejs:14`](oraclelinux8/nodejs/14/Dockerfile)
* [`oraclelinux8-nodejs:14-oracledb`](oraclelinux8/nodejs/14-oracledb/Dockerfile)
* [`oraclelinux8-nodejs:16`](oraclelinux8/nodejs/16/Dockerfile)

### PHP module

* [`oraclelinux8-php:7.3-apache`](oraclelinux8/php/7.3-apache/Dockerfile)
* [`oraclelinux8-php:7.3-cli`](oraclelinux8/php/7.3-cli/Dockerfile)
* [`oraclelinux8-php:7.3-fpm`](oraclelinux8/php/7.3-fpm/Dockerfile)
* [`oraclelinux8-php:7.4-apache`](oraclelinux8/php/7.4-apache/Dockerfile)
* [`oraclelinux8-php:7.4-apache-oracledb`](oraclelinux8/php/7.4-apache-oracledb/Dockerfile)
* [`oraclelinux8-php:7.4-cli`](oraclelinux8/php/7.4-cli/Dockerfile)
* [`oraclelinux8-php:7.4-cli-oracledb`](oraclelinux8/php/7.4-cli-oracledb/Dockerfile)
* [`oraclelinux8-php:7.4-fpm`](oraclelinux8/php/7.4-fpm/Dockerfile)
* [`oraclelinux8-php:7.4-fpm-oracledb`](oraclelinux8/php/7.4-fpm-oracledb/Dockerfile)

### Python modules

> **Note**: Each version of Python is provided as a module for Oracle
> Linux 8 as opposed to other languages which are provided as a single module
> with multiple AppStreams.

* [`oraclelinux8-python:3.6`](oraclelinux8/python/3.6/Dockerfile)
* [`oraclelinux8-python:3.6-oracledb`](oraclelinux8/python/3.6-oracledb/Dockerfile)
* [`oraclelinux8-python:3.8`](oraclelinux8/python/3.8/Dockerfile)
* [`oraclelinux8-python:3.9`](oraclelinux8/python/3.9/Dockerfile)

### Ruby module

To install Ruby on Rails, extend one of the images tagged `-nodejs` and add the
following directive to your `Dockerfile`:

```dockerfile
RUN npm install -g yarn && \
    gem install rails
```

You should then be able to create a new Ruby on Rails application.

* [`oraclelinux8-ruby:2.6`](oraclelinux8/ruby/2.6/Dockerfile)
* [`oraclelinux8-ruby:2.7`](oraclelinux8/ruby/2.7/Dockerfile)
* [`oraclelinux8-ruby:2.7-nodejs`](oraclelinux8/ruby/2.7-nodejs/Dockerfile)
* [`oraclelinux8-ruby:3.0`](oraclelinux8/ruby/3.0/Dockerfile)

[1]: https://github.com/orgs/oracle/packages?repo_name=docker-images
[2]: https://yum.oracle.com
