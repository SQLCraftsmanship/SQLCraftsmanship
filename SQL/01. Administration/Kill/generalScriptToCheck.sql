
/******************************************************************************************************************************************************
-- SCRIPT 1
******************************************************************************************************************************************************/
-- Kill sleeping sessions from sp_who2
-- Ref 
-- https://blog.sqlauthority.com/2019/05/06/sql-server-script-to-kill-all-inactive-sessions-kill-sleeping-sessions-from-sp_who2/
-- NOTA: Este usa MASTER.DBO.SYSPROCESSES

DECLARE @user_spid INT

DECLARE CurSPID CURSOR FAST_FORWARD
FOR
	SELECT SPID
	FROM MASTER.DBO.SYSPROCESSES (NOLOCK)
	WHERE spid   > 50			-- avoid system   threads
	AND   status = 'sleeping'	-- only  sleeping threads
	AND   DATEDIFF(HOUR, last_batch, GETDATE()) >= 24 -- thread sleeping for 24 hours
	-- AND DATEDIFF(mi,last_batch,GETDATE())>=60 -- in minutes (es un monton)
	AND   spid <> @@spid        -- ignore current spid

OPEN CurSPID
FETCH NEXT FROM CurSPID INTO @user_spid
WHILE (@@FETCH_STATUS=0)
BEGIN
	PRINT 'Killing ' + CONVERT(VARCHAR, @user_spid)
	EXEC('KILL ' + @user_spid)
	FETCH NEXT FROM CurSPID INTO @user_spid
END

CLOSE CurSPID
DEALLOCATE CurSPID
GO


/******************************************************************************************************************************************************
-- SCRIPT 2
******************************************************************************************************************************************************/
-- Ref
-- https://www.sqlshack.com/kill-spid-command-in-sql-server/
-- By default, it shows all processes in SQL Server. We might not be interested in the system processes. We can filter the results using the following query.
-- NOTA: Usa SYS.DM_EXEC_SESSIONS
SELECT *
FROM SYS.DM_EXEC_SESSIONS
WHERE is_user_process = 1;


/******************************************************************************************************************************************************
-- SCRIPT 3
******************************************************************************************************************************************************/
-- Ref
-- https://www.sqlservercentral.com/forums/topic/killing-sleeping-processes

print 'The following spids have a last active time older than 30 minutes and will be killed'

-- 30 mins is an arbitrary value, adjust to your needs
DECLARE 
	@program_name	char(30),
	@userid			char(10),
	@spid			smallint,
	@last_batch		datetime,
	@date			datetime,
	@no_of_mins		smallint,
	@occurred		char(1),
	@statement		nvarchar (10)

select @date = getdate()
set @occurred = 'N'

declare kill_cursor cursor for

	select spid, convert(char(10),nt_username), convert(char(30), program_name), last_batch
	from sysprocesses
	where spid > 50

open kill_cursor

fetch next from kill_cursor

into @spid, @userid, @program_name, @last_batch

while @@fetch_status = 0

begin

	select @no_of_mins = datediff(mi, @last_batch, @date)

	if @no_of_mins > 29

	begin

		print convert(char(3),@spid) +' ' +@userid

		set @statement = N'kill ' + convert(nvarchar(3),@spid)

		exec sp_executesql @statement

		set @occurred = 'Y'

	end

	fetch next from kill_cursor

	into @spid, @userid, @program_name, @last_batch

end

close kill_cursor

deallocate kill_cursor

if @occurred = 'N'

begin
	print 'none were found!'
end


/******************************************************************************************************************************************************
-- SCRIPT 4
******************************************************************************************************************************************************/
-- Ref
-- https://blog.sqlauthority.com/2006/12/01/sql-server-cursor-to-kill-all-process-in-database/

CREATE TABLE #TmpWho
	(
		  spid		INT
		, ecid		INT
		, status	VARCHAR(150)
		, loginame	VARCHAR(150)
		, hostname	VARCHAR(150)
		, blk		INT
		, dbname	VARCHAR(150)
		, cmd		VARCHAR(150)
	)

INSERT INTO #TmpWho

EXEC sp_who

DECLARE @spid	 INT
DECLARE @tString VARCHAR(15)
DECLARE @getspid CURSOR

SET @getspid = CURSOR FOR

	SELECT spid
	FROM   #TmpWho
	WHERE  dbname = 'mydb' OPEN @getspid

FETCH NEXT FROM @getspid INTO @spid

WHILE @@FETCH_STATUS = 0

BEGIN
	SET @tString = 'KILL ' + CAST(@spid AS VARCHAR(5))

	EXEC(@tString)
FETCH NEXT FROM @getspid INTO @spid
END

CLOSE @getspid
DEALLOCATE @getspid
DROP TABLE #TmpWho
GO

/******************************************************************************************************************************************************
-- SCRIPT 5
******************************************************************************************************************************************************/
-- Misma Ref que arriba pero sin usar cursor eso es muy bueno
-- I never use cursors for loops. Just prefer to stay away from them. Here’s my solution:

CREATE PROC msp_killallspids (@db varchar(255)) 
AS

declare @min int, @max int
declare @dbname varchar(255), @dbid int
declare @cmd varchar(255)

select @dbid = dbid from master..sysdatabases
where name = @db

select @min = min(spid) from master..sysprocesses where dbid = @dbid
select @max = max(spid) from master..sysprocesses where dbid = @dbid

while @min @min
end

/******************************************************************************************************************************************************
-- SCRIPT 6
******************************************************************************************************************************************************/
-- Same before without use of cursor
DECLARE 
	@count INT ,
	@sno INT,
	@tString VARCHAR(50)

SET @sno = 1

CREATE TABLE #TmpWho
( 
	spid INT
	, ecid INT
	, status VARCHAR(150)
	, loginame VARCHAR(150)
	, hostname VARCHAR(150)
	, blk INT
	, dbname VARCHAR(150)
	, cmd VARCHAR(150),Request_id INT
)

INSERT INTO #TmpWho
EXEC sp_who

CREATE TABLE #TmpWho_second
(
	sno INT IDENTITY
	, spid INT
	, ecid INT
	, status VARCHAR(150)
	, loginame VARCHAR(150)
	, hostname VARCHAR(150)
	, blk INT
	, dbname VARCHAR(150)
	, cmd VARCHAR(150)
	, Request_id INT
)

SELECT @count=count(*) from #TmpWho_second
INSERT INTO #TmpWho_second
SELECT spid
	,ecid
	,status
	,loginame
	,hostname
	,blk
	,dbname
	,cmd
	,Request_id 
FROM #TmpWho 
WHERE spid > 50

WHILE @sno <= @count
BEGIN
	SELECT @tString = 'kill ' + cast(spid as VARCHAR(5)) FROM #TmpWho_second WHERE sno = @sno
	
	EXEC (@tString)

	SELECT @sno AS sno
	SET @sno = @sno + 1
END

DROP TABLE #TmpWho
DROP TABLE #TmpWho_second

/******************************************************************************************************************************************************
-- SCRIPT 7
******************************************************************************************************************************************************/
-- Other example Another “no cursor” approach:

USE MASTER
GO

DECLARE @dbname1 VARCHAR(255)

SET @dbname1 = 'YourDatabase'

WHILE (SELECT COUNT(spid) FROM MASTER..SYSPROCESSES WHERE DBID=DB_ID(@dbname1)) > 0

BEGIN
	DECLARE @klpr1 NVARCHAR(30);
	
	WITH proc1 AS 
	( 
		SELECT TOP 1 'Kill ' + CONVERT(NVARCHAR(30), spid) AS KlPr 
		FROM MASTER..SYSPROCESSES 
		WHERE dbid = DB_ID(@dbname1) 
		ORDER BY DB_ID(@dbname1)
	)

	SELECT @klpr1 = (SELECT KlPr FROM proc1)

	EXEC(@klpr1)
	
	WAITFOR DELAY '00:00:01'
	PRINT @klpr1
