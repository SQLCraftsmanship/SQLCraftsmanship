
Diff between Full and Simple recovery mode
	Full	
		You can revoer your database to any point in time
	
	LOG
		You can not


------------------------------------------------------------------------------
------------------------------------------------------------------------------


-- Check Databse Recovery mode
SELECT
	Name, State_Desc, recovery_model_desc
FROM SYS.DATABASES
WHERE Name = 'ExpressLane';

-- Check Transaction Log Size
WITH LogSizeInfo AS (
    SELECT 
        DB_NAME(database_id) AS [DatabaseName],
        name AS [FileName],
        type_desc AS [TypeDescription],
        size / 128.0 AS [CurrentSizeMB], -- size is in 8 KB pages, converting to MB
        size / 128.0 / 1024.0 AS [CurrentSizeGB], -- converting MB to GB
        (size - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)) / 128.0 AS [FreeSpaceMB], -- calculating free space in MB
        (size - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)) / 128.0 / 1024.0 AS [FreeSpaceGB] -- converting MB to GB
    FROM 
        sys.master_files
    WHERE 
        type_desc = 'LOG' -- filtering for log files
)
SELECT 
    DatabaseName,
    FileName,
    TypeDescription,
    CAST(CurrentSizeMB AS DECIMAL(10, 2)) AS CurrentSizeMB,
    CAST(CurrentSizeGB AS DECIMAL(10, 2)) AS CurrentSizeGB,
    CAST(FreeSpaceMB AS DECIMAL(10, 2)) AS current_free_size_MB,
    CAST(FreeSpaceGB AS DECIMAL(10, 2)) AS current_free_size_GB
FROM 
    LogSizeInfo
WHERE
	DatabaseName = 'ExpressLane'
ORDER BY 
    DatabaseName;

DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS
CHECKPOINT;


-- Change DB to single user
USE master;
GO
ALTER DATABASE ExpressLane
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE;
GO
--ALTER DATABASE ExpressLane
--SET READ_ONLY;
--GO



-- Full BKP
BACKUP DATABASE [ExpressLane] 
TO DISK = N'M:\ExpressLane.bak' WITH 
  NOFORMAT
, NOINIT
, NAME = N'ExpressLane-Full Database Backup'
, SKIP
, NOREWIND
, NOUNLOAD
, COMPRESSION
,  STATS = 10
GO

-- TRL BKP
BACKUP LOG [ExpressLane] 
TO DISK = N'M:\ExpressLaneLog.trn' WITH 
   NOFORMAT
,  NOINIT
,  NAME = N'ExpressLane-Full Database Backup'
,  SKIP
,  NOREWIND
,  NOUNLOAD
,  STATS = 10
GO

-- Check Logreuse
SELECT name, log_reuse_wait_desc, is_cdc_enabled 
FROM sys.databases
WHERE name = 'ExpressLane';
GO

USE ExpressLane
GO
EXEC sys.sp_cdc_disable_db
GO


-- Shrink
ALTER DATABASE ExpressLane
SET RECOVERY SIMPLE
GO
DBCC SHRINKFILE ('ExpressLane_log', 1)

-- DBCC SHRINKFILE ('ExpressLane_log', 0, TRUNCATEONLY)
GO
ALTER DATABASE ExpressLane
SET RECOVERY FULL
GO

-- Change to multi user
ALTER DATABASE ExpressLane
SET MULTI_USER;
GO

------------------------------------------------------------------------------
------------------------------------------------------------------------------

USE TEMPDB
GO

DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS
CHECKPOINT;

DBCC SHRINKFILE(templog, 1)
DBCC SHRINKFILE(tempdev, 1)


