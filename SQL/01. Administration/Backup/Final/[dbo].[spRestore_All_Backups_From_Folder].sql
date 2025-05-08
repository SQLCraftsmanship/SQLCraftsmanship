
USE [DBA]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO


/*******************************************************************************************************************************************
Adapted from: https://www.sqlservercentral.com/Forums/Topic401619-31-1.aspx

Purpose: 
Restore one or many database backups from a single directory. This script reads all database backups that are found in 
the @restoreFromDir parameter. Any file that matches the form %_FULL_% will be restored to the file locations specified in 
the RestoreTo... parameter(s). 

The restored database name is determined from the headers in the backup file, so will match the originally backed up database.
We only prcoess FULL backups and ignore DIFF's or TRN's.

Examples Calls:
EXEC dbo.spRestore_All_Backups_From_Folder 'G:\SQLBACKUP_File'

If you use declare/set option then you don't have to use this command to restore
EXEC dbo.spRestore_All_Backups_From_Folder 'C:\sqldb\sql_backup', 'C:\sqldb\sql_data', 'C:\sqldb\sql_log' 

Execution methodology

	First
	You will need to enable CMDSHELL in order to execute the SP. This script checks if you need to change anything:

		USE [master]
		GO

		IF (SELECT CONVERT(INT, ISNULL(value, value_in_use)) AS config_value FROM  sys.configurations WHERE  name = 'xp_cmdshell') = 0
			PRINT 'You need to enable CMDSHELL'
		ELSE
			PRINT 'CMDSHELL is already enabled, you can now run the SP.'

	Here is how to enable CMDSHELL:

		EXEC sp_configure 'show advanced options', 1
		GO
		RECONFIGURE
		GO
		EXEC sp_configure 'xp_cmdshell', 1
		GO
		RECONFIGURE
		GO

	Second
		EXEC dbo.spRestore_All_Backups_From_Folder 'C:\sqldb\sql_backup', 'C:\sqldb\sql_data', 'C:\sqldb\sql_log', @recovery = 0 
*******************************************************************************************************************************************/


IF  EXISTS ( SELECT * FROM sys.objects 
			 WHERE Object_id =  OBJECT_ID(N'[dbo].[spRestore_All_Backups_From_Folder]') 
			 AND   Type      IN (N'P', N'PC') )
	DROP PROCEDURE [dbo].[spRestore_All_Backups_From_Folder]
GO

CREATE PROCEDURE dbo.spRestore_All_Backups_From_Folder
	@restoreFromDir		VARCHAR(255)	,           -- The dir. where the DB Backs are located. Do not include a trailing slash.
	@restoreToDataDir	NVARCHAR(512) = NULL,       -- The dir. where the data files (i.e. MDF) will be restored to. Leave blank to use the default database folder.
	@restoreToLogDir	NVARCHAR(512) = NULL,       -- The dir. where the log files  (i.e. LDF) will be restored to. Leave blank to use the default log folder.
	@restoreToSecondaryDataDir NVARCHAR(512) = NULL,-- Allows NDF files to be placed in a different location. Leave blank to use @restoreToDataDir instead.
	@recovery			INT		= 1,                -- Set to 1 to use the option WITH RECOVERY, or 0 for WITH NORECOVERY
	@MatchFileList		CHAR(1) = 'N',				-- Set to 'Y' to restore to the same directory structure that is contained in the backup, creating the 
													-- folders if necessary, and ignoring the @restoreToDataDir / @restoreToLogDir values.
													-- Also allows for secondary data files 'ndf' to be in a different dir than mdf files.
	@OneDBName			VARCHAR(255) = NULL,        -- Filters the list of .BAKs to just this single name. Takes the latest .BAK/.DAT file with this name.
	@bitReplace_Existing_DB BIT = 0                 -- Set to 1 to overwrite existing databases.
AS

SET NOCOUNT ON

