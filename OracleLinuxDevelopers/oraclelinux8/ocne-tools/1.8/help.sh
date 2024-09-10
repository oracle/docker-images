#!/bin/bash

echo "OCNE/OKE Tools"

echo "oci-cli version: $(oci --version)"
helm version --template='helm version: {{.Version}}'
echo ''
echo "kubectl versions: "
kubectl version --client