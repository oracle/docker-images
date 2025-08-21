CREATE OR REPLACE TRIGGER ps_personalData_delete_trigger AFTER
    DELETE ON ps_personal_data
    FOR EACH ROW
DECLARE
operationcode VARCHAR2(20);
    entitykey     VARCHAR2(30);
BEGIN
    IF deleting THEN
        operationcode := '1';
        entitykey := :old.emplid;
END IF;

    IF (
        operationcode IS NOT NULL
        AND entitykey IS NOT NULL
    ) THEN
UPDATE oag_entity_changes oec
SET
    oec.timestamp = current_timestamp
WHERE
    oec.opcode = operationcode
  AND oec.key = entitykey;

IF SQL%rowcount = 0 THEN
            INSERT INTO oag_entity_changes VALUES (
                entitykey,
                operationcode,
                current_timestamp
            );

END IF;

END IF;

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('EXCEPTION ALERT!!!');
END;
/