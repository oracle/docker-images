#!/bin/bash
docker run --name oggoradb -h oggoradb -e ORACLE_SID=ORCL -e ORACLE_PDB=pdb1 -e ORACLE_PWD=welcome1 -P ogg-oracle:12.1.0.2-ee
