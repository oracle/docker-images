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
    pj.emplid AS empl_id,
    pj.empl_rcd,
    pj.effdt AS eff_dt,
    pj.effseq AS eff_seq,
    pj.business_unit,
    pj.empl_type,
    pj.empl_class,
    pj.officer_cd AS officer_code,
    pj.company,
    '' AS per_org,
    pj.position_nbr,
    pj.deptid,
    pj.jobcode,
    pj.supervisor_id,
    pj.empl_status,
    pj.full_part_time,
    pj.action,
    pj.action_reason,
    pj.location AS locationcode,
    '' AS locationdetails,
    pj.job_indicator AS job_type,
    pj.setid_jobcode,
    pjc.descr AS job_title,
    '' AS end_date,
    pj.reports_to,
    '' AS dept_code_hierarchy,
    '' AS lastupddttm
FROM ps_job pj
LEFT JOIN ps_jobcode_tbl pjc
    ON pj.setid_jobcode = pjc.setid
   AND pj.jobcode = pjc.jobcode
   AND pj.effdt = pjc.effdt;