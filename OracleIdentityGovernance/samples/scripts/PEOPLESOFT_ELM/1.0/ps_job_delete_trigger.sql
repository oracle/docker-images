CREATE OR REPLACE TRIGGER ps_job_delete_trigger
AFTER DELETE ON ps_lm_person_job
FOR EACH ROW
DECLARE
    operationcode VARCHAR2(20);
    entitykey     VARCHAR2(30);
BEGIN
    operationcode := '2';
    entitykey := :OLD.LM_PERSON_ID;

    IF operationcode IS NOT NULL
       AND entitykey IS NOT NULL
    THEN
        UPDATE oag_entity_changes oec
           SET oec.timestamp = CURRENT_TIMESTAMP
         WHERE oec.opcode = operationcode
           AND oec.key    = entitykey;

        IF SQL%ROWCOUNT = 0 THEN
            INSERT INTO oag_entity_changes
                (key, opcode, timestamp)
            VALUES
                (entitykey, operationcode, CURRENT_TIMESTAMP);
        END IF;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('EXCEPTION ALERT!!!');
END;
/