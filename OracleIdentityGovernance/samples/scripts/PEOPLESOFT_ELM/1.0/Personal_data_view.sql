-- Copyright (c) 2025 Oracle and/or its affiliates.
--
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
--
--  Author: OAG Development
--
--  Description: Script file to create PERSONAL_DATA_VIEW in the AG Service Account User Schema of the PSFT DB, required for OAG integration
--
--  DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.

CREATE OR REPLACE VIEW personal_data_view (
    empl_id,
    first_name,
    last_name,
    middle_name,
    pref_first_name,
    name_title,
    phone,
    email,
    country,
    address1,
    address2,
    address3,
    city,
    state,
    postal,
    lastupddttm
) AS
SELECT
    p.LM_PERSON_ID AS empl_id,
    n.FIRST_NAME,
    n.LAST_NAME,
    n.MIDDLE_NAME,
    n.PREF_FIRST_NAME,
    n.NAME_TITLE,
    ph.LM_PHONE AS phone,
    em.LM_EMAIL_ADDR AS email,
    a.COUNTRY,
    a.ADDRESS1,
    a.ADDRESS2,
    a.ADDRESS3,
    a.CITY,
    a.STATE,
    a.POSTAL,
    NULL AS lastupddttm
FROM PS_LM_PERSON p
LEFT JOIN PS_LM_PERSON_NAME n
    ON n.LM_PERSON_ID = p.LM_PERSON_ID
LEFT JOIN PS_LM_PERSON_PHONE ph
    ON ph.LM_PERSON_ID = p.LM_PERSON_ID
   AND ph.LM_PRIMARY = 'Y'
LEFT JOIN PS_LM_PERSON_ADDR a
    ON a.LM_PERSON_ID = p.LM_PERSON_ID
   AND a.EFF_STATUS = 'A'
LEFT JOIN PS_LM_PERSON_EMAIL em
    ON em.LM_PERSON_ID = p.LM_PERSON_ID
   AND em.LM_PRIMARY = 'Y';