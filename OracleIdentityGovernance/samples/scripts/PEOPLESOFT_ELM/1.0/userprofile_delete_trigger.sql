CREATE OR REPLACE TRIGGER userprofile_delete_trigger AFTER
    DELETE ON psoprdefn
    FOR EACH ROW
DECLARE
operationcode VARCHAR2(20);
    entitykey     VARCHAR2(30);
BEGIN
    IF deleting THEN
        operationcode := '3';
        entitykey := :old.oprid;
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