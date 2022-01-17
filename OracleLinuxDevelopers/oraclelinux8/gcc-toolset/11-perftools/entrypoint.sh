#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

if [ "$1" = "interactive-shell" ]; then
    scl enable gcc-toolset-11 -- bash
else
    scl enable gcc-toolset-11 -- env -- "$@"
fi
