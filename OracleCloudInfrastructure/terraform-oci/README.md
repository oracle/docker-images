# Containerized Terraform for OCI provider

[Terraform](https://www.terraform.io/) is a powerful tool for building, changing, and versioning infrastructure safely and efficiently. It gives you agility and fine-grained control over all your infrastructure resources, you can create configuration files to describe your resources in a human-readable format. Terraform can manage existing and popular service providers as well as custom in-house solutions. 

Oracle provides an open source [Terraform provider for Oracle Cloud Infrastructure](https://github.com/oracle/terraform-provider-oci) which you can use to manage all your Cloud infrastructure resources (Network, Compute, Storage, etc).

This image was inspired by https://medium.com/oracledevs/containerized-terraform-for-oci-provider-2deb917783fa

## Building the image

This image has no external dependencies. It can be built using the standard`docker build` command, as follows: 

```
# docker build -t oracle/terraform-oci:2.0.6 .
```

### Manually specifying versions

By default, the image will install the latest available version of Terraform and the Terraform provider for OCI. If you want to install a specific version of either of these, you can pass a specific `--build-arg` during the build process of the image.

Here is an example command that uses a specific version of Terraform and the Provider for OCI:

```
# docker build -t oracle/terraform-oci:2.0.6 \
  --build-arg TERRAFORM_VERSION="-0.11.2-1.el7" \
  --build-arg OCI_PROVIDER_VERSION="-2.0.5-1.el7" \
  .
```

Note that the argument includes the initial hypen separator. To find out which versions are available, check the [Oracle Linux 7 Developer Channel](http://yum.oracle.com/repo/OracleLinux/OL7/developer/x86_64/index.html) on the [Oracle Linux Yum Server](http://yum.oracle.com).

## Running Terraform

Create a directory to store your Terraform configuration files and specify that directory as the source of the `VOLUME` when starting the container:

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

To simplify working with Terraform inside a container, create an alias (or a shell script) so that you can access Terraform as if it were running locally on your machine:

```
$ alias terraform-oci="docker run \
   --interactive --tty --rm \
   --volume "$PWD":/data \
   oracle/terraform-oci:2.0.6 terraform"
```
## Public Domain Dedication

This Dockerfile was created by Oracle and has been dedicated to the public domain by Oracle.  The scope of Oracle's public domain dedication is limited to the content of the Dockerfile itself and does not extend to any other content in Docker images that may be created using the Dockerfile. Such Docker images, including any automated builds that are created and made available by Oracle, may contain material that is subject to copyright and other intellectual property rights of Oracle and/or third parties, which is licensed under terms specified in the applicable material and/or in the source code for that material.
