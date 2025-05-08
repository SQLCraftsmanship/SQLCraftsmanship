/*
Fundamentals of TempDB: Other TempDB Consumers
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


/* Cursors are kinda like temp tables. Depending
on your cursor options, SQL Server may need to
store a copy of the data you're working with: */
DECLARE MyCursor CURSOR STATIC FOR
	SELECT Id FROM dbo.Users;

/* Note how this takes time: it's copying data to TempDB. */
OPEN MyCursor;

/* Not a lot, though, because we're just getting IDs: */
SELECT user_objects_alloc_page_count * 8.0 / 1024 AS user_objects_mb,
	internal_objects_alloc_page_count * 8.0 / 1024 AS internal_objects_mb
FROM sys.dm_db_session_space_usage
WHERE session_id = @@SPID;

/* Shut 'er down: */
CLOSE MyCursor;
DEALLOCATE MyCursor;
GO


/* Try SELECT *: */
DECLARE MyCursor CURSOR STATIC FOR
	SELECT * FROM dbo.Users;

/* The slow part, reading & copying to TempDB: */
OPEN MyCursor;

/* How much space did we use this time? */
SELECT user_objects_alloc_page_count * 8.0 / 1024 AS user_objects_mb,
	internal_objects_alloc_page_count * 8.0 / 1024 AS internal_objects_mb
FROM sys.dm_db_session_space_usage
WHERE session_id = @@SPID;

/* Shut 'er down: */
CLOSE MyCursor;
DEALLOCATE MyCursor;
GO


/* The lesson with cursors:
* Get as few rows as practical
* Get as few columns as practical
* The more you get, the more TempDB space you take

If your workloads are heavily reliant on cursors,
check out this post on how to minimize their impact:
https://sqlperformance.com/2012/09/t-sql-queries/cursor-options
*/







/* Sorting an index is also kinda like a temp table.
Get the estimated plans for these two: */
ALTER INDEX PK_Users_Id ON dbo.Users REBUILD;
ALTER INDEX PK_Users_Id ON dbo.Users REBUILD
	WITH (SORT_IN_TEMPDB = ON);

/* Well, that's not very helpful. */
BEGIN TRAN
ALTER INDEX PK_Users_Id ON dbo.Users REBUILD
	WITH (SORT_IN_TEMPDB = ON);

/* How much space are we taking up? */
SELECT user_objects_alloc_page_count * 8.0 / 1024 AS user_objects_mb, 
	internal_objects_alloc_page_count * 8.0 / 1024 AS internal_objects_mb 
FROM sys.dm_db_session_space_usage 
WHERE session_id = @@SPID;

/* Save our work: */
COMMIT
GO

/* Here's the really cool trick though:
Just because SQL Server is storing data in TempDB
doesn't mean it's actually writing to disk!

Remember, TempDB's been caching stuff in memory
rather than writing it to disk for years:
https://www.brentozar.com/archive/2014/04/memory-ssd-tempdb-temp-table-sql-2014/

So try each of these separately, one at a time: */
ALTER INDEX PK_Users_Id ON dbo.Users REBUILD;
ALTER INDEX PK_Users_Id ON dbo.Users REBUILD
	WITH (SORT_IN_TEMPDB = ON);

/* While you monitor this in another window: */
sp_BlitzFirst @ExpertMode = 1, @Seconds = 10;


/* So use the SORT_IN_TEMPDB option if:

* Your TempDB is on much faster storage than
  your user databases, or

* You want the less-eager-writes enhancement
  (because TempDB pages don't go to disk as
  quickly as user databases have to)

But just keep in mind that if you're building or
rebuilding large indexes in TempDB, and if you're
under memory pressure, then you're going to
actually need that space available in TempDB. */





/* Alright, next up: what else uses TempDB?
Let's make the database read-only: */
DropIndexes;
GO
USE [master]
GO
ALTER DATABASE [StackOverflow2013] SET READ_ONLY WITH NO_WAIT
GO
USE StackOverflow2013;
GO
/* Look at the statistics on the dbo.Users table.
We have stats on the Id column, but that's it:*/
SELECT * FROM sys.stats WHERE object_id = OBJECT_ID('dbo.Users');
EXEC sp_BlitzIndex @TableName = 'Users';

/* Run a query that needs stats on DisplayName,
and look at the actual plan to see the estimates: */
SELECT *
FROM dbo.Users
WHERE DisplayName = N'Brent Ozar'
ORDER BY Reputation DESC;


/* How did it come up with those estimates? */
SELECT * FROM sys.stats WHERE object_id = OBJECT_ID('dbo.Users');
/* Make a note of that object_id. */


/* Because the database is read-only, those stats
are actually created in TempDB. */
USE tempdb;
GO
SELECT * FROM sys.stats
WHERE object_id = 149575571
AND name LIKE '%readonly%';
GO

/* Takeaway: when you query one of these:
* Read-only databases
* Snapshots
* Availability Group readable replicas

Then SQL Server is going to need to make stats
based on your queries, and because those
databases aren't writable, the stats get created
in TempDB. The good news is that this is a really
lightweight TempDB consumer, but...

This is very tricky because:

* Every server will have different stats depending
  on when they're updated, and their sampling rate

* Every server's stats will get erased when the
  SQL Server restarts

So you can have a query that's:

* Fast on one replica, and slow on another

* Or slow on two replicas, for two different reasons

More info on these:
https://docs.microsoft.com/en-us/archive/blogs/sqlserverstorageengine/alwayson-making-latest-statistics-available-on-readable-secondary-read-only-database-and-database-snapshot
https://docs.microsoft.com/en-us/sql/database-engine/availability-groups/windows/active-secondaries-readable-secondary-replicas-always-on-availability-groups#Read-OnlyStats
http://www.nikoport.com/2019/06/20/updating-statistics-on-secondary-replicas-of-the-availability-groups/

Set it back to read-write:
*/
USE [master]
GO
ALTER DATABASE [StackOverflow2013] SET READ_WRITE WITH NO_WAIT
GO


/* During the break, check your production SQL
Servers to see sessions are using TempDB: 
*/
SELECT DB_NAME(database_id), session_id, 
	user_objects_alloc_page_count * 8.0 / 1024 AS user_objects_mb, 
	internal_objects_alloc_page_count * 8.0 / 1024 AS internal_objects_mb
FROM sys.dm_db_session_space_usage 
WHERE user_objects_alloc_page_count <> 0 OR internal_objects_alloc_page_count <> 0
ORDER BY (user_objects_alloc_page_count + internal_objects_alloc_page_count) DESC;

/* Then check:
* If you have read-only databases that people query
* Whether your index maintenance jobs are using
  SORT_IN_TEMPDB = ON
*/



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