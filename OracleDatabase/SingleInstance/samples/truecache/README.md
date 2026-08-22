## True Cache Primary Script Sample

Use [configure-primary-truecache-service.sh](/scratch/sauahuja/gobin/goprojects/src/github.com/user/dboper/docker-images/OracleDatabase/SingleInstance/samples/truecache/configure-primary-truecache-service.sh) as the sample primary-host script for the manual primary-side service step in wallet-backed True Cache deployments. The script creates the primary service if needed, starts it if needed, and then runs the primary-side DBCA True Cache service configuration.

In the supported True Cache extension-image workflow, this same script is also prebaked into the image at `/home/oracle/configure-primary-truecache-service.sh`. When the primary pod uses that extension image too, no separate manual copy step is needed.

On RAC primaries, the current sample also resolves the local instance `ORACLE_SID` from `srvctl` before it uses local `/ as sysdba` connectivity. If an older copy of the script is still installed on the primary host, the automatic scheduler-driven flow can surface that stale script as `ORA-27369` in the True Cache pod while the underlying helper log shows `ORA-12162`.

Copy this file to the primary host at the default path:

```bash
/home/oracle/configure-primary-truecache-service.sh
```

For RAC automatic registration, place the same script at the same path on every RAC node where the scheduler job might run.

Then make it executable by the Oracle software owner:

```bash
cp configure-primary-truecache-service.sh /home/oracle/configure-primary-truecache-service.sh
chown oracle:oinstall /home/oracle/configure-primary-truecache-service.sh
chmod 755 /home/oracle/configure-primary-truecache-service.sh
```

If you use a different target path on the primary host, adjust the manual command accordingly. For automatic registration, set `PRIMARY_TC_SERVICE_SCRIPT_PATH` in the True Cache container environment to the custom path that the DBMS scheduler job should execute on the primary host. In the SIDB manifest, that looks like:

```yaml
envVars:
  - name: PRIMARY_TC_SERVICE_SCRIPT_PATH
    value: /custom/path/configure-primary-truecache-service.sh
```

If the primary-side DBCA step should use a mkstore wallet instead of a raw SYS password, place that wallet on the primary host and set `PRIMARY_TC_SERVICE_WALLET_PATH` in the True Cache container environment to the primary-host directory containing `ewallet.p12`.

For `AUTO_TC_SVC_REGISTRATION=true`, this is also a RAC primary-host prerequisite:

- `DBMS_SCHEDULER` executable jobs run as the OS user and group configured in `$ORACLE_HOME/rdbms/admin/externaljob.ora`.
- That user must be able to execute both `/home/oracle/configure-primary-truecache-service.sh` and every executable the script launches, especially the RAC `dbca` binary.
- Keep the sample helper owned by `oracle:oinstall` and executable.
- On RAC homes where `dbca` is installed as `oracle:oinstall` with mode `750`, the scheduler user should normally be:

```ini
run_user = oracle
run_group = oinstall
```

Do not stop at `externaljob.ora`. Validate the actual runtime user with a real scheduler smoke test before enabling `AUTO_TC_SVC_REGISTRATION=true`:

```sql
BEGIN
  DBMS_SCHEDULER.CREATE_JOB(
    job_name            => 'EXTJOB_ID_TEST',
    job_type            => 'EXECUTABLE',
    job_action          => '/bin/bash',
    number_of_arguments => 2,
    enabled             => FALSE,
    auto_drop           => FALSE
  );

  DBMS_SCHEDULER.SET_JOB_ARGUMENT_VALUE('EXTJOB_ID_TEST', 1, '-lc');
  DBMS_SCHEDULER.SET_JOB_ARGUMENT_VALUE(
    'EXTJOB_ID_TEST', 2,
    'id > /tmp/extjob_id_test.out; echo ORACLE_HOME=$ORACLE_HOME >> /tmp/extjob_id_test.out; echo ORACLE_SID=$ORACLE_SID >> /tmp/extjob_id_test.out'
  );

  DBMS_SCHEDULER.RUN_JOB('EXTJOB_ID_TEST', use_current_session => TRUE);
END;
/
```

Then verify the output on the RAC node where the job ran:

```bash
cat /tmp/extjob_id_test.out
```

The automatic path is ready only when that file shows the Oracle DB software owner, for example `uid=... (oracle)`. If it shows `grid` instead, the scheduler executable job is still running in the wrong OS context for the helper and the RAC scheduler runtime still needs to be corrected.

Manual primary-host execution does not use `externaljob.ora`, so this prerequisite applies to the automatic scheduler-driven flow, not the manual-only flow.
