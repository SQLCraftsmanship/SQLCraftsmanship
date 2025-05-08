
/****************************************************************************************************************************************
Ref : https://www.mssqltips.com/sqlservertip/1070/simple-script-to-backup-all-sql-server-databases/
Desc: This script will allow to backup (Full or Diff) of each database within your instance of SQL Server.
Exec: 
	  e.g

	  CASJSQL01
	  EXEC [dbo].[sp_CreateFullDiffBackup] 'Full', '\\CASJBK01.inmar.ca\SQLBackups\CASJSQL01\AllFullBackupforMigration\'
	  EXEC [dbo].[sp_CreateFullDiffBackup] 'Diff', '\\CASJBK01.inmar.ca\SQLBackups\CASJSQL01\AllDiffBackupforMigration\'

	  CASJSQL02
	  EXEC [dbo].[sp_CreateFullDiffBackup] 'Full', '\\CASJBK01.inmar.ca\SQLBackups\CASJSQL02\AllFullBackupforMigration\'
	  EXEC [dbo].[sp_CreateFullDiffBackup] 'Diff', '\\CASJBK01.inmar.ca\SQLBackups\CASJSQL02\AllDiffBackupforMigration\'
****************************************************************************************************************************************/

USE DBA
GO

IF EXISTS (SELECT Name FROM SYS.PROCEDURES WHERE Name = 'sp_CreateFullDiffBackup')
	DROP PROC [dbo].[sp_CreateFullDiffBackup]
GO

CREATE PROC [dbo].[sp_CreateFullDiffBackup] (@parBackupType NVARCHAR(4) = 'FULL', @path NVARCHAR(MAX))
AS
BEGIN

	SET NOCOUNT ON

	DECLARE @name     NVARCHAR(256) -- Database Name  
	DECLARE @fileName NVARCHAR(512) -- Filename for backup  
	DECLARE @fileDate NVARCHAR(40)  -- Used for file name
	DECLARE @GetTime  TIME

	-- specify filename format
	SELECT @fileDate = CONVERT(NVARCHAR(20),GETDATE(),112) 
 
	DECLARE db_cursor CURSOR READ_ONLY FOR  
		SELECT Name 
		FROM master.sys.databases 
		WHERE name NOT IN ('master','model','msdb','tempdb','ReportServer','ReportServerTempDB')  -- exclude these databases ,'ReportServer','ReportServerTempDB'
		AND state = 0 -- database is online
		AND is_in_standby = 0 -- database is not read only for log shipping
		ORDER BY Name

	 BEGIN TRY
		-- Print Start Time
		SELECT @GetTime = CONVERT(TIME, GETDATE())
		PRINT  @GetTime 
	
		OPEN db_cursor   
		FETCH NEXT FROM db_cursor INTO @name   
 
		WHILE @@FETCH_STATUS = 0

			-- Check which backup type are we gonna do
			IF @parBackupType = 'FULL'
			BEGIN
				-- Set FileName
				SET @fileName = @path + @name + '_' + @fileDate + '_FULL.BAK'  

				-- Execute Full backup
				BACKUP DATABASE @name TO DISK = @fileName  
			
				-- Print name of the DB that is doing the Backup
				PRINT 'Backup Full for ' + @name + ' database is taken place.'

				FETCH NEXT FROM db_cursor INTO @name  
			END   
			ELSE
			BEGIN
				-- Set FileName
				SET @fileName = @path + @name + '_' + @fileDate + '_DIFF.BAK'  

				-- Execute Full backup
				BACKUP DATABASE @name TO DISK = @fileName WITH DIFFERENTIAL, NOINIT, SKIP, NOREWIND, NOUNLOAD,  STATS = 10 
			
				-- Print name of the DB that is doing the Backup
				PRINT 'Backup Diff for ' + @name + ' database is taken place.'

				FETCH NEXT FROM db_cursor INTO @name
			END

		    SELECT @GetTime = CONVERT(TIME, GETDATE())
			PRINT  @GetTime 

	   		CLOSE db_cursor   
			DEALLOCATE db_cursor

	END TRY

	BEGIN CATCH  
    SELECT  
          ERROR_NUMBER()	AS ErrorNumber  
        , ERROR_SEVERITY()  AS ErrorSeverity  
        , ERROR_STATE()		AS ErrorState  
        , ERROR_PROCEDURE() AS ErrorProcedure  
		, ERROR_LINE()      AS ErrorLine
        , ERROR_MESSAGE()	AS ErrorMessage;  

		CLOSE db_cursor   
		DEALLOCATE db_cursor
	END CATCH; 
END;
