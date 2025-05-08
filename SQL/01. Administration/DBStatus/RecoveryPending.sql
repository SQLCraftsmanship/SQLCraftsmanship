
/*****************************************************************************************************************************************************************
SQL Server Database States

If a single or multiple core files cannot be accessed in SQL Server, it means that the SQL Server database is corrupted. According to the degree of damage in the
database, there are different states of SQL Server Database that indicate different issues. Some of the states are listed below:

Online			: If a single file is damaged or corrupted and cannot be accessed, the database remains available and online.
Suspect			: If the transaction log file is damaged and the recovery is prevented or the transaction is prevented from being rolled back, the SQL database 
				  will fail.
Recovery Pending: When the SQL server knows that the database needs to be restored but there is an obstacle before starting. This status differs from the suspect
				  mode because it cannot be declared that the database restore has failed but the process has not yet started.

Know the Reasons for SQL Server Recovery Pending State
Before moving to the solution, you need to know the reasons behind the SQL database in recovery pending state. Some of the main reasons are explained below:

	1. The database is not shutting down properly, which means that at least one uncommitted transaction is active at the time the database is shutdown, 
	   and the log file for it has been deleted. 
	2. Due to insufficient space or hard disk space, the SQL database recovery cannot be started. 
	3. If the primary database files are corrupted then the user may also face this problem. 
	4. The user tried to move the log files to a new drive to resolve server performance issues. But, the log files were damaged.

Reference
https://www.sqlserverlogexplorer.com/free-manual-ways-fix-sql-server-recovery-pending-state/
*****************************************************************************************************************************************************************/

------------------------------------------------------------------------------------------------
-- Option 1
------------------------------------------------------------------------------------------------
ALTER DATABASE [DBName] SET EMERGENCY;
GO
ALTER DATABASE [DBName] set single_user
GO
DBCC CHECKDB ([DBName], REPAIR_ALLOW_DATA_LOSS) WITH ALL_ERRORMSGS;
GO
ALTER DATABASE [DBName] set multi_user
GO

------------------------------------------------------------------------------------------------
-- Option 2
------------------------------------------------------------------------------------------------
ALTER DATABASE [DBName] SET EMERGENCY;
GO
ALTER DATABASE [DBName] set multi_user;
GO
EXEC sp_detach_db '[DBName]';
GO
EXEC sp_attach_single_file_db @DBName = '[DBName]', @physname = N'[mdf path]';
GO
