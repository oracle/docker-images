#!/bin/bash
## Copyright (c) 2021, Oracle and/or its affiliates.
set -e

##
##  r e p l a c e - v a r i a b l e s . s h
##  Replace environment variables with their values in one or more text files
##

perl -pi -e 'foreach $key(sort keys %ENV){ s/\$\{$key\}/$ENV{$key}/g}' "$@"
