Oracle Database on Docker - TESTS
===============
This folder contains tests for Docker images. It makes it easier to test the integrity of those images after a change to the build files.

## How to run all tests

Use a Linux x86-64 Docker host with enough memory and disk space for the database images.
Copy these installer archives into the `bin` folder:

* `LINUX.X64_2326000_db_home.zip`
* `LINUX.X64_213000_db_home.zip`
* `LINUX.X64_193000_db_home.zip`
* `linuxx64_12201_database.zip`
* `linuxamd64_12102_database_1of2.zip`
* `linuxamd64_12102_database_2of2.zip`
* Both `linuxamd64_12102_database_se2_*.zip` archives

The builds download the 21c XE and 26ai Free installers automatically.
Internet access is also required to pull base images and install packages.

From this `tests` directory, call `./runAllTests.sh`. It builds the images and then runs
the container tests, returning a nonzero status if a build or test fails.
The build script copies the installers into the corresponding version directories and
removes those copies after successful builds.

## Coverage

The build and container runners cover EE and SE2 for 12.1.0.2, 12.2.0.1, 19.3.0,
21.3.0 and 23.26.0 (26ai), plus 21.3.0 XE and 23.26.0 Free.
The new 21c and 26ai tests are startup smoke tests: they wait for the database readiness
message in the container logs. They do not validate SQL queries or application behavior.
The existing 12c and 19c suites also exercise selected database configuration options.

To run only the container tests against images already built, call `./runContainerTests.sh`
from this directory.

## Copyright
Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
