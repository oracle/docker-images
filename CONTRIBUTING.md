# Contribution guidelines

<!-- markdownlint-disable MD036 -->
*Last updated: March 2023*

Oracle welcomes contributions to this repository from anyone.

If you want to submit a pull request to fix a bug or enhance an existing
`Dockerfile`, please open an issue first and link to that issue when you
submit your pull request.

If you have any questions about a possible submission, we encourage you to start
a discussion about the contribution to get feedback from other users.

## Contributing code

All contributors are expected to adhere to our [code of conduct](CODE_OF_CONDUCT.md).

External contributions are only accepted from contributors who have signed the
[the Oracle Contributor Agreement](https://oca.opensource.oracle.com/) (OCA).
The [OCA Bot](https://github.com/apps/oracle-contributor-agreement) automatically
checks every pull request and will provide a link for you to follow to sign
the agreement if it can't find one for you.

## Oracle product ownership and responsibility

For any new product content, *you must obtain internal Oracle approvals for the
distribution of this content prior to submitting a pull request*. If you are
unfamiliar with the approval process to submit code to an existing GitHub
repository, please contact the [Oracle Open Source team](mailto:opensource_ww_grp@oracle.com)
for details.

The GitHub user who submits the initial pull request to add a new product image
should add themselves to the [code owner](./CODEOWNERS) file in that same
request. This will flag the user as the owner of the content and any future pull
requests that affect the content will need to be approved by this user.

The code owner will also be assigned to any issues relating to their content.

You must ensure that you check the [issues](https://github.com/oracle/docker-images/issues)
on at least a weekly basis, though daily is preferred.

If you wish to nominate additional or alternative users, they must be a visible
member of the [Oracle GitHub Organisation](https://github.com/orgs/oracle/people/).

Contact [Avi Miller](https://github.com/Djelibeybi) for more information.

## Opening issues

For bugs or enhancement requests, please file a GitHub issue unless it's
security related. When filing a bug remember that the better written the bug is,
the more likely it is to be fixed. If you think you've found a security
vulnerability, do not raise a GitHub issue and follow the instructions in our
[security policy](./SECURITY.md).

## Pull request process

1. Fork this repository
1. Create a branch in your fork to implement the changes. We recommend using
the issue number as part of your branch name, e.g. `1234-fixes`
1. Ensure that any documentation is updated with the changes that are required
by your fix.
1. Ensure that any samples are updated if the base image has been changed.
1. Submit a pull request. *Do not leave the pull request blank*. Explain exactly
what your changes are meant to do and provide simple steps on how to validate
your changes. Ensure that you reference the issue you created as well.
We will assign the pull request to 2-3 people for review before it is merged.

## Guidelines for contributions

All contributions must meet the following quality and style guidelines, regardless of whether
they are made by an Oracle employee or not.

Oracle employees must ensure their membership of the Oracle GitHub Organization
and their Oracle email address are publicly visible on their profile. This will
allow the OCA Bot to properly identify you.

### Code and documentation quality and style requirements

All pull requests are checked by the following linters to ensure your contribution
meets the default quality, style and formatting guidelines of each language:

| Language     | Linter                                           |
| ------------ | ------------------------------------------------ |
| Dockerfiles | [hadolint](https://github.com/hadolint/hadolint) |
| GitHub Actions | [actionlint](https://github.com/rhysd/actionlint) |
| Markdown files | [markdownlint](https://github.com/igorshubovych/markdownlint-cli)
| Shell scripts | [ShellCheck](https://github.com/koalaman/shellcheck) / [shfmt](https://github.com/mvdan/sh)

You can use the provided [`lint`](./scripts/lint) script to run the linters
locally before submitting a pull request. The script will scan all files from
the current directory and below, so `cd` to a subdirectory before running the
script to only scan a subset of files.

### Base image rules

1. Extend an existing product image wherever possible. For example, if your
   product requires WebLogic, then extend the WebLogic image instead of creating
   your own WebLogic installation.
1. If you can't extend an existing product image, your image must use either the
   `oraclelinux:8` (preferred) or `oraclelinux:8-slim` base image as these images are
   specifically designed to be the smallest possible install size. Both images are
   also updated whenever a security-related errata is published.
1. No new product images based on `oraclelinux:7` or `oraclelinux:7-slim` will be
   accepted.
1. Re-use existing scripts wherever possible. If a particular base image or
   script doesn't have the functionality you need, open an issue and work with
   the image owner to implement it.
1. Specify only the major version of the base in the `FROM` directive, i.e. use
   `FROM oraclelinux:8` or `FROM java/serverjre:8`.
1. All images must provide a `CMD` or `ENTRYPOINT`. If your image is designed
   to be extended, then this should output documentation on how to extend the
   image to be useful.
1. Use `LABEL` instructions for additional information such as ports and volumes.
   The following are common label instructions that should be present in all
   images where applicable:

Additional product-specific labels are listed below:

| Label   | Value | Applicability |
| -------- | ----- | ------------- |
| `provider` | `Oracle` | All images |
| `issues` | `https://github.com/oracle/docker-images/issues` | All images |
| `maintainer` | Name of the maintainer | At the discretion of the author. |
| `volume[.purpose]` | See below | Mandatory for any image with persistent storage
| `port[.purpose]` | See below | Mandatory for all images with port mappings |

### Volume labels

Use `volume` labels to describe the purpose of each volume available to
containers that are created using your image.

If your image provides multiple volumes, use qualified names to specify the
purpose of each volume, e.g. `volume.data` would be for data created by the
container while `volume.setup.scripts` would be the location of scripts used
by the container during its setup process.

Use hierarchical nesting for multiple volumes of the same type, for example:

* `volume.data.dir1`
* `volume.data.dir2`

### Port labels

Use `port` labels to describe the required port mappings needed when running
a container based on your image.

If your images uses multiple ports, use qualified names to specify the purpose of
each port, e.g. `port.http` to specify the HTTP port on which your application is
reachable.

 Use hierarchical nesting for multiple ports of the same type:

* `port.app.http`
* `port.app.https`

The Oracle Database XE image provides a good example of how to specify labels
effectively:

```dockerfile
LABEL "provider"="Oracle"                                   \
      "issues"="https://github.com/oracle/docker-images/issues"         \
      "volume.data"="/opt/oracle/oradata"                               \
      "volume.setup.location1"="/opt/oracle/scripts/setup"              \
      "volume.setup.location2"="/docker-entrypoint-initdb.d/setup"      \
      "volume.startup.location1"="/opt/oracle/scripts/startup"          \
      "volume.startup.location2"="/docker-entrypoint-initdb.d/startup"  \
      "port.listener"="1521"                                            \
      "port.oemexpress"="5500"                                          \
      "port.apex"="8080"
```

### Security-related rules

1. **No hard-coded passwords.** If passwords are required, generate them
   on container startup using `openssl rand` or accept a password argument during
   container startup (via `-e`).
1. **No world-writeable directories or files.** Limit read and write to file
   owners if possible, or groups at most. Do not allow anyone to write to files.
1. Do not require the use of the `--privileged` flag when running a container.
1. Do not run an SSH daemon (`sshd`) inside a container.
1. Do not use host networking mode (`--net=host`) for a container.

### Documentation rules

1. No Oracle host or domain names should be included in any code or examples.
   If an example domain name is required, use `example.com`.
1. All documentation including `README.md` files must meet Oracle
   documentation standards. For content submitted by internal Oracle teams,
   it is recommended that your documentation team either write or at least
   review this content. Externally submitted documentation will be reviewed
   during the PR process.
1. Docker and Podman are product names and trademarks and should only be used
   when referring to those products specifically and both should be capitalised,
   except when used in monospaced formatted command-line examples.
1. All build or usage examples should be based on [Podman](https://docs.oracle.com/en/operating-systems/oracle-linux/podman/)
   running on Oracle Linux 8 or Oracle Linux 9.

### Guidelines and recommendations

The following are some guidelines that will not prevent an image from being
merged, but are generally frowned upon if breached.

* Always aim to produce the smallest possible image. This means using multi-stage
  builds with a final stage using the least amount of layers possible. Combine
  as much as possible within a single directive and be sure to remove any
  cache created by `dnf` or `yum` or other tools.
* Don't install all possible required RPMs, even if the product
  documentation says so. Some RPMs aren't applicable inside a container, e.g
  filesystem utilities (`btrfs-progs`, `ocfs2-tools`, `nfs-utils`).
* Don't install any interactive/user tools, e.g. things like `vim`, `less` or
  `man`. Debugging should be done prior to the image submission.
* Don't install `wget` as the base images already include `curl`.
* Always remember to run `rm -rf /var/cache/yum` or `dnf clean all` in the same
  `RUN` directive as any `yum` or `dnf` command so that the metadata is not
  stored in the layer.
* Always document any inputs (via `--build-arg` or `-e`) required by
  `docker build` or `docker run`. This documentation should also clearly state
  any defaults that are used if no input is provided.
* If a custom value must be provided by the end-user, the build or run should
  gracefully fail if that value is not provided.

## Code of conduct

Follow the [Golden Rule](https://en.wikipedia.org/wiki/Golden_Rule). If you'd
like more specific guidelines, see the [Contributor Covenant Code of Conduct][COC].

[COC]: https://www.contributor-covenant.org/version/1/4/code-of-conduct/

Copyright (c) 2017, 2023 Oracle and/or its affiliates.