DECLARE 
	@filename		  VARCHAR(255) ,
	@cmd			  VARCHAR(8000),
	@cmd2			  VARCHAR(500) ,
	@cmd3			  VARCHAR(255) ,
	@DataName		  VARCHAR(255) ,
	@LogName		  VARCHAR(255) ,
	@LogicalName	  VARCHAR(255) ,
	@PhysicalName	  VARCHAR(255) ,
	@Type			  VARCHAR(20)  ,
	@FileGroupName	  VARCHAR(255) ,
	@Size			  VARCHAR(20)  ,
	@MaxSize		  VARCHAR(20)  ,
	@restoreToDir	  VARCHAR(255) ,
	@searchName		  VARCHAR(255) ,
	@dbName			  VARCHAR(255) ,
	@PhysicalFileName VARCHAR(255)

DECLARE @dirList TABLE (filename VARCHAR(100))


DECLARE @filelist TABLE
(
    LogicalName			 VARCHAR(255), 
    PhysicalName		 VARCHAR(255), 
    Type				 VARCHAR(20), 
    FileGroupName		 VARCHAR(255), 
    Size				 VARCHAR(20), 
    MaxSize				 VARCHAR(20),
    FileId				 INT,
    CreateLSN			 BIT, 
    DropLSN				 BIT, 
    UniqueID			 VARCHAR(255),
    ReadOnlyLSn			 BIT, 
    ReadWriteLSN		 BIT, 
    backupSizeInBytes	 VARCHAR(50), 
    SourceBlockSize		 INT,
    FileGroupid			 INT, 
    LogGroupGUID		 VARCHAR(255),
    DifferentialBaseLSN  VARCHAR(255),
    DifferentialBaseGUID VARCHAR(255),
    isReadOnly			 BIT, 
    IsPresent			 BIT,
    TDEThumbprint		 VARCHAR(255) 
)

DECLARE @Dbnameheaders TABLE 
(
	BackupName			  VARCHAR(256), 
	BackupDescription	  VARCHAR(256), 
	BackupType			  VARCHAR(256), 
	ExpirationDate		  VARCHAR(256), 
	Compressed			  VARCHAR(256), 
	Position			  VARCHAR(256),
	DeviceType			  VARCHAR(256), 
	UserName			  VARCHAR(256), 
	ServerName			  VARCHAR(256), 
	DatabaseName		  VARCHAR(256), 
	DatabaseVersion		  VARCHAR(256), 
	DatabaseCreationDate  VARCHAR(256),
	BackupSize			  VARCHAR(256), 
	FirstLSN			  VARCHAR(256), 
	LastLSN				  VARCHAR(256), 
	CheckpointLSN		  VARCHAR(256), 
	DatabaseBackupLSN	  VARCHAR(256), 
	BackupStartDate		  VARCHAR(256),
	BackupFinishDate	  VARCHAR(256), 
	SortOrder			  VARCHAR(256), 
	CodePage			  VARCHAR(256), 
	UnicodeLocaleId		  VARCHAR(256), 
	UnicodeComparisonStyle VARCHAR(256), 
	CompatibilityLevel	  VARCHAR(256),
	SoftwareVendorId      VARCHAR(256), 
	SoftwareVersionMajor  VARCHAR(256), 
	SoftwareVersionMinor  VARCHAR(256), 
	SoftwareVersionBuild  VARCHAR(256), 
	MachineName			  VARCHAR(256), 
	Flags				  VARCHAR(256),
	BindingID			  VARCHAR(256), 
	RecoveryForkID		  VARCHAR(256), 
	Collation			  VARCHAR(256), 
	FamilyGUID			  VARCHAR(256), 
	HasBulkLoggedData	  VARCHAR(256), 
	IsSnapshot			  VARCHAR(256), 
	IsReadOnly			  VARCHAR(256),
	IsSingleUser		  VARCHAR(256), 
	HasBackupChecksums	  VARCHAR(256), 
	IsDamaged			  VARCHAR(256), 
	BeginsLogChain		  VARCHAR(256), 
	HasIncompleteMetaData VARCHAR(256), 
	IsForceOffline		  VARCHAR(256),
	IsCopyOnly			  VARCHAR(256), 
	FirstRecoveryForkID   VARCHAR(256), 
	ForkPointLSN		  VARCHAR(256), 
	RecoveryModel		  VARCHAR(256), 
	DifferentialBaseLSN   VARCHAR(256), 
	DifferentialBaseGUID  VARCHAR(256),
	BackupTypeDescription VARCHAR(256), 
	BackupSetGUID		  VARCHAR(256), 
	CompressedBackupSize  VARCHAR(256), 
	Containment			  VARCHAR(256),
	KeyAlgorithm		  NVARCHAR(32),
	EncryptorThumbprint	  VARBINARY(20),
	EncryptorType		  NVARCHAR(32)
);

