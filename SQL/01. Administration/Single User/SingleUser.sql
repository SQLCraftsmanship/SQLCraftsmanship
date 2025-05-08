
USE master
GO

-- Step 1: Check DB Status
SELECT name, user_access_desc, state_desc
FROM sys.databases
WHERE name = 'ExpressLaneExtracts'
GO

-- Step 2: Check who is connect to the Instance
sp_whoisactive
GO

-- Step 3: Check who is connect to a specific DB
SELECT 
    s.session_id,
    s.login_name,
    s.host_name,
    s.program_name,
    r.status,
    r.command,
    r.start_time
FROM sys.dm_exec_sessions s
JOIN sys.dm_exec_requests r ON s.session_id = r.session_id
WHERE r.database_id = DB_ID('ExpressLaneExtracts')
GO

-- Step 4: Check if the Log has something that maybe chenged the status of the DB
SELECT TOP 100 *
FROM fn_dblog(NULL, NULL)
WHERE Operation = 'LOP_BEGIN_XACT'
AND Context = 'LCX_NULL'
AND [Transaction Name] = 'ALTER DATABASE'
GO

-- Step 5: Kill al sessions for a DB
USE master;
GO

DECLARE @dbName NVARCHAR(128) = 'ExpressLaneExtracts';
DECLARE @sql NVARCHAR(MAX) = '';

SELECT @sql += 'KILL ' + CAST(session_id AS NVARCHAR(10)) + '; '
FROM sys.dm_exec_sessions
WHERE database_id = DB_ID(@dbName);

EXEC sp_executesql @sql;


/*
Step 6: Change DB status to Multi User

USE master;
GO
ALTER DATABASE ExpressLaneExtracts SET MULTI_USER WITH ROLLBACK IMMEDIATE;
*/
