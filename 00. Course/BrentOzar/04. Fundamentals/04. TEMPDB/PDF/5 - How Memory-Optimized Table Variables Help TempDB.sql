/*
Fundamentals of TempDB: How Memory-Optimized Table Variables Help TempDB
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
USE StackOverflow2013;
GO




/* Earlier, we ran a load test with this: */
CREATE OR ALTER PROCEDURE dbo.TableVariable AS
BEGIN
	DECLARE @TableVariable TABLE (Id INT, AboutMe NVARCHAR(MAX));

	INSERT INTO @TableVariable (Id, AboutMe)
	SELECT TOP 1000 Id, AboutMe
	FROM dbo.Users WITH (NOLOCK)
	OPTION (MAXDOP 1);
END
GO
/* And we still ran into page latch waits.

SQL Server 2014 introduced In-Memory OLTP, which
didn't catch on too much, but it also came with
the table variables built with In-Memory OLTP.

They do have a lot of drawbacks, though:
	* We have to enable In-Memory OLTP on the db
	* We have to create a table type ahead of time
	* They only use memory, not disk
	  (which means they add memory pressure)

We'll start by setting up In-Memory OLTP: */
ALTER DATABASE StackOverflow2013
	ADD FILEGROUP [InMemoryOLTP] CONTAINS MEMORY_OPTIMIZED_DATA
GO
ALTER DATABASE StackOverflow2013 
	ADD FILE (name='InMemoryOLTP', filename='M:\MSSQL\DATA\InMemoryOLTP')
	TO FILEGROUP [InMemoryOLTP];
GO
ALTER DATABASE StackOverflow2013 
	SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT ON;
GO

/* Create the table type: */
CREATE TYPE TempUsers AS TABLE
	(Id INT PRIMARY KEY NONCLUSTERED, 
	 AboutMe NVARCHAR(MAX))
	WITH (MEMORY_OPTIMIZED = ON);
GO

/* Now we can use that table type in our proc: */
CREATE OR ALTER PROCEDURE dbo.InMemory AS
BEGIN
	/* Instead of creating the table, we use the type: */
	DECLARE @InMemoryOLTP TempUsers;

	INSERT INTO @InMemoryOLTP (Id, AboutMe)
	SELECT TOP 1000 Id, AboutMe
	FROM dbo.Users WITH (NOLOCK)
	OPTION (MAXDOP 1);
END
GO


/* Try just one with actual plan on: */
SET STATISTICS TIME, IO ON;
GO
EXEC InMemory;
/* No memory grant, no logical writes. */

/* Turn OFF actual plans, run it in SQLQueryStress on a lot of threads. */
EXEC sp_BlitzFirst @ExpertMode = 1, @Seconds = 60;
EXEC sp_WhoIsActive;
SELECT * FROM sys.dm_os_memory_clerks ORDER BY pages_kb DESC;

/* Check for compilations: */
EXEC dbo.sp_HumanEvents @event_type = 'recompilations', @seconds_sample = 10

/* Check the plan cache: */
DBCC FREEPROCCACHE;
GO
EXEC InMemory;
GO 10
sp_BlitzCache;
GO

/* The good news:

* There are no page latch waits
* There are XTP (Extreme Transaction Processing) waits
  (aka In-Memory OLTP, aka Hekaton)
* There are no compilations
* It does show up in the plan cache (but not memory used)
* This does alleviate the pressure from TempDB

The bad news:

* We have to declare the table type ahead of time
* It's not flexible: you can't just add a column
* They work fine for small amounts of data used by
  fast, short queries, but not as well for big
  data and long-running queries

To see what I mean by that last one, let's stuff
millions of rows into that object:
*/
CREATE OR ALTER PROCEDURE dbo.InMemory_AllRows AS
BEGIN
	DECLARE @InMemoryOLTP TempUsers;

	/* Insert ALL the rows, no TOP 1000 */
	INSERT INTO @InMemoryOLTP (Id, AboutMe)
	SELECT Id, AboutMe
	FROM dbo.Users WITH (NOLOCK);

	WAITFOR DELAY '00:00:30';
END
GO

/* Turn on actual plans: */
EXEC InMemory_AllRows;

/* And while it runs, in another window: */
sp_Blitz;
sp_WhoIsActive;
SELECT * FROM sys.dm_os_memory_clerks ORDER BY pages_kb DESC;
GO

/* Yeah, that would be bad in production.

To mitigate that, you can use Resource Governor
to cap the amount of memory used by In-Memory OLTP:
https://docs.microsoft.com/en-us/sql/relational-databases/in-memory-oltp/bind-a-database-with-memory-optimized-tables-to-a-resource-pool


So my verdict on memory optimized table variables:

* If you can't fix GAM/SGAM/PFS contention or
  recompilations any other way, and
* If it's caused by queries using a relatively
  small amount of data, and
* If estimates don't matter (because like table
  variables, these don't have statistics), and
* It's a relatively small number of procs
  (because you have to create user-defined table
  types ahead of time for them, plus edit the
  procs to point to the new table types), and
* You're on Enterprise Edition (because you need
  Resource Governor)

Then it makes sense. Just set up Resource Governor.


Restore your Stack Overflow database if you want
to reset without In-Memory OLTP being enabled, and
it's probably a good idea to restart your server.

During the break, check your own production server
to see if any databases have in-memory OLTP turned
on, and if so, do they have any table types:
*/
sp_BlitzInMemoryOLTP @dbName = N'ALL'
GO



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