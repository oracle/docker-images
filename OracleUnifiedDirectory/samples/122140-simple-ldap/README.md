# Simple OUD LDAP

Setup a simple OUD LDAP Directory Server using OUD 12.2.1.4.0.

## Create and Run the Container

Create the container using `docker-compose`

```bash
docker-compose up -d
```

The OUD container will create a default instance on first start. Persistent data will be create on a volume. By default this is in the current location. You can specify an alternative directory by setting environment variable *DOCKER_VOLUME_BASE* or change the volume path in the compose file.

## Customize the Container

The `docker-compose.yml` does set a couple of environment variable to change the behavior of the OUD container and setup of the OUD instance.

| Variable      | Value               | Description                                            |
|---------------|---------------------|--------------------------------------------------------|
| INSTANCE_INIT | `/u01/config`       | Path to the OUD instance init scripts                  |
| OUD_INSTANCE  | *oud_docker*        | Name of the OUD instance.                              |
| SAMPLE_DATA   | *TRUE*              | Flag load sample data after creating the OUD instance. |
| BASEDN        | *dc=example,dc=com* | Base DN used to setup the directory server             |
