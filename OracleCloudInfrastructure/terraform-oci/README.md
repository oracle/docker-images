# Containerized Terraform for OCI provider

Terraform is a powerful tool for building, changing, and versioning
infrastructure safely and efficiently. It gives you agility and fine-grained
control over all your infrastructure resources, you can create configuration
files to describe your resources in a human-readable format. Terraform can
manage existing and popular service providers as well as custom in-house
solutions.

Oracle provides an open source Terraform provider for Oracle Cloud
Infrastructure which you can use to manage all your Cloud infrastructure
resources (Network, Compute, Storage, etc).

## Building the image

This image has no external dependencies. It can be built using the standard
`docker build` command, as follows:

```
# docker build -t oracle/terraform-oci:2.0.6 .
```


## Running terraform

Create a directory to store your Terraform configuration files and specify that
directory as the source of the `VOLUME` when starting the container:

```
docker run \
  --interactive --tty --rm \
  --volume "$PWD":/data \
  oracle/terraform-oci:2.0.6 "$@"
```

Now you can work with Terraform the same way you are familiar with:

```
sh-4.2# terraform init

Initializing provider plugins…

The following providers do not have any version constraints in configuration,
so the latest version was installed.

To prevent automatic upgrades to new major versions that may contain breaking
changes, it is recommended to add version = “…” constraints to the
corresponding provider blocks in configuration, with the constraint strings
suggested below.

* provider.oci: version = “~> 2.0”

Terraform has been successfully initialized!
```
## Create an alias for terraform

To simplify working with Terraform inside a container, create an alias
(or a shell script) so that you can access Terraform as if it were running
locally on your machine:

```
$ alias terraform-oci="docker run \
   --interactive --tty --rm \
   --volume "$PWD":/data \
   oracle/terraform-oci:2.0.6 terraform"
```


Inspired by https://medium.com/oracledevs/containerized-terraform-for-oci-provider-2deb917783fa
