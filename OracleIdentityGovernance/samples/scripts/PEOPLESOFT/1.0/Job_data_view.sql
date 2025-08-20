-- Copyright (c) 2025 Oracle and/or its affiliates.
--
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
--
--  Author: OAG Development
--
--  Description: Script file to create JOB_DATA_VIEW in the AG Service Account User Schema of the PSFT DB, required for OAG integration
--
--  DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

CREATE OR REPLACE VIEW job_Data_View (
empl_id,
empl_rcd,
eff_dt,
EFF_SEQ,
business_unit,
empl_type,
empl_class,
officer_Code,
company,
per_org,
POSITION_NBR,
poi_type,
deptid,
jobcode,
supervisor_id,
hr_status,
empl_status,
full_part_time,
action,
action_reason,
locationCode,
postalAddress,
street,
address2,
city,
county,
state,
postalCode,
job_type,
setid_jobcode,
job_title,
end_date,
termination_dt,
reports_to,
department_codes,
department_levels,
department_titles,
Description,
lastupddttm ) AS
SELECT
    pj.emplid,
    pj.empl_rcd,
    pj.effdt,
    pj.EFFSEQ,
    pj.business_unit,
    pj.empl_type,
    pj.empl_class,
    pj.officer_cd,
    pj.company,
    pj.per_org,
    pj.POSITION_NBR,
    pj.poi_type,
    pj.deptid,
    pj.jobcode,
    pj.supervisor_id,
    pj.hr_status,
    pj.empl_status,
    pj.full_part_time,
    pj.action,
    pj.action_reason,
    pj.location,
    pl.descr,
    pl.address1,
    pl.address2,
    pl.city,
    pl.county,
    pl.state,
    pl.postal,
    pj.JOB_INDICATOR,
    setid_jobcode,
    pjc.descr,
    To_Date(NULL, 'YYYYMMDD'),
    pj.termination_dt,
    pj.reports_to,
    null,
    null,
    null,
    null,
    pj.lastupddttm
FROM
    ps_job pj
        left join PS_JOBCODE_TBL pjc on pj.SETID_JOBCODE=pjc.setid and pj.jobcode = pjc.jobcode  and pj.effdt = pjc.effdt
        left join PS_LOCATION_TBL pl on pj.location=pl.location;