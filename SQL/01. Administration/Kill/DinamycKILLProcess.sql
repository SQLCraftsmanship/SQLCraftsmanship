
/***********************************************************************************************************************************
Dynamic Kill Process with CURSOR and SYSPROCESSES
	Ref
	https://blog.sqlauthority.com/2019/05/06/sql-server-script-to-kill-all-inactive-sessions-kill-sleeping-sessions-from-sp_who2/

Create object
	USE [AdventureWorks2019]
	GO

	IF EXISTS (SELECT Name FROM sys.tables WHERE Name = 'dba_KillProcess')
		DROP TABLE [dbo].[dba_KillProcess]
	GO

	CREATE TABLE [dbo].[dba_KillProcess]
	(
		  [user_spid]	 SMALLINT
		, [dbid]		 SMALLINT
		, [status]		 NCHAR(30)
		, [hostname]     NCHAR(128)
		, [program_name] NCHAR(128)
		, [nt_username]  NCHAR(128)
		, [loginame]     NCHAR(128)
	)

	SELECT * FROM [dbo].[dba_KillProcess]

Example
	
	Demo 
		USE [AdventureWorks2019]
		GO
		truncate table [dbo].[tblSQLDemoKillProcess]
		DROP TABLE [dbo].[tblSQLDemoKillProcess]

		CREATE TABLE [dbo].[tblSQLDemoKillProcess]
		(
			[S.No.] [int] IDENTITY(0,1) NOT NULL,
			[value] [uniqueidentifier]      NULL,
			[Date]  [datetime]			    NULL
		) ON [PRIMARY]
		GO
    
		ALTER TABLE [dbo].[tblSQLDemoKillProcess] ADD DEFAULT (GETDATE()) FOR [Date]
		GO

		SELECT * FROM [dbo].[tblSQLDemoKillProcess]

		BEGIN TRANSACTION
		DECLARE @Id int
		SET @Id = 1
     
		WHILE @Id <= 1000000
		BEGIN 
		   INSERT INTO [dbo].[tblSQLDemoKillProcess](value) VALUES(NEWID())
		   SET @Id = @Id + 1
		END

	
	How to execute
		EXEC [dbo].[DynamicKillProcess] 12
***********************************************************************************************************************************/
USE [master]
GO

IF EXISTS (SELECT Name FROM MASTER.SYS.PROCEDURES WHERE Name = 'DynamicKillProcess')
	DROP PROC[dbo].[DynamicKillProcess]
GO

CREATE PROC [dbo].[DynamicKillProcess] (@TimeRunning INT)
AS
BEGIN

    -- Check value in var @TimeRunning
	IF (@TimeRunning = '' OR @TimeRunning = 0 or @TimeRunning IS NULL)
		SET @TimeRunning  = 12

	-- Declare var to use un cursor
    DECLARE @user_spid  SMALLINT, @dbid SMALLINT
	DECLARE @status		NCHAR(30)
	DECLARE @hostname   NCHAR(128), @program_name NCHAR(128), @nt_username NCHAR(128), @loginame NCHAR(128)

    -- FAST_FORWARD: This type of cursor does not allow data modifications from inside the cursor.
    DECLARE CurSPID CURSOR FAST_FORWARD
    FOR
        SELECT SPID, dbid, status, hostname, program_name, nt_username, loginame
        FROM MASTER.DBO.SYSPROCESSES (NOLOCK)
        WHERE spid   > 50			-- avoid system   threads
        AND   status = 'sleeping'	-- only  sleeping threads
        AND   DATEDIFF(HOUR, last_batch, GETDATE()) >= 12 -- thread sleeping for XX hours
        -- AND DATEDIFF(mi,last_batch,GETDATE())>=60 -- in minutes (es un monton)
        AND   spid <> @@spid        -- ignore current spid

    OPEN CurSPID
    FETCH NEXT FROM CurSPID INTO @user_spid, @dbid, @status, @hostname, @program_name, @nt_username, @loginame
    WHILE (@@FETCH_STATUS=0)
    BEGIN
        -- PRINT 'Killing ' + CONVERT(VARCHAR, @user_spid)
		-- Insert in table, to know wich spid we are going to kill
		INSERT INTO [AdventureWorks2019].[dbo].[dba_KillProcess]([user_spid], [dbid], [status], [hostname], [program_name], [nt_username], [loginame])
		VALUES(@user_spid, @dbid, @status, @hostname, @program_name, @nt_username, @loginame)

        EXEC('KILL ' + @user_spid)
        FETCH NEXT FROM CurSPID INTO @user_spid
    END

    CLOSE CurSPID
    DEALLOCATE CurSPID
    
END