-- Step 1
-- Process parameters
IF RIGHT(@restoreFromDir,1) = '\'
    SET @restoreFromDir = LEFT(@restoreFromDir, LEN(@restoreFromDir)-1)

IF ISNULL(@restoreToDataDir,'') = ''
    SET @restoreToDataDir = CAST(SERVERPROPERTY('InstanceDefaultDataPath') AS NVARCHAR(512))
    --EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultData', @restoreToDataDir output

IF ISNULL(@restoreToLogDir,'') = ''
    SET @restoreToLogDir = CAST(SERVERPROPERTY('InstanceDefaultLogPath') AS NVARCHAR(512))
    --EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultLog', @restoreToLogDir output

IF ISNULL(@restoreToSecondaryDataDir, '') = ''
    SET @restoreToSecondaryDataDir = @restoreToDataDir

	-- Test command
	-- SELECT @restoreToDataDir, @restoreToLogDir, @restoreToSecondaryDataDir

-- Step 2
-- Get the list of database backups that are in the restoreFromDir directory. We only go with FULL backups and ignore DIFF's or TRN's.
IF @OneDBName IS NULL
    SELECT @cmd = 'dir /b /on "' + @restoreFromDir + '\*_FULL*.*"'
ELSE
    SELECT @cmd = 'dir /b /o-d /o-g "' + @restoreFromDir + '\*_FULL*.*"'

	-- Test command
	-- SELECT @cmd,'AllFiles' -- Give All Files in Backup Folder

INSERT @dirList EXEC master..xp_cmdshell @cmd

-- SELECT * FROM @dirList WHERE Filename LIKE '%_FULL%' -- ORDER BY Filename --List all the files in backup folder
SELECT * FROM @dirList WHERE Filename LIKE '%.bak' OR Filename LIKE '%.dat' ORDER BY Filename -- List all the files in backup folder


IF @OneDBName IS NULL
    BEGIN
        DECLARE BakFile_csr CURSOR FOR
        SELECT * FROM @dirList WHERE Filename LIKE '%.bak' OR Filename LIKE '%.dat' ORDER BY Filename
    END
ELSE
    BEGIN 
		-- single db, don't order by filename, take default latest date /o-d parm in dir command above
        SELECT @searchName = @OneDBName + '_FULL%'

        DECLARE BakFile_csr cursor for
        SELECT top 1 * FROM @dirList WHERE filename LIKE @searchName
    END


OPEN BakFile_csr
FETCH BakFile_csr INTO @filename

