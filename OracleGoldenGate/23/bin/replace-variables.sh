#!/bin/bash
## Copyright (c) 2024, Oracle and/or its affiliates.
set -e

##
##  Replace environment variables with their values in one or more text files
##

perl -pi -e 'foreach $key(sort keys %ENV){ s/\$\{$key\}/$ENV{$key}/g}' "$@"
