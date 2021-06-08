# Oracle Linux developer images

These are developer-oriented images designed to be used as the base image and
extended to include application code.

Each of the language and version variants are based off either the
`oraclelinux:7-slim` or `oraclelinux:8-slim` base images with as minimal a
package set as possible. If your application requires additional modules or
packages, they should be installed as part of your downstream `Dockerfile`.

All images use the available language packages from the
[Oracle Linux yum server](https://yum.oracle.com). There are no external
dependencies.

The `-oracledb` variants include the language-specific driver for connecting to
and Oracle Database along with the appropriate Oracle Instant Client packages.

## Oracle Linux 7 based images

### Go

* [`oraclelinux7-golang:1.15`](oraclelinux7/golang/1.16/Dockerfile)
* [`oraclelinux7-golang:1.16`](oraclelinux7/golang/1.15/Dockerfile)

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

## Oracle Linux 8 based images

### Go

* [`oraclelinux8-golang:latest`](oraclelinux8/golang/latest/Dockerfile)

### Node.js

* [`oraclelinux8-nodejs:12`](oraclelinux8/nodejs/12/Dockerfile)
* [`oraclelinux8-nodejs:14`](oraclelinux8/nodejs/14/Dockerfile)
* [`oraclelinux8-nodejs:14-oracledb`](oraclelinux8/nodejs/14-oracledb/Dockerfile)

### PHP

* [`oraclelinux8-php:7.3-apache`](oraclelinux8/php/7.3-apache/Dockerfile)
* [`oraclelinux8-php:7.3-cli`](oraclelinux8/php/7.3-cli/Dockerfile)
* [`oraclelinux8-php:7.3-fpm`](oraclelinux8/php/7.3-fpm/Dockerfile)
* [`oraclelinux8-php:7.4-apache`](oraclelinux8/php/7.4-apache/Dockerfile)
* [`oraclelinux8-php:7.4-cli`](oraclelinux8/php/7.4-cli/Dockerfile)
* [`oraclelinux8-php:7.4-fpm`](oraclelinux8/php/7.4-fpm/Dockerfile)


### Python

* [`oraclelinux8-python:3.6`](oraclelinux8/python/3.6/Dockerfile)
* [`oraclelinux8-python:3.6-oracledb`](oraclelinux8/python/3.6-oracledb/Dockerfile)
* [`oraclelinux8-python:3.8`](oraclelinux8/python/3.8/Dockerfile)

### Ruby

* [`oraclelinux8-ruby:2.6`](oraclelinux8/ruby/2.6/Dockerfile)
* [`oraclelinux8-ruby:2.7`](oraclelinux8/ruby/2.7/Dockerfile)