END

/******************************************************************************************************************************************************
-- SCRIPT 8
******************************************************************************************************************************************************/
-- A good one but use cursor
-- Ref
-- https://vladdba.com/2021/03/02/t-sql-script-to-kill-multiple-sql-server-sessions-in-one-go/

USE [master]
GO
 
-- Variable declaration
DECLARE  
	  @SPID				SMALLINT
	, @ExecSQL			VARCHAR(11)
	, @Confirm			BIT
	, @ForLogin			NVARCHAR(128)
	, @SPIDState		VARCHAR(1)
	, @OmitLogin		NVARCHAR(128)
	, @ForDatabase		NVARCHAR(128)
	, @ReqOlderThanMin	INT;
 
-- Filters
SET @Confirm			= 0;	/* Just a precaution to make sure you've set the right filters before running this, switch to 1 to execute */
SET @ForLogin			= N'';	/* Only kill SPIDs belonging to this login, empty string = all logins */
SET @SPIDState			= '';	/* S = only kill sleeping SPIDs, R = only kill running SPIDs, empty string = kill SPIDs regardless of state*/
SET @OmitLogin			= N'';	/* Kill all SPIDs except the login name specified here, epty string = omit none */
SET @ForDatabase		= N'';	/* Kill only SPIDs hitting this database, empty string = all databases */
SET @ReqOlderThanMin	= 0;	/* Kill SPIDs whose last request start time is older than or equal to the value specified (in minutes),
									0 = the moment this query is executed*/
 
IF (@Confirm = 0)
BEGIN 
	PRINT '@Confirm is set 0. The script has exited without killing any sessions.'
	RETURN
END

DECLARE KillSPIDCursor CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY FOR

  SELECT DISTINCT [session_id]
  FROM   [master].[sys].[dm_exec_sessions]
  WHERE  [login_name] = CASE
                     /* Get all SPIDs */
                     WHEN @OmitLogin = N''
                          AND @ForLogin = N'' THEN
                       [login_name]
                     /* Get all SPIDs except for the ones belonging to @OmitLogin */
                     WHEN @OmitLogin <> N''
                          AND @ForLogin = N'' THEN
                       (SELECT DISTINCT [login_name]
                        FROM   [master].[sys].[dm_exec_sessions]
                        WHERE
                         [login_name] <> @OmitLogin)
                     /* Get all SPIDs belonging to a specific login */
                     WHEN @ForLogin <> N'' THEN
                       @ForLogin
                   END
    AND [session_id] <> @@SPID /* Exclude this SPID */
    AND [is_user_process] = 1 /* Target only non-system SPIDs */
    AND [database_id] = CASE
                          WHEN @ForDatabase <> N'' THEN
                            DB_ID(@ForDatabase)
                          ELSE [database_id]
                        END
    AND [login_name] NOT IN (SELECT [service_account]
                             FROM   [master].[sys].[dm_server_services]
                             WHERE
                              [status] = 4)
    AND [status] = CASE
                     WHEN @SPIDState = 'S' THEN
                       N'sleeping'
					 WHEN @SPIDState = 'R' THEN
					   N'running'
                     ELSE [status]
                   END
	AND [last_request_start_time] <= CASE
									   WHEN @ReqOlderThanMin = 0 THEN
										 GETDATE()
									   WHEN @ReqOlderThanMin > 0 THEN 
									     DATEADD(MINUTE,-@ReqOlderThanMin,GETDATE())
									 END;
OPEN KillSPIDCursor;
 
FETCH NEXT FROM KillSPIDCursor INTO @SPID;
 
WHILE @@FETCH_STATUS = 0
  BEGIN
      SET @ExecSQL = 'KILL ' + CAST(@SPID AS VARCHAR(5)) + ';';
      EXEC (@ExecSQL);
      FETCH NEXT FROM KillSPIDCursor INTO @SPID;
  END;
 
CLOSE KillSPIDCursor;
DEALLOCATE KillSPIDCursor;

