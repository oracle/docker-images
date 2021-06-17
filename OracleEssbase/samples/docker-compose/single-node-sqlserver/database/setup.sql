CREATE DATABASE CertDB
GO

ALTER DATABASE CertDB set Read_committed_snapshot on
GO

DECLARE @collate sysname
SELECT @collate = convert (sysname, serverproperty('COLLATION'))
IF ( charindex(N'_CI', @collate) > 0)
BEGIN 
        SELECT @collate=replace(@collate, N'_CI', N'_CS')
        exec('Alter database CertDB COLLATE ' + @collate)
END
GO