WHILE @@FETCH_STATUS = 0
    BEGIN
		-- Set @cmd variable
        SELECT @cmd = "RESTORE FILELISTONLY FROM disk = '" + @restoreFromDir + "\" + @filename + "'"
        INSERT @filelist EXEC ( @cmd )

        -- Identify the db name from backup file
        SELECT @cmd3 = "RESTORE HEADERONLY FROM disk = '" + @restoreFromDir + "\" + @filename + "'"
        INSERT @Dbnameheaders EXEC (@cmd3)

		-- Set DB Name
        SELECT @dbName = DatabaseName FROM @Dbnameheaders
        --identify the db name from backup file [END Here]

		-- Check if is OneDBName to restore
		IF @OneDBName IS NULL
            SELECT @dbName = @dbName --left(@filename,datalength(@filename) - patindex('%_FULL_%',reverse(@filename))-3)
        ELSE
            SELECT @dbName = @OneDBName

		-- Perform restore
        SELECT @cmd = "RESTORE DATABASE [" + @dbName + "] FROM DISK = '" + @restoreFromDir + "\" + @filename + "' WITH "
			-- Test command
			-- Example: RESTORE DATABASE [HCPPREPROD] FROM DISK = 'C:\To Restore\HCPPREPROD_FULL_20180103.dat' WITH 

		-- Print Restoring command
        PRINT 'RESTORING DATABASE ' + @dbName
			-- Test command
			-- Select * from @filelist ---List of files in backupfile all mdf,ndf,ldf

		-- Cursor to search DB files
        DECLARE DataFileCursor cursor for
        SELECT LogicalName, PhysicalName, Type, FileGroupName, Size, MaxSize
        FROM @filelist

        OPEN DataFileCursor
        FETCH DataFileCursor INTO @LogicalName, @PhysicalName, @Type, @FileGroupName, @Size, @MaxSize

        WHILE @@FETCH_STATUS = 0
            BEGIN
                IF @MatchFileList != 'Y'
                    BEGIN -- RESTORE with MOVE option
                        SELECT @PhysicalFileName = REVERSE(SUBSTRING(REVERSE(RTRIM(@PhysicalName)),1,patindex('%\%',reverse(rtrim(@PhysicalName)))-1 ))

                        IF @Type = 'L'
                            SELECT @restoreToDir = @restoreToLogDir
                        ELSE IF @PhysicalFileName LIKE '%.ndf'
                            SELECT @restoreToDir = @restoreToSecondaryDataDir
                        ELSE
                            SELECT @restoreToDir = @restoreToDataDir

                        IF RIGHT(@restoreToDir, 1) = '\'
                            SET @restoreToDir = LEFT(@restoreToDir, LEN(@restoreToDir)-1)

                        --SELECT @LogicalName, @restoreToDir, @PhysicalFileName
                        SELECT @cmd = @cmd + " MOVE '" + @LogicalName + "' TO '" + @restoreToDir + "\" + @PhysicalFileName + "', "

                    END
                ELSE
                    BEGIN 
						-- Match the file list, attempt to create any missing directory
                        SELECT @restoreToDir = LEFT(@PhysicalName, DATALENGTH(@PhysicalName) - PATINDEX('%\%',REVERSE(@PhysicalName)) )
                        SELECT @cmd2 = "if not exist " +@restoreToDir+ " md " +@restoreToDir
                        EXEC master..xp_cmdshell @cmd2
                    END

                FETCH DataFileCursor INTO @LogicalName, @PhysicalName, @Type, @FileGroupName, @Size, @MaxSize

            END -- DataFileCursor loop

        CLOSE DataFileCursor
        DEALLOCATE DataFileCursor


        IF @recovery = 0
            SELECT @cmd = @cmd + ' NORECOVERY, STATS = 5'
        ELSE
            SELECT @cmd = @cmd + ' RECOVERY, STATS = 5'


        IF @bitReplace_Existing_DB = 1
            SELECT @cmd = @cmd + ', REPLACE'

        SELECT @cmd 'x6'

        IF @bitReplace_Existing_DB = 0 AND DB_ID(@dbName) IS NOT NULL
            PRINT 'Database already exists - skipping... ' + @dbName
        ELSE
            EXEC (@cmd)

        DELETE FROM @filelist
        DELETE FROM @Dbnameheaders

        FETCH BakFile_csr INTO @filename

    END -- BakFile_csr loop

CLOSE BakFile_csr
DEALLOCATE BakFile_csr

RETURN 
GO;
