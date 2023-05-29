--=============================================--
-- Script file for Creating: Database User
-- & for Granting basic privileges, like: Connect, Create synonym & alter procedure
--=============================================--

Accept USERNAME prompt"Enter New database Username to be created::"
Accept USERPWD prompt"Enter the New user password::" hide
CREATE USER &USERNAME identified by &USERPWD;
alter user &USERNAME enable editions;
prompt grant connect, resource to &USERNAME;
grant connect, resource to &USERNAME;

prompt grant create synonym to &USERNAME;
grant create synonym to &USERNAME;

prompt grant alter any procedure to &USERNAME;
grant alter any procedure to &USERNAME;
