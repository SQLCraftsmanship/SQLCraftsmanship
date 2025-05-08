
-- https://www.mssqltips.com/sqlservertip/1070/simple-script-to-backup-all-sql-server-databases/

-- Database Backup File Name Format DBname_YYYYDDMM.BAK
-- Here is the script that will allow you to backup each database within your instance of SQL Server. You will need to change the 
-- @path to the appropriate backup directory.

DECLARE @name     NVARCHAR(256) -- database name  
DECLARE @path     NVARCHAR(512) -- path for backup files  
DECLARE @fileName NVARCHAR(512) -- filename for backup  
DECLARE @fileDate NVARCHAR(40)  -- used for file name
 
-- specify database backup directory
SET @path = 'C:\test\'
 
-- specify filename format
SELECT @fileDate = CONVERT(NVARCHAR(20),GETDATE(),112) 
 
DECLARE db_cursor CURSOR READ_ONLY FOR  
    SELECT name 
    FROM master.sys.databases 
    WHERE name NOT IN ('master','model','msdb','tempdb','ReportServer','ReportServerTempDB')  -- exclude these databases ,'ReportServer','ReportServerTempDB'
    AND state = 0 -- database is online
    AND is_in_standby = 0 -- database is not read only for log shipping
 
OPEN db_cursor   
FETCH NEXT FROM db_cursor INTO @name   
 
WHILE @@FETCH_STATUS = 0   
BEGIN   
   SET @fileName = @path + @name + '_' + @fileDate + '.BAK'  
   BACKUP DATABASE @name TO DISK = @fileName  
 
   FETCH NEXT FROM db_cursor INTO @name   
END   
 
CLOSE db_cursor   
DEALLOCATE db_cursor
