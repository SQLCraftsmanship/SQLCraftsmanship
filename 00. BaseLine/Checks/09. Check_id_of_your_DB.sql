
--Determine the id of your database
DECLARE @intDBID INTEGER

SET @intDBID = ( SELECT dbid FROM MASTER.DBO.SYSDATABASES WHERE name = 'mydatabasename')
