-- Copyright (c) 2025 Oracle and/or its affiliates.
--
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
--
--  Author: OAG Development
--
--  Description: Script file to create PERSONAL_DATA_VIEW in the AG Service Account User Schema of the PSFT DB, required for OAG integration
--
--  DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

CREATE OR REPLACE VIEW personal_data_view ( empl_id,
first_name,
last_name,
middle_name,
pref_first_name,
name_title,
phone,
email,
organization_name,
country,
address1,
address2,
address3,
city,
state,
postal,
lastupddttm,
description,
employeeType,
employmentStatus,
hrStatus,
manager
) AS
SELECT
    pd.emplid,
    pd.first_name,
    pd.last_name,
    pd.middle_name,
    pd.pref_first_name,
    pd.name_title,
    pd.phone,
    pe.email_addr,
    '',
    pd.country,
    pd.address1,
    pd.address2,
    pd.address3,
    pd.city,
    pd.state,
    pd.postal,
    pd.lastupddttm,
    null,
    null,
    null,
    null,
    null
FROM
    ps_personal_data pd
        LEFT JOIN ps_email_addresses pe ON pd.emplid = pe.emplid and pe.pref_email_flag='Y';