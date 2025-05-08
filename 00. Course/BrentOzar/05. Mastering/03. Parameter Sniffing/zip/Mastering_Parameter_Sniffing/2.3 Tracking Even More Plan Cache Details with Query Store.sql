/*
Mastering Parameter Sniffing
Tracking Even More Plan Cache Details with Query Store

v1.4 - 2022-06-12

https://www.BrentOzar.com/go/mastersniffing


This demo requires:
* SQL Server 2017 or newer
* 2018-06 Stack Overflow database: https://www.BrentOzar.com/go/querystack

This first RAISERROR is just to make sure you don't accidentally hit F5 and
run the entire script. You don't need to run this:
*/
RAISERROR(N'Oops! No, don''t just hit F5. Run these demos one at a time.', 20, 1) WITH LOG;
GO




/* Set the stage with the right server options & database config.
If you already did this in the last module, you can keep it as-is:
it's the exact same indexes & proc we used in the last module. */
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



/* 
Logging the plan cache gets you enough data to
to troubleshoot a lot of sniffing, but:

* Some queries have RECOMPILE hints
* Some servers get so much memory pressure that the plan cache is worthless
* Some shops can't install third party scripts

So starting with SQL Server 2016, Query Store is 
a built-in option that logs the plan cache to disk.
It logs the data into the user database itself.
*/


/* Build our very sensitive proc, AND say 
someone "fixed" it with a recompile hint: */
CREATE OR ALTER PROC dbo.usp_SearchPostsByLocation_Recompile_OUTside
	@Location VARCHAR(100), @StartDate DATETIME, @EndDate DATETIME WITH RECOMPILE AS
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


/* Free the plan cache just to make monitoring easier, then run a few variations - note no recompile hint here: */
DBCC FREEPROCCACHE
GO
EXEC usp_SearchPostsByLocation_Recompile_OUTside 'Willemstad, Curaçao', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Outlier data, big dates */
GO
EXEC usp_SearchPostsByLocation_Recompile_OUTside 'Near Stonehenge', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Tiny data */
GO
EXEC usp_SearchPostsByLocation_Recompile_OUTside 'India', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Big data, big dates */
GO


/* Look in the plan cache: */
SELECT * FROM sys.dm_exec_query_stats;
GO
sp_BlitzCache;
GO



/* Putting WITH RECOMPILE on the OUTSIDE 
of a stored procedure is TERRIBLE.
(Unless you want to hide it from monitoring.)


This is where SQL Server 2016 & newer's Query Store comes in handy. It can:

* Catch every execution of a query, including compilation hints
* Catch queries 24/7, not just every 15 minutes
* Write the data into the user database itself
* Clean out its own history based on your settings

Let's look at the GUI, and then I'm going to enable it with these settings,
BUT ONLY FOR DEMO PURPOSES. YOU SHOULD NEVER LOG EVERY MINUTE.
*/
ALTER DATABASE [StackOverflow] SET QUERY_STORE = ON
GO
ALTER DATABASE [StackOverflow] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, DATA_FLUSH_INTERVAL_SECONDS = 60, INTERVAL_LENGTH_MINUTES = 1)
GO
/* In case we need to clear it out during a demo: 
ALTER DATABASE [StackOverflow] SET QUERY_STORE CLEAR;
*/

/* Then run a bunch of our terrible outside queries that would usually disappear: */
EXEC usp_SearchPostsByLocation_Recompile_OUTside 'India', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Big data, big dates */
EXEC usp_SearchPostsByLocation_Recompile_OUTside 'India', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Big data, medium dates */
EXEC usp_SearchPostsByLocation_Recompile_OUTside 'India', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Big data, small dates */
EXEC usp_SearchPostsByLocation_Recompile_OUTside 'Near Stonehenge', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Small data, big dates */
EXEC usp_SearchPostsByLocation_Recompile_OUTside 'Near Stonehenge', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Small data, medium dates */
EXEC usp_SearchPostsByLocation_Recompile_OUTside 'Near Stonehenge', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Small data, small dates */
EXEC usp_SearchPostsByLocation_Recompile_OUTside 'Willemstad, Curaçao', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Outlier data, big dates */
EXEC usp_SearchPostsByLocation_Recompile_OUTside 'Willemstad, Curaçao', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Outlier data, medium dates */
EXEC usp_SearchPostsByLocation_Recompile_OUTside 'Willemstad, Curaçao', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Outlier data, small dates */
EXEC usp_SearchPostsByLocation_Recompile_OUTside 'Netherlands', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Medium data, big dates */
EXEC usp_SearchPostsByLocation_Recompile_OUTside 'Netherlands', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Medium data, medium dates */
EXEC usp_SearchPostsByLocation_Recompile_OUTside 'Netherlands', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Medium data, small dates */
GO 10


/* Take a short look at where the data is being stored, and the kind of data we get: */
SELECT * FROM sys.query_store_query;
SELECT * FROM sys.query_store_runtime_stats;
GO

/* Go into the Query Store GUI, and walk through the reports:

* Queries With High Variations
* Top Resource Consuming Queries

Note that for each plan - even recompiled plans - we get the parameters!

Pick one of the plans, and force it. Then try to run the queries again:
*/
EXEC usp_SearchPostsByLocation_Recompile_OUTside 'India', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Big data, big dates */
EXEC usp_SearchPostsByLocation_Recompile_OUTside 'India', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Big data, medium dates */
EXEC usp_SearchPostsByLocation_Recompile_OUTside 'India', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Big data, small dates */
EXEC usp_SearchPostsByLocation_Recompile_OUTside 'Near Stonehenge', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Small data, big dates */
EXEC usp_SearchPostsByLocation_Recompile_OUTside 'Near Stonehenge', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Small data, medium dates */
EXEC usp_SearchPostsByLocation_Recompile_OUTside 'Near Stonehenge', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Small data, small dates */
EXEC usp_SearchPostsByLocation_Recompile_OUTside 'Willemstad, Curaçao', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Outlier data, big dates */
EXEC usp_SearchPostsByLocation_Recompile_OUTside 'Willemstad, Curaçao', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Outlier data, medium dates */
EXEC usp_SearchPostsByLocation_Recompile_OUTside 'Willemstad, Curaçao', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Outlier data, small dates */
EXEC usp_SearchPostsByLocation_Recompile_OUTside 'Netherlands', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Medium data, big dates */
EXEC usp_SearchPostsByLocation_Recompile_OUTside 'Netherlands', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Medium data, medium dates */
EXEC usp_SearchPostsByLocation_Recompile_OUTside 'Netherlands', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Medium data, small dates */
GO 10


/* The good news is that forcing a plan overrides the recompile hint!

The bad news is that one plan may not be good for everyone.

But that's not Query Store's fault: the problem is that there isn't one good
plan that makes all of these go fast - yet, at least. That's where you will
have your work cut out for you tomorrow.



Go unforce that plan for now.


I don't actually like the GUI for this - I much prefer sp_BlitzQueryStore:
*/
/* Get the top 10: */
EXEC sp_BlitzQueryStore @DatabaseName = 'StackOverflow', @Top = 10

/* Minimum execution count, duration filter (seconds) */
EXEC sp_BlitzQueryStore @DatabaseName = 'StackOverflow', 
@Top = 10, @MinimumExecutionCount = 10, @DurationFilter = 2

/* Look for a stored procedure by name, get its params quickly */
EXEC sp_BlitzQueryStore @DatabaseName = 'StackOverflow', 
	@Top = 10, @SkipXML = 1,
	@StoredProcName = 'usp_SearchPostsByLocation_Recompile_OUTside'

/* Filter for a date range: */
EXEC sp_BlitzQueryStore @DatabaseName = 'StackOverflow', 
@Top = 10, @StartDate = '20200530', @EndDate = '20200605'
GO


/* You may also be able to query for
all parameters that have been used
for a few query plan hashes */
;WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS p), [raw_data] AS (
	SELECT [p].[plan_id],
		[p].[query_plan_hash],
		CONVERT(XML, p.query_plan) AS [query_plan]
	FROM StackOverflow.sys.query_store_plan AS [p]
		INNER JOIN StackOverflow.sys.query_store_runtime_stats AS [rs] ON [p].[plan_id] = [rs].[plan_id]
	WHERE [p].[query_plan_hash] IN (0xA6B47452A5D7511F, 0xC0DC86703A611840)
)
SELECT DISTINCT [plan_id],
	[query_plan_hash],
	-- [query_plan],
	n.x.value('@Column', 'varchar(128)') + ' = ' + n.x.value('@ParameterCompiledValue', 'varchar(128)') [parameter]
FROM [raw_data]
	CROSS APPLY [query_plan].nodes('//p:ParameterList/p:ColumnReference') AS n(x)
ORDER BY [plan_id], [parameter];
GO




/* Query Store does have a performance overhead. The more queries that it has
to examine, the higher the overhead will be. The worst case scenario is a
workload whose queries constantly change, like unparameterized dynamic SQL.

Here's the example from Fundamentals of Parameter Sniffing:
*/
CREATE OR ALTER PROC dbo.usp_GetUser @UserId INT = NULL, @DisplayName NVARCHAR(40) = NULL, @Location NVARCHAR(100) = NULL AS
BEGIN
/* They have to ask for either a UserId or a DisplayName or a Location: */
IF @UserId IS NULL AND @DisplayName IS NULL AND @Location IS NULL
	RETURN;

DECLARE @StringToExecute NVARCHAR(4000);
SET @StringToExecute = N'SELECT * FROM dbo.Users WHERE 1 = 1 ';

IF @UserId IS NOT NULL
	SET @StringToExecute = @StringToExecute + N' AND Id = ' + CAST(@UserId AS NVARCHAR(10));

IF @DisplayName IS NOT NULL
	SET @StringToExecute = @StringToExecute + N' AND DisplayName = ''' + @DisplayName + N'''';

IF @Location IS NOT NULL
	SET @StringToExecute = @StringToExecute + N' AND Location = ''' + @Location + N'''';

EXEC sp_executesql @StringToExecute;
END
GO


CREATE OR ALTER PROC [dbo].[usp_DynamicSQLLab] WITH RECOMPILE AS
BEGIN
	/* Hi! You can ignore this stored procedure.
	   This is used to run different random stored procs as part of your class.
	   Don't change this in order to "tune" things.
	*/
	SET NOCOUNT ON
 
	DECLARE @Id1 INT = CAST(RAND() * 1000000 AS INT) + 1,
			@Param1 NVARCHAR(100);

	IF @Id1 % 4 = 3
		EXEC dbo.usp_GetUser @UserId = @Id1;
	ELSE IF @Id1 % 4 = 2
		BEGIN
		SELECT @Param1 = Location FROM dbo.Users WHERE Id = @Id1 OPTION (RECOMPILE);
		EXEC dbo.usp_GetUser @Location = @Param1;
		END
	ELSE
		BEGIN
		SELECT @Param1 = DisplayName FROM dbo.Users WHERE Id = @Id1 OPTION (RECOMPILE);
		EXEC dbo.usp_GetUser @DisplayName = @Param1;
		END
END
GO


EXEC usp_DynamicSQLLab;
GO 500

/* To find out if your server is going to have a problem with constant query
compilations triggering Query Store to do a lot of work, run this:
https://www.brentozar.com/archive/2018/07/tsql2sday-how-much-plan-cache-history-do-you-have/
*/
SELECT TOP 50
    creation_date = CAST(creation_time AS date),
    creation_hour = CASE
                        WHEN CAST(creation_time AS date) <> CAST(GETDATE() AS date) THEN 0
                        ELSE DATEPART(hh, creation_time)
                    END,
    SUM(1) AS plans
FROM sys.dm_exec_query_stats
GROUP BY CAST(creation_time AS date),
         CASE
             WHEN CAST(creation_time AS date) <> CAST(GETDATE() AS date) THEN 0
             ELSE DATEPART(hh, creation_time)
         END
ORDER BY 1 DESC, 2 DESC


/* If your SQL Server is seeing 10,000 or more queries per hour, and it can
only remember the last 2-4 hours of queries, then you're probably going to have
a tough time with the performance overhead of Query Store. Get the queries
parameterized first, or use Forced Parameterization:

https://www.brentozar.com/training/mastering-server-tuning-wait-stats-live-3-days-recording/3-1-plan-caching-and-parameterization/

Although ironically...if you use that, then you're going to experience
parameter sniffing! Because now these queries will get reusable plans.
*/







/*
What to take away from this demo:

* Query Store can capture every possible variety 
  of every compilation. If you need to track 
  queries with recompile hints, it's great.

* It does add overhead. To minimize it, read Erin
  Stellato's Query Store Best Practices:
  https://www.sqlskills.com/blogs/erin/query-store-best-practices/

* If you aren't a good fit for Query Store, don't 
  forget that sp_BlitzWho can log live query plans 
  on 2016+ when it catches queries running during the
  every-15-minute capture job. It's nowhere near as 
  good as Query Store, but it's a decent Plan B.

* If you love Query Store, check out sp_QuickieStore:
  https://www.erikdarlingdata.com/sp_quickiestore/

* In SQL Server 2022, Query Store is on by default
  but only for newly created databases.

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