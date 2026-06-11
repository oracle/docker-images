-- Copyright (c) 2025 Oracle and/or its affiliates.
--
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
--
--  Author: OAG Development
--
--  Description: Script file to create JOB_DATA_VIEW in the AG Service Account User Schema of the PSFT DB, required for OAG integration
--
--  DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.


CREATE OR REPLACE VIEW job_data_view (
    empl_id,
    empl_rcd,
    eff_dt,
    eff_seq,
    business_unit,
    empl_type,
    empl_class,
    officer_code,
    company,
    per_org,
    position_nbr,
    deptid,
    jobcode,
    supervisor_id,
    empl_status,
    full_part_time,
    action,
    action_reason,
    locationcode,
    locationdetails,
    job_type,
    setid_jobcode,
    job_title,
    end_date,
    reports_to,
    dept_code_hierarchy,
    lastupddttm
) AS
SELECT
    j.LM_PERSON_ID          AS empl_id,
    j.LM_EMPL_RCD           AS empl_rcd,
    j.EFFDT                 AS eff_dt,
    j.LM_EFFSEQ             AS eff_seq,
    j.BUSINESS_UNIT         AS business_unit,
    j.LM_EMPL_TYPE          AS empl_type,
    j.LM_EMPL_CLASS         AS empl_class,
    j.LM_OFFICER_CD         AS officer_code,
    j.LM_HR_COMPANY         AS company,
    j.LM_PER_ORG            AS per_org,
    j.LM_POSITION_NBR       AS position_nbr,
    NULL                    AS deptid,
    j.LM_JOBCODE_ID         AS jobcode,
    j.LM_SUPERVISOR_ID      AS supervisor_id,
    j.LM_ACTIVE             AS empl_status,
    j.LM_FULL_PART_TIME     AS full_part_time,
    NULL                    AS action,
    NULL                    AS action_reason,
    j.LM_LOCATION_ID        AS locationcode,
    NULL                    AS locationdetails,
    j.LM_JOB_INDICATOR      AS job_type,
    NULL                    AS setid_jobcode,
    j.LM_JOB_TITLE          AS job_title,
    j.LM_END_EFFDT          AS end_date,
    j.LM_REPORTS_TO         AS reports_to,
    NULL                    AS dept_code_hierarchy,
    NULL                    AS lastupddttm
FROM PS_LM_PERSON_JOB j;