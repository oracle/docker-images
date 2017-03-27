#!/bin/sh

DEPLOY_DIR=${DEPLOY_DIR-`pwd`}
export DEPLOY_DIR

echo ""
echo "ENVIRONMENT INFO: "
echo "================="
echo "DEPLOY_DIR  = ${DEPLOY_DIR}"
echo "ORACLECLI_HOME = ${ORACLECLI_HOME}"
echo ""

cd $ORACLECLI_HOME
source setenv.sh

cd $DEPLOY_DIR
DB_PATCH_LEVEL=`$ORACLE_HOME/sqlplus -S /nolog <<!
set heading off feedback off pagesize 0 verify off echo off
conn $DB_TSAM_USER/$DB_TSAM_PASSWD@//$DB_CONNSTR;
SELECT COUNT(*) FROM GLOBALCONFIG WHERE PARAM  = 'DB_PATCH_LEVEL';
EXIT
!`

if [ $DB_PATCH_LEVEL -ne 0 ]; then
  echo ""
  echo "========================================="
  echo "SUCCESS: Upgrade TSAM schema sucessfully."
  echo "========================================="
  echo ""
  exit 0
fi

$ORACLE_HOME/sqlplus -S /nolog <<!
conn $DB_TSAM_USER/$DB_TSAM_PASSWD@//$DB_CONNSTR;
SET SERVEROUTPUT ON
@${DEPLOY_DIR}/TSAMUpgradeOracleRP.sql
EXIT 0;
!

if [ $? -ne 0 ]; then
  echo ""
  echo "====================================================================="
  echo "FAILED: Upgrade TSAMUpgradeOracleRP.sql failed."
  echo "        Please check your SQLPLUS runtime environment, and try again."
  echo "====================================================================="
  echo ""
  exit 1
fi

echo ""
echo "INFO: Upgrade TSAMUpgradeOracleRP.sql."
echo ""

$ORACLE_HOME/sqlplus -S /nolog 1>/dev/null <<!
conn $DB_TSAM_USER/$DB_TSAM_PASSWD@//$DB_CONNSTR;

SET SERVEROUTPUT ON

--WHENEVER SQLERROR EXIT WARNING;
@${DEPLOY_DIR}/sql/basic_types.sql;
@${DEPLOY_DIR}/sql/basic_ng_types_met.sql;
@${DEPLOY_DIR}/sql/sdk_types.sql;
@${DEPLOY_DIR}/sql/sdk_types_body.sql;
@${DEPLOY_DIR}/sql/sdk_metrics_type.sql;
@${DEPLOY_DIR}/sql/metric_types.sql;
@${DEPLOY_DIR}/sql/metric_type_bodys.sql;

@${DEPLOY_DIR}/sql/target_tables.sql;
@${DEPLOY_DIR}/sql/basic_ng_tables_met.sql;
@${DEPLOY_DIR}/sql/metric_units_tables.sql;
@${DEPLOY_DIR}/sql/admin_tables.sql;
@${DEPLOY_DIR}/sql/log_tables.sql;

@${DEPLOY_DIR}/sql/basic_views.sql;
@${DEPLOY_DIR}/sql/basic_backward_compat_views.sql;

@${DEPLOY_DIR}/sql/mgmt_global_pkgdef.sql;
@${DEPLOY_DIR}/sql/mgmt_global_pkgbody.sql;
@${DEPLOY_DIR}/sql/log_pkgdefs.sql;
@${DEPLOY_DIR}/sql/log_pkgbodys.sql;

@${DEPLOY_DIR}/sql/util_check_pkgdef.sql;
@${DEPLOY_DIR}/sql/util_check_pkgbody.sql;
@${DEPLOY_DIR}/sql/util_lock_pkgdef.sql;
@${DEPLOY_DIR}/sql/util_lock_pkgbody.sql;
@${DEPLOY_DIR}/sql/em_metric_pkgdef.sql;
@${DEPLOY_DIR}/sql/em_metric_pkgbody.sql;
@${DEPLOY_DIR}/sql/mgmt_metric_pkgdef.sql;
@${DEPLOY_DIR}/sql/mgmt_metric_pkgbody.sql;
@${DEPLOY_DIR}/sql/chartdata_pkgdef.sql;
@${DEPLOY_DIR}/sql/chartdata_pkgbody.sql;
@${DEPLOY_DIR}/sql/admin_interval_partition_pkgdef.sql;
@${DEPLOY_DIR}/sql/admin_interval_partition_pkgbody.sql;
@${DEPLOY_DIR}/sql/basic_rollup_pkgdef.sql;
@${DEPLOY_DIR}/sql/basic_rollup_pkgbody.sql;

@${DEPLOY_DIR}/sql/tuxedo_metrics_pkgdef.sql;
@${DEPLOY_DIR}/sql/tuxedo_domain.sql;
@${DEPLOY_DIR}/sql/basic_part_data_upgrade.sql;

EXIT;
!

echo ""
echo "INFO: Upgrade TSAM schema for STATISTICS FEATURE."
echo ""

$ORACLE_HOME/sqlplus -S /nolog <<!
conn $DB_TSAM_USER/$DB_TSAM_PASSWD@//$DB_CONNSTR;
SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT WARNING;
@${DEPLOY_DIR}/sql/tsam_schema_validation.sql
EXIT 0;
!

if [ $? -eq 0 ]; then
  echo ""
  echo "========================================="
  echo "SUCCESS: Upgrade TSAM schema sucessfully."
  echo "========================================="
  echo ""
else
  echo ""
  echo "==========================================================================="
  echo "FAILED: Upgrade TSAM schema for STATISTICS FEATURE failed."
  echo "        Please try to create a new fresh TSAM schema by DatabaseDeployer.sh"
  echo "        and try to run DatabaseUpgradeOracleRP.sh again!"
  echo "==========================================================================="
  echo ""
  exit 1;
fi
