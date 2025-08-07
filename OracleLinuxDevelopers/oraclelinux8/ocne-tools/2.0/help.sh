#!/bin/bash
# Copyright (c) 2025 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

echo "OCNE/OKE Tools"

echo "oci-cli version: $(oci --version)"
helm version --template='helm version: {{.Version}}'
echo ''
echo "kubectl versions: "
kubectl version --client