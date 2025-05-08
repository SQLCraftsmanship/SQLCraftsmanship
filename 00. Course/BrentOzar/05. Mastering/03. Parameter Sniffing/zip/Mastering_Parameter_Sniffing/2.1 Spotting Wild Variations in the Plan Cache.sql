/*
Mastering Parameter Sniffing
Spotting Wild Variations in the Plan Cache

v1.3 - 2022-06-12

https://www.BrentOzar.com/go/mastersniffing


This demo requires:
* SQL Server 2017 or newer
* 2018-06 Stack Overflow database: https://www.BrentOzar.com/go/querystack

This first RAISERROR is just to make sure you don't accidentally hit F5 and
run the entire script. You don't need to run this:
*/
RAISERROR(N'Oops! No, don''t just hit F5. Run these demos one at a time.', 20, 1) WITH LOG;
GO


/* Set the stage with the right server options & database config: */
USE StackOverflow;
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


/* Add a few indexes to let SQL Server choose.
   This can take 4-5 minutes. */
EXEC DropIndexes @TableName = 'Users', @ExceptIndexNames = 'Location';
EXEC DropIndexes @TableName = 'Posts', @ExceptIndexNames = 'CreationDate,_dta_index_Posts_5_85575343__K8,IX_OwnerUserId,OwnerUserId';
GO
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Users') AND name = 'Location')
	CREATE INDEX Location ON dbo.Users(Location);
GO
IF EXISTS(SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Posts') AND name = N'_dta_index_Posts_5_85575343__K8')
	EXEC sp_rename @objname = N'dbo.Posts._dta_index_Posts_5_85575343__K8', @newname = N'CreationDate', @objtype = N'INDEX';
GO
IF EXISTS(SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Posts') AND name = N'IX_OwnerUserId')
	EXEC sp_rename @objname = N'dbo.Posts.IX_OwnerUserId', @newname = N'OwnerUserId', @objtype = N'INDEX';
GO
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Posts') AND name = 'CreationDate')
	CREATE INDEX CreationDate ON dbo.Posts(CreationDate);
GO
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Posts') AND name = 'OwnerUserId')
	CREATE INDEX OwnerUserId ON dbo.Posts(OwnerUserId);
GO



/* Build our very sensitive proc: */
CREATE OR ALTER PROC dbo.usp_SearchPostsByLocation 
	@Location VARCHAR(100), @StartDate DATETIME, @EndDate DATETIME AS
BEGIN
/* Find the most recent posts from an area */
SELECT TOP 200 u.DisplayName, p.Title, p.Id, p.CreationDate
  FROM dbo.Posts p
  INNER JOIN dbo.Users u ON p.OwnerUserId = u.Id
  WHERE u.Location LIKE @Location
    AND p.CreationDate BETWEEN @StartDate AND @EndDate
  ORDER BY p.CreationDate DESC;
END
GO



/* 
As a reminder, these produce wildly different plans.
Note differences in:
	* Which table is processed first
	* Parallelism or single-threaded
	* Memory grant sizes
*/
DBCC FREEPROCCACHE;
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2008-01-01', @EndDate = '2014-01-01' WITH RECOMPILE; /* Big data, big dates */
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2009-01-01', @EndDate = '2009-02-01' WITH RECOMPILE; /* Big data, medium dates */
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01' WITH RECOMPILE; /* Big data, small dates */

EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2008-01-01', @EndDate = '2014-01-01' WITH RECOMPILE; /* Medium data, big dates */
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2009-01-01', @EndDate = '2009-02-01' WITH RECOMPILE; /* Medium data, medium dates */
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01' WITH RECOMPILE; /* Medium data, small dates */

EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2008-01-01', @EndDate = '2014-01-01' WITH RECOMPILE; /* Small data, big dates */
EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2009-01-01', @EndDate = '2009-02-01' WITH RECOMPILE; /* Small data, medium dates */
EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01' WITH RECOMPILE; /* Small data, small dates */

EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2008-01-01', @EndDate = '2014-01-01' WITH RECOMPILE; /* Outlier data, big dates */
EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2009-01-01', @EndDate = '2009-02-01' WITH RECOMPILE; /* Outlier data, medium dates */
EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01' WITH RECOMPILE; /* Outlier data, small dates */
GO
/* Note that when ALL of them are run with RECOMPILE, they finish in under 5 seconds. */




/* Let's put the tiny-data plan in memory, then run a few others: */
DBCC FREEPROCCACHE;
GO
EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Small data, small dates */
GO
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Medium data, medium dates */
GO
EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Outlier data, medium dates */
GO
EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Outlier data, big dates */
GO
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Big data, medium dates */
GO
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Big data, big dates */
GO
/* Run them all a few times, and then check the plan cache: */


SELECT * FROM sys.dm_exec_query_stats ORDER BY total_elapsed_time DESC;
/* Things to note:
* Plan_generation_num = 1 right now
* Executions
* Worker time: min/max/last
* Logical reads: min/max/last
* Elapsed time: min/max/last
* Total rows: min/max/last (bigger datasets will naturally take more time)
* DOP: min/max/last (total makes no sense here)
* Grant: min/max/last, used
* Spills: min/max/last

Make a note of the query_hash for later querying: 0xC3D39254FF662673

One disappointing thing to note: the contents of the plan are just the estimates. */
SELECT qp.query_plan, qs.*
  FROM sys.dm_exec_query_stats qs
  CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
  WHERE qs.query_hash = 0xC3D39254FF662673;
GO


/* Starting with SQL Server 2019, you can turn this on to cache (most of the)
last actual plan: */
ALTER DATABASE SCOPED CONFIGURATION SET LAST_QUERY_PLAN_STATS = ON;
GO
/* And run the query again: */
DBCC FREEPROCCACHE;
GO
EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Outlier data, big dates */
GO

/* The old-school plan cache still only has the estimates: */
SELECT qp.query_plan, qs.*
  FROM sys.dm_exec_query_stats qs
  CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
  WHERE qs.query_hash = 0xC3D39254FF662673;
GO

/* But there's a new function in town: */
SELECT qp.query_plan AS normally_cached_plan, qps.query_plan AS last_actual_plan, qs.*
  FROM sys.dm_exec_query_stats qs
  CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
  CROSS APPLY sys.dm_exec_query_plan_stats(qs.plan_handle) qps /* THIS ONE IS NEW IN 2019 */
  WHERE qs.query_hash = 0xC3D39254FF662673;
GO
/* The new one shows:
* Estimated rows vs actuals
* Some (but not all) info on spills
* The compiled (but not runtime) parameters

sp_BlitzCache shows this automatically by default:
*/
sp_BlitzCache;
GO


/* Rebuild an index on Users: */
ALTER INDEX Location ON dbo.Users REBUILD;
GO

/* Check the plan cache again: */
SELECT * FROM sys.dm_exec_query_stats WHERE query_hash = 0xC3D39254FF662673;


/* Note the # of executions, and plan_generation_num = 1.
The rebuild of the index didn't cause a new plan to be built - YET.



But run the stored proc again, and give it a different starting value: */
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Big data, big dates */


/* And then check the plan cache again: */
SELECT * FROM sys.dm_exec_query_stats WHERE query_hash = 0xC3D39254FF662673;
GO
/* Ruh roh - check:
* plan_generation_num
* All the performance metrics, like worker time min/max/last/total

We expose plan_generation_num at the far right:
*/
sp_BlitzCache;


/*
If we only have the current contents of sys.dm_exec_query_stats:

* The plan cache is useful for spotting wild 
  variations in CPU, reads, duration, etc.
* The plan cache only stores the current 
  estimated plan, not all the old ones
* 2019 adds the last actual plan, but only if 
  you opt into it, and it's not all actuals 
  (no spill page counts, runtime parameters)
* High plan_generation_num can mean you're 
  getting frequent compiles, but...
* Metrics reset, so you can't see how the 
  current plan fares vs historical
* In theory, you could look for wild variances 
  between min/max/total/avg/last,
  but there are risks with that, too.

Here's the code we use in sp_BlitzCache to trigger the parameter sniffing warning.
The defaults:
@parameter_sniffing_warning_pct = 30%
@parameter_sniffing_io_threshold = 100,000 logical reads
*/
parameter_sniffing = 
   CASE WHEN ExecutionCount > 3 AND AverageReads > @parameter_sniffing_io_threshold
            AND min_worker_time < ((1.0 - (@parameter_sniffing_warning_pct / 100.0)) * AverageCPU) THEN 1
        WHEN ExecutionCount > 3 AND AverageReads > @parameter_sniffing_io_threshold
            AND max_worker_time > ((1.0 + (@parameter_sniffing_warning_pct / 100.0)) * AverageCPU) THEN 1
        WHEN ExecutionCount > 3 AND AverageReads > @parameter_sniffing_io_threshold
            AND MinReturnedRows < ((1.0 - (@parameter_sniffing_warning_pct / 100.0)) * AverageReturnedRows) THEN 1
        WHEN ExecutionCount > 3 AND AverageReads > @parameter_sniffing_io_threshold
            AND MaxReturnedRows > ((1.0 + (@parameter_sniffing_warning_pct / 100.0)) * AverageReturnedRows) THEN 1 END ,
GO

/* Parameter sniffing happens when a NEW
plan is regenerated, and the OLD one is
flushed out of the cache.

So what we really need to do is store
the plan cache contents over time. */


/* I do this to clear out past instances of my monitoring tables only to make
it clear what's happening while I run my demos. If you're already logging
sp_BlitzFirst & friends to tables, you may not want to delete your existing
data.
DROP TABLE IF EXISTS DBAtools.dbo.BlitzFirst;
DROP TABLE IF EXISTS DBAtools.dbo.BlitzFirst_FileStats;
DROP TABLE IF EXISTS DBAtools.dbo.BlitzFirst_PerfmonStats;
DROP TABLE IF EXISTS DBAtools.dbo.BlitzFirst_WaitStats;
DROP TABLE IF EXISTS DBAtools.dbo.BlitzCache;
DROP TABLE IF EXISTS DBAtools.dbo.BlitzWho;
*/


/* Let's put the tiny-data plan in memory, 
then run a few others. This whole set will take ~60 seconds. */
DBCC FREEPROCCACHE;
GO
EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Small data, small dates */
GO 5
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Medium data, medium dates */
GO 5
EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Outlier data, medium dates */
GO 5
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Big data, medium dates */
GO 5
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Big data, big dates */
GO 5
/* This one is going to suck a little: he takes 3-5 seconds each time to run if the tiny-data plan goes in memory first. */
EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Outlier data, big dates */
GO 5





/* If you want to track plan cache changes over time, plus track root causes
for why the plan cache will clear out, you can run this every 15 minutes: */
EXEC dbo.sp_BlitzFirst 
  @OutputDatabaseName = 'DBAtools', 
  @OutputSchemaName = 'dbo', 
  @OutputTableName = 'BlitzFirst',
  @OutputTableNameFileStats = 'BlitzFirst_FileStats',
  @OutputTableNamePerfmonStats = 'BlitzFirst_PerfmonStats',
  @OutputTableNameWaitStats = 'BlitzFirst_WaitStats',
  @OutputTableNameBlitzCache = 'BlitzCache',
  @OutputTableNameBlitzWho = 'BlitzWho',
  @BlitzCacheSkipAnalysis = 0;
GO
/* When you call sp_BlitzFirst like this, it's really running:

sp_BlitzCache @SortOrder = 'all', @MinutesBack = 15;

Which logs all of these sort orders in dbo.BlitzCache:
* CPU
* Reads
* Duration
* Writes
* Spills
* Memory grant

And more. It's basically finding the top 10 queries by each of those sort
orders, so the most CPU-consuming, read-consuming, spill-producing, etc.

As a result, it's 50-100 queries (depending on how yours sort out) - it's not
the top 10 overall, but the top 10 for ALL of those sort methods.

For each one of those, you get its current plan and cumulative metrics.
(Not the metrics for the last 15 minutes - the total metrics.)
*/

/* Check the results: */
SELECT TOP 100 *
  FROM DBAtools.dbo.BlitzFirst
  ORDER BY CheckDate DESC, Priority ASC, FindingsGroup ASC, Finding ASC;
GO
SELECT TOP 100 *
  FROM DBAtools.dbo.BlitzCache
  ORDER BY CheckDate DESC, TotalCPU DESC;
GO
/* Things to note in dbo.BlitzCache:

* All numbers are cumulative since the last capture
* The only way to get Warnings (or anything else that involves parsing the XML)
  is to set @SkipAnalysis = 0, which takes more time for each execution
* If you set LAST_QUERY_PLAN_STATS = ON for a database, the QueryPlan column is
  the last actual plan - has est vs actual rows, rough spill info, and the
  compiled (but not runtime) parameters
*/


/* So if something happens, and the plan gets reset: */
ALTER INDEX Location ON dbo.Users REBUILD;
GO



/* And then run the proc again with a different starting value - 
this time, with the one that was suffering, so he gets a perfect plan: */
EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Outlier data, big dates */
GO 5

/* And try tiny data - he's quick: */
EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2008-01-01', @EndDate = '2014-01-01';
GO 5

/* But then run it for India, which won't do so well - 
   takes ~30 seconds just to run once: */
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Big data, big dates */
GO









/* Then when sp_BlitzFirst logs data to disk again: */
EXEC dbo.sp_BlitzFirst 
  @OutputDatabaseName = 'DBAtools', 
  @OutputSchemaName = 'dbo', 
  @OutputTableName = 'BlitzFirst',
  @OutputTableNameFileStats = 'BlitzFirst_FileStats',
  @OutputTableNamePerfmonStats = 'BlitzFirst_PerfmonStats',
  @OutputTableNameWaitStats = 'BlitzFirst_WaitStats',
  @OutputTableNameBlitzCache = 'BlitzCache',
  @OutputTableNameBlitzWho = 'BlitzWho',
  @BlitzCacheSkipAnalysis = 0;
GO




/* You'll be able to see the different plans for this query over time: */
SELECT * 
	FROM DBAtools.dbo.BlitzCache
	WHERE QueryHash = 0xC3D39254FF662673
	ORDER BY CheckDate DESC;
GO
/* You can use this table to find:
* Distinct query plans (note the QueryPlanHash column)
* Which parameters produced the plan (to build a set of testing params)
* Total & avg reads/CPU/duration/etc per plan

Here's an example query that will give you the top 10 queries 
that have burned the most CPU, and have multiple cached plans:
*/

WITH MultiplePlans AS (SELECT TOP 10 QueryHash,
	SUM(TotalCPU) AS TotalCPU
	FROM DBAtools.dbo.BlitzCache
	GROUP BY QueryHash
	HAVING COUNT(DISTINCT QueryPlanHash) > 1
	ORDER BY SUM(TotalCPU) DESC
)
SELECT mp.TotalCPU, mp.QueryHash, bc.*
FROM MultiplePlans mp
INNER JOIN DBAtools.dbo.BlitzCache bc ON mp.QueryHash = bc.QueryHash
ORDER BY 1 DESC, bc.CheckDate DESC;

/*
But you can't tell:
* Which parameters each plan sucks for
* Min/max numbers for each plan (because we're not logging it...yet)
* Warnings for the plan (because it takes too long to examine every 15 minutes)
* "Good" versions of the plan (because they may not be in the top ~50)
*/




/* We can augment our data a little if we happen to get lucky, and the data
collection happens at the same time as a long-running query.

Run this 30-second query in another window: */
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Big data, big dates */
GO



/* While you collect data with sp_BlitzFirst: */
EXEC dbo.sp_BlitzFirst 
  @OutputDatabaseName = 'DBAtools', 
  @OutputSchemaName = 'dbo', 
  @OutputTableName = 'BlitzFirst',
  @OutputTableNameFileStats = 'BlitzFirst_FileStats',
  @OutputTableNamePerfmonStats = 'BlitzFirst_PerfmonStats',
  @OutputTableNameWaitStats = 'BlitzFirst_WaitStats',
  @OutputTableNameBlitzCache = 'BlitzCache',
  @OutputTableNameBlitzWho = 'BlitzWho',
  @BlitzCacheSkipAnalysis = 0;
GO


/* For queries that happen to be running live, in SOME builds of
SQL Server, but not 2019 CU13 & newer, we get something amazing: 
check the live_query_plan column: */
SELECT *
	FROM DBAtools.dbo.BlitzWho;

/* Things to know:
* THIS HAS THE RUNTIME PARAMETERS W00T
* The plan and the metrics aren't the final metrics - they're the point-in-time when sp_BlitzWho runs
* This requires SQL Server 2016 SP1 or higher: https://www.brentozar.com/archive/2017/10/get-live-query-plans-sp_blitzwho/

This table also has the query hash, so you can filter just for one query:
*/
SELECT * 
	FROM DBAtools.dbo.BlitzWho
	WHERE query_hash = 0xC3D39254FF662673
	ORDER BY CheckDate DESC;
GO



/*
So the plan cache helps - but much more
so if you log it over time.

* Set up an Agent job to run sp_BlitzFirst 
  to table every 15 minutes, and it'll
  also run sp_BlitzCache, sp_BlitzWho

* The dbo.BlitzCache table has actual 
  metrics, estimated plan, and the compiled
  plan (but only compiled params, not runtime)

* For really terrible queries that happen
  to be running when sp_BlitzFirst's scheduled 
  job runs, the dbo.BlitzWho table adds the 
  runtime parameters, AND the current (but not 
  total) status of that plan, which can show 
  why those params suck for the current plan

* It's up to you to assemble this data into 
  a picture of the various plans and params 
  for a single stored procedure.
*/




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