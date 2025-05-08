/*
Fundamentals of Parameter Sniffing
What Triggers Parameter Sniffing Emergencies, Part 1

v1.2 - 2020-08-04

https://www.BrentOzar.com/go/snifffund


This demo requires:
* SQL Server 2016 or newer
* 50GB Stack Overflow 2013 database: https://www.BrentOzar.com/go/querystack

This first RAISERROR is just to make sure you don't accidentally hit F5 and
run the entire script. You don't need to run this:
*/
RAISERROR(N'Oops! No, don''t just hit F5. Run these demos one at a time.', 20, 1) WITH LOG;
GO


/* Set the stage with the right server options & database config: */
USE StackOverflow2013;
GO
DropIndexes;
GO
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 140; /* 2017, not 2019 yet */
GO
EXEC sys.sp_configure N'cost threshold for parallelism', N'50' /* Keep small queries serial */
GO
EXEC sys.sp_configure N'max degree of parallelism', N'4' /* Let queries go parallel */
GO
RECONFIGURE
GO
SET STATISTICS IO, TIME ON;
GO
CREATE INDEX IX_Reputation ON dbo.Users(Reputation)
GO
CREATE OR ALTER PROCEDURE dbo.usp_UsersByReputation
  @Reputation int
AS
SELECT TOP 10000 *
FROM dbo.Users
WHERE Reputation=@Reputation
ORDER BY DisplayName;
GO


/* These things cause the plan cache to be evicted:

* Restarting the operating system
* Restarting the SQL Server service
* Cluster failover
* AG failover (since we're now on a different plan cache)
* Database restore
* Running RECONFIGURE after changing some server-level options
* Changing some database-level options like MAXDOP

We'll demo the running queries, checking the plan cache, changing CTFP, and running RECONFIGURE.

* DBCC FREEPROCCACHE
* Altering the stored proc
* sp_recompile
* Rebuilding an index
* Updating statistics

We'll demo the above by looking at:

* sp_BlitzCache's plan cache history warning
* sp_Blitz's plan cache history warning
* sp_BlitzFirst's warning about stats being updated
* plan_generation_num in sys.dm_exec_query_stats

We'll talk through it and do the demos live.
*/


EXEC dbo.usp_UsersByReputation @Reputation =1;
GO
EXEC dbo.usp_UsersByReputation @Reputation =2;
GO

DBCC FREEPROCCACHE
GO
EXEC dbo.usp_UsersByReputation @Reputation =2;
GO
EXEC dbo.usp_UsersByReputation @Reputation =1;
GO
sp_BlitzCache
GO


DBCC FREEPROCCACHE
GO
EXEC dbo.usp_UsersByReputation @Reputation =1;
GO
EXEC dbo.usp_UsersByReputation @Reputation =1;
GO
EXEC dbo.usp_UsersByReputation @Reputation =1;
GO
SELECT execution_count, total_worker_time, total_elapsed_time, plan_generation_num
FROM sys.dm_exec_query_stats WHERE query_hash = 0xA6F28073109D7278;
GO

ALTER INDEX IX_Reputation ON dbo.Users REBUILD;
GO
SELECT execution_count, total_worker_time, total_elapsed_time, plan_generation_num
FROM sys.dm_exec_query_stats WHERE query_hash = 0xA6F28073109D7278;
GO
EXEC dbo.usp_UsersByReputation @Reputation = 2;
GO
SELECT execution_count, total_worker_time, total_elapsed_time, plan_generation_num
FROM sys.dm_exec_query_stats WHERE query_hash = 0xA6F28073109D7278;




/*
License: Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
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
*/