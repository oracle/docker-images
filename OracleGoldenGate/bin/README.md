Oracle GoldenGate on Docker
===============
Additional utilities for managing the Oracle GoldenGate installation.

## Contents

* [oggServiceConfig](#oggserviceconfig)


## oggServiceConfig

### Summary
The `oggServiceConfig` utility will examine or change a configuration value for an Oracle GoldenGate service.

### Examples

**NOTE**: String values for `<json-value>` must be quoted using JSON notation.

```
oggServiceConfig http://localhost:11000 Local distsrvr \
                 --user oggadmin --password oggadmin-A1
```

   Display the configuration data for Distribution Server in the
   deployment called 'Local'.  The Service Manager administrative
   user name is 'oggadmin' and the password is 'password' for the
   Service Manager listening on port 11000.

```
oggServiceConfig http://localhost:11000 Local adminsrvr \
                 --user oggadmin --password oggadmin-A1 \
                 --path /authorizationDetails/common/allow \
                 --value '["Digest","x-Cert"]'
```

   Set the authentication modes used by Administration Server in the
   deployment called 'Local' to Basic and x-Cert and then restart
   the Administration Server.

   **NOTE**: Digest Authentication is available starting
         with Oracle GoldenGate version 19.1.

```
oggServiceConfig http://localhost:11000 Local adminsrvr \
                 --user oggadmin --password oggadmin-A1 \
                 --path /securityDetails/network/inbound/protocolVersion \
                 --value '"1_2"'
```

   Set the TLS version used by Administration Server in the
   deployment called 'Local' to TLS 1.2 and then restart the
   Administration Server.

```
oggServiceConfig http://localhost:11000 Local adminsrvr \
                 --user oggadmin --password oggadmin-A1 \
                 --path /securityDetails/network/inbound/cipherSuites \
                 --value '[ "TLS_RSA_WITH_AES_128_GCM_SHA256",
                            "TLS_RSA_WITH_AES_128_CBC_SHA256",
                            "TLS_RSA_WITH_AES_256_GCM_SHA384",
                            "TLS_RSA_WITH_AES_256_CBC_SHA256",
                            "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256" ]'
```

   Set the TLS ciphers used by Administration Server in the
   deployment called 'Local' to secure values and then restart the
   Administration Server.
