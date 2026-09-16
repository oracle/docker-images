-- Replace the placeholder password before running this script.
ALTER SESSION SET CONTAINER=FREEPDB1;
CREATE USER app_user IDENTIFIED BY ReplaceWithAStrongPassword;
GRANT CREATE SESSION TO app_user;
EXIT
