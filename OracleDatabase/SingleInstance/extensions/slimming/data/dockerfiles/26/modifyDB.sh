#!/bin/bash

sqlplus / as sysdba << EOF
   alter system set "_kdzk_load_specialized_library"=2 scope=spfile;
   alter system set "_enable_memory_protection_keys"=FALSE scope=spfile;
   alter pluggable database FREEPDB1 close;
   drop pluggable database FREEPDB1 including datafiles;
   shutdown immediate;
   exit;
EOF
