# Oracle Cloud Infrastructure Command Line Interface Container Image

The Oracle Cloud Infrastructure (OCI) Command Line Interface (CLI) is a small-footprint tool that you can use on its own or with the Oracle Cloud Console to complete tasks. The OCI CLI provides the same core functionality as the console, plus additional commands. Some of these, such as the ability to run scripts, extend console functionality.

## Using the OCI CLI container image

To use the OCI CLI container image, you must have:

* a standards-compliant container runtime engine, e.g. [Docker][6], [Podman][7] or similar
* an Oracle Cloud Infrastructure tenancy
* a user account in that tenancy that belongs to a group to which appropriate policies have been assigned to grant the required permissions.
* A keypair used for signing API requests, with the public key uploaded to Oracle. Only the user calling the API should possess the private key. See [Configuring the CLI][3].

For examples of how to set up a new user, group, compartment, and policy, see the [documentation on adding users][1]. For a list of other typical OCI policies, review the [list of common policies][2].

> Oracle recommends creating and using dedicated service accounts instead of personal user accounts for accessing the OCI API.

To use the container image, pull the latest version from the GitHub Container Registry:

```bash
$ docker pull ghcr.io/oracle/oci-cli:latest
$ docker images
REPOSITORY                              TAG               IMAGE ID       CREATED        SIZE
ghcr.io/oracle/oci-cli                  latest            387639e80a9a   3 days ago     711MB
```

Consider tagging the image as `oci` to make it a more seamless drop-in replacement:

```bash
$ docker tag ghcr.io/oracle/oci-cli:latest oci
$ docker images oci
REPOSITORY   TAG       IMAGE ID       CREATED      SIZE
oci          latest    387639e80a9a   3 days ago   711MB
$ docker run -v "$HOME/.oci:/oracle/.oci" oci os ns get
{
  "data": "demo-tenancy"
}
```

To make it even easier, create an shell alias that runs the container for you:

```bash
$ alias oci='docker run --rm -it -v "$HOME/.oci:/oracle/.oci" oci'
$ oci os ns get
{
  "data": "demo-tenancy"
}
```

## API signing key authentication

This is the default authentication method used by all OCI SDKs and the OCI CLI. To use this method, mount a location on the host system to the `/oracle/.oci` directory inside the container.

If you have previously configured the OCI CLI on the host machine, the easiest way to provide access to your API signing key is map your `$HOME/.oci` directory to `/oracle/.oci/` inside the container:

```bash
$ docker run --rm -it \
  -v "$HOME/.oci:/oracle/.oci" \
  ghcr.io/oracle/oci-cli os ns get
{
  "data": "example"
}
```

Alternatively, you could pass the `OCI_CLI_CONFIG_FILE` environment variable to use a different location for the OCI CLI `config` file.

> Note: ensure that the `key_file` field in `$HOME/.oci/config` uses the `~` character so that the path resolves both inside and outside the container, e.g. `key_file=~/.oci/oci_api_key.pem`. Alternatively, pass the `OCI_CLI_KEY_FILE` environment variable to the container at runtime to specify a different location for the private key.

 If you haven't previously configured the OCI CLI, create `$HOME/.oci`:

 ```bash
mkdir $HOME/.oci
```

 Then start the OCI CLI's interactive setup process:

```bash
docker run --rm -it \
  -v "$HOME/.oci:/oracle/.oci" \
  ghcr.io/oracle/oci-cli setup config
```

## Session token authentication

To use token-based authentication, map port 8181 to the container:

```bash
docker run --rm -it \
  -v "$HOME/.oci:/oracle/.oci" \
  -p 8181:8181 \
  ghcr.io/oracle/oci-cli session authenticate
```

## Instance principal authentication

To enable instance prinicipal authentication, you can use either the `--auth instance_principal` command-line parameter:

```bash
docker run --rm -it ghcr.io/oracle/oci-cli --auth instance_principal os ns get
```

Or pass the `OCI_CLI_AUTH` environment variable:

```bash
docker run --rm -it -e OCI_CLI_AUTH=instance_principal ghcr.io/oracle/oci-cli os ns get
```

If you created a shell alias, add it to the alias definition.

## Local file access

The simplest way to allow the OCI CLI running inside the container to access files on the host is to bind mount a directory from the host into the container.

In the following example, the `$HOME/scratch` directory is bind mounted as `/oracle/scratch` in the container so that the files inside that directory can be bulk uploaded to OCI Object Storage using the OCI CLI:

```bash
docker run --rm -it \
  -v "$HOME/.oci:/oracle/.oci" \
  -v "$HOME/scratch:/oracle/scratch" \
  ghcr.io/oracle/oci-cli os object bulk-upload -ns <namespace> -bn <bucket name> --src-dir /oracle/scratch/
```

## Building the image locally

To build the image, clone this repository, change to the `OracleCloudInfrastructure/oci-cli` directory and then run:

```bash
docker build --tag oci .
```

## License

This container image is licensed under the Universal Permissive License 1.0. The OCI CLI and samples are dual-licensed under the Universal Permissive License 1.0 and the Apache License 2.0. Third-party dependencies of the OCI CLI are separately licensed as described in the [OCI CLI repository][5].

[1]: https://docs.oracle.com/en-us/iaas/Content/GSG/Tasks/addingusers.htm#Adding_Users
[2]: https://docs.oracle.com/en-us/iaas/Content/Identity/Concepts/commonpolicies.htm#top
[3]: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#Required_Keys_and_OCIDs
[4]: https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/clitoken.htm#Tokenbased_Authentication_for_the_CLI
[5]: https://github.com/oracle/oci-cli
[6]: https://www.docker.com/
[7]: https://podman.io/
