-- For enabling REST capabilities in our objects the user needs DBA privileges
CREATE USER sample IDENTIFIED BY changeit;
GRANT DBA TO sample WITH ADMIN OPTION;