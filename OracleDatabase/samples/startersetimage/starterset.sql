-- Create test user
GRANT CONNECT, RESOURCE, UNLIMITED TABLESPACE TO TEST IDENTIFIED BY test;
-- Connect as test user
CONN TEST/test@//localhost:1521/STARTERSET
-- Create starter set
CREATE TABLE PEOPLE(name VARCHAR2(10));
INSERT INTO PEOPLE (name) VALUES ('Larry');
INSERT INTO PEOPLE (name) VALUES ('Bruno');
INSERT INTO PEOPLE (name) VALUES ('Gerald');
COMMIT;
exit;
