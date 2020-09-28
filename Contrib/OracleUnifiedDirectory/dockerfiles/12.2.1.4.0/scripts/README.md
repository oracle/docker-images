# Local Setup Scripts

This directory contains local setup scripts to build and run the OUD and OUDSM Docker image respectively container. Most of the scripts are originated in the Git repositoy [oehrlis/oradba_init](https://github.com/oehrlis/oradba_init)).

| Script                                                  | Runas  | Description                                                                                                   |
|---------------------------------------------------------|--------|---------------------------------------------------------------------------------------------------------------|
| [00_setup_oradba_init.sh](00_setup_oradba_init.sh)      | root   | Initialize and install oradba init scripts. Define common functions                                           |
| [01_setup_os_oud.sh](01_setup_os_oud.sh)                | root   | Configure Oracle Enterprise Linux for Oracle Unified Directory installations.                                 |
| [10_setup_oud.sh](10_setup_oud)                         | oracle | Install Oracle Unified Directory 11g, 12c and 12c OUDSM. Install type defined by *OUD_TYPE*                   |
| [11_setup_oud_patch.sh](11_setup_oud_patch.sh)          | oracle | Patch Oracle Unified Directory binaries. If necessary called by `10_setup_oud.sh`                             |
| [20_setup_oudbase.sh](20_setup_oudbase.sh)              | oracle | Setup and configure OUD Base Environments scripts (see [oehrlis/oudbase](https://github.com/oehrlis/oudbase)) |
| [60_start_oud_instance.sh](60_start_oud_instance.sh)    | oracle | Start an Oracle Unified Directory instance                                                                    |
| [62_create_oud_instance.sh](62_create_oud_instance.sh)  | oracle | Create an Oracle Unified Directory instance                                                                   |
| [63_config_oud_instance.sh](63_config_oud_instance.sh)  | oracle | Configure an Oracle Unified Directory instance                                                                |
| [64_check_oud_instance.sh](64_check_oud_instance.sh)    | oracle | Check an Oracle Unified Directory instance                                                                    |
| [70_start_oudsm_domain.sh](70_start_oudsm_domain.sh)    | oracle | Start an Oracle Unified Directory Services Manager OUDSM console                                              |
| [72_create_oudsm_domain.sh](72_create_oudsm_domain.sh)  | oracle | Create an Oracle Unified Directory Services Manager OUDSM console                                             |
| [72_create_oudsm_domain.py](b72_create_oudsm_domain.py) | oracle | Python script to create an Oracle Unified Directory Services Manager console OUDSM                            |
| [74_check_oudsm_console.sh](74_check_oudsm_console.sh)  | oracle | Check an Oracle Unified Directory Services Manager console OUDSM                                              |