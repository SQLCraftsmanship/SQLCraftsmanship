/*
Fundamentals of TempDB: How Temp Tables Affect TempDB, Part 2: Many Queries at Once
v1.0 - 2020-12-06
https://www.BrentOzar.com/go/tempdbfun


This demo requires:
* SQL Server 2016 or newer
* Any Stack Overflow database: https://www.BrentOzar.com/go/querystack

This first RAISERROR is just to make sure you don't accidentally hit F5 and
run the entire script. You don't need to run this:
*/
RAISERROR(N'Oops! No, don''t just hit F5. Run these demos one at a time.', 20, 1) WITH LOG;
GO

/* If you're on SQL Server 2019, check to make
sure this returns a 0: */
SELECT SERVERPROPERTY('IsTempDBMetadataMemoryOptimized');
GO
/* If it returns a 1, let's turn this feature off
for now in order to demo SQL Server's traditional
problem in TempDB: */
ALTER SERVER CONFIGURATION SET MEMORY_OPTIMIZED TEMPDB_METADATA=OFF;
/* And you'll then need to restart SQL Server. */


/* Before we start, review the number of files
we've got in TempDB: */
SELECT type_desc, name, physical_name, 
	size * 8.0 / 1024 AS size_mb
	FROM tempdb.sys.database_files
	ORDER BY type_desc DESC;


USE StackOverflow2013;
GO
CREATE OR ALTER PROCEDURE dbo.TempTable AS
	SELECT TOP 1000 Id, AboutMe
	INTO #t1
	FROM dbo.Users WITH (NOLOCK)
	OPTION (MAXDOP 1);
GO

/* When you run just one, it's quick: */
SET STATISTICS TIME, IO ON;
GO
EXEC TempTable;

/* But run that in SQLQueryStress on a lot of 
threads while we measure: */
EXEC sp_BlitzFirst @ExpertMode = 1, @Seconds = 60;
EXEC sp_WhoIsActive;
GO




/* What if we try table variables? */
CREATE OR ALTER PROCEDURE dbo.TableVariable AS
BEGIN
	DECLARE @TableVariable TABLE (Id INT, AboutMe NVARCHAR(MAX));

	INSERT INTO @TableVariable (Id, AboutMe)
	SELECT TOP 1000 Id, AboutMe
	FROM dbo.Users WITH (NOLOCK)
	OPTION (MAXDOP 1);
END
GO


/* Try just one: */
SET STATISTICS TIME, IO ON;
GO
EXEC TableVariable;

/* Then run it in SQLQueryStress on a lot of threads. */
EXEC sp_BlitzFirst @ExpertMode = 1, @Seconds = 60;
EXEC sp_WhoIsActive;
GO


/* SQL Server 2019 brings a new system-level
feature to help solve this: */
ALTER SERVER CONFIGURATION SET MEMORY_OPTIMIZED TEMPDB_METADATA=ON;
/* Restart the SQL Server instance for it to take
effect, then check it: */
SELECT SERVERPROPERTY('IsTempDBMetadataMemoryOptimized');
GO

/* Then run both the TempTable and TableVariable
load tests again while watching page latch waits. */
EXEC sp_BlitzFirst @ExpertMode = 1, @Seconds = 60;
EXEC sp_WhoIsActive;
GO


/* Turn this back off for the lab: */
ALTER SERVER CONFIGURATION SET MEMORY_OPTIMIZED TEMPDB_METADATA=OFF;
/* Restart the SQL Server instance for it to take
effect, then check it: */
SELECT SERVERPROPERTY('IsTempDBMetadataMemoryOptimized');
GO

/* During the break, check your production servers
to see how many files they have: */
SELECT type_desc, name, physical_name, 
	size * 8.0 / 1024 AS size_mb
	FROM tempdb.sys.database_files
	ORDER BY type_desc DESC;
GO
/* And look for PAGELATCH waits amongst your top 10,
indicating that you may need more files (or a
code change): */
sp_BlitzFirst @OutputType = 'Top10'

/* Not PAGEIOLATCH% or LATCH% - we're specifically
looking for PAGELATCH%. */


/*
License: Creative Commons Attribution-ShareAlike 4.0 Unported (CC BY-SA 4.0)
More info: https://creativecommons.org/licenses/by-sa/4.0/

You are free to:
* Share - copy and redistribute the material in any medium or format
* Adapt - remix, transform, and build upon the material for any purpose, even 
  commercially

Under the following terms:
* Attribution - You must give appropriate credit, provide a link to the license, 
  and indicate if changes were made. You may do so in any reasonable manner, 
  but not in any way that suggests the licensor endorses you or your use.
* ShareAlike - If you remix, transform, or build upon the material, you must
  distribute your contributions under the same license as the original.
* No additional restrictions — You may not apply legal terms or technological 
  measures that legally restrict others from doing anything the license permits.
*/