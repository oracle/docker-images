
Tuxedo TMA samples on Docker

## Configuration
## for TMA SNA
1. Configure `sna.in` file in tma_samples.zip if neccessary.

* wasa                                   `Mainframe Host Name`
* 12200                                  `Mainframe Port Number`
* VT210                                  `Stack Type`
* CRMLU09                                `Local LU`
* CICSA                                  `Remote LU`
* CR09                                   `Local SYSID`
* CICS                                   `Remote SYSID`
* CRM12200                               `SNA Group`
* /home/oracle/tuxHome/tuxedo12.2.2.0.0  `Tuxedo Path`

2. Make sure that CRM on z/OS is configured and running properly, which could be referred to edoc.

## for TMA TCP
1. Configure `tcp.in` file in tma_samples.zip if neccessary
* wasa                                   `Mainframe Host Name`
* /home/oracle/tuxHome/tuxedo12.2.2.0.0  `Tuxedo Path`

2. Make sure that gateway for CICS and IMS on z/OS are configured and running properly, which could be referred to edoc.

## How to build
build.sh

## How to run
You can start the image in a new container with:
docker run -ti -v ${Local_volumes_dir}/TuxedoVolumes/${VERSION}:/u01/oracle/user_projects oracle/tuxedotmasample:12.2.2 /bin/bash

which will put you into the container with a bash prompt.  If you want to test the samples, simply execute the `tmasna_runme.sh` or `tmatcp_runme.sh`.

