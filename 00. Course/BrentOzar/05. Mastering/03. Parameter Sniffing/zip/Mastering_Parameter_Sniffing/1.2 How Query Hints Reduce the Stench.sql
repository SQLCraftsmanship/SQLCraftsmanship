/*
Mastering Parameter Sniffing
1.2 How Query Hints Reduce the Stench

v1.3 - 2022-02-08

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
EXEC DropIndexes @TableName = 'Users', @ExceptIndexNames = 'Location';
EXEC DropIndexes @TableName = 'Posts', @ExceptIndexNames = 'CreationDate,_dta_index_Posts_5_85575343__K8,IX_OwnerUserId,OwnerUserId,Score_CreationDate';
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
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Posts') AND name = 'Score_CreationDate')
	CREATE INDEX Score_CreationDate ON dbo.Posts(Score, CreationDate);
GO


ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 140; /* 2017, not 2019 yet */
GO
EXEC sys.sp_configure N'cost threshold for parallelism', N'50' /* Keep small queries serial */
GO
EXEC sys.sp_configure N'max degree of parallelism', N'4' /* Let queries go parallel */
GO
RECONFIGURE
GO


/* In the index-tuning module, we hit a wall when we tried to use index tuning
alone to solve a tough choice between two indexes on this proc: */
CREATE OR ALTER PROC dbo.usp_TopScoringPostsByDateAndScore
	@StartDate DATETIME, @EndDate DATETIME, @MinimumScore INT AS
BEGIN
SELECT TOP 200 p.Score, p.Title, p.Body, p.Id, p.CreationDate, u.DisplayName
  FROM dbo.Posts p
  INNER JOIN dbo.Users u ON p.OwnerUserId = u.Id
  WHERE p.CreationDate BETWEEN @StartDate AND @EndDate
    AND p.Score >= @MinimumScore
  ORDER BY p.Score DESC;
END
GO

/* There is no one good plan for this.

If you call it for a SELECTIVE date range and a NON-SELECTIVE score, you need
to use the index on CreationDate first: */
EXEC usp_TopScoringPostsByDateAndScore 
	@StartDate = '2009-01-01 10:00', 
	@EndDate = '2009-01-01 10:01',
	@MinimumScore = 1 WITH RECOMPILE;
GO

/* If you call it for a NON-SELECTIVE date range and a SELECTIVE score, you
need to use the index on Score first: */
EXEC usp_TopScoringPostsByDateAndScore 
	@StartDate = '2017-01-01', 
	@EndDate = '2017-12-31',
	@MinimumScore = 10000 WITH RECOMPILE;
GO

/* If the CreationDate index goes into cache first, and then we call the other,
the results are terrible: */
sp_recompile 'usp_TopScoringPostsByDateAndScore';
GO
EXEC usp_TopScoringPostsByDateAndScore 
	@StartDate = '2009-01-01 10:00', 
	@EndDate = '2009-01-01 10:01',
	@MinimumScore = 1;
GO
EXEC usp_TopScoringPostsByDateAndScore 
	@StartDate = '2017-01-01', 
	@EndDate = '2017-12-31',
	@MinimumScore = 10000;
GO


/* If the Score index goes in memory first: */
sp_recompile 'usp_TopScoringPostsByDateAndScore';
GO
EXEC usp_TopScoringPostsByDateAndScore 
	@StartDate = '2017-01-01', 
	@EndDate = '2017-12-31',
	@MinimumScore = 10000;
GO
EXEC usp_TopScoringPostsByDateAndScore 
	@StartDate = '2009-01-01 10:00', 
	@EndDate = '2009-01-01 10:01',
	@MinimumScore = 1;
GO


/* Wait - that's...that's actually not bad! We might be able to live with that
plan being used for everything. Let's try the absolute worst case for it: a
score filter that matches ALL posts, and a CreationDate that only matches just
one single post: */
SELECT TOP 1 CreationDate FROM dbo.Posts;
GO
EXEC usp_TopScoringPostsByDateAndScore 
	@StartDate = '2008-07-31 21:42:52.667', 
	@EndDate = '2008-07-31 21:42:52.667',
	@MinimumScore = -100;
GO


/* In this case:

* We read ALL of the posts - that's a lot of logical reads
* But SQL Server can read data quickly, even with just one core

* There's no over-allocation of CPU here
* There's no over-allocation of memory here
* There aren't a bunch of key lookups

This might be the least-bad query! If we want to stick with this, we could use
an index hint by name: */
CREATE OR ALTER PROC dbo.usp_TopScoringPostsByDateAndScore
	@StartDate DATETIME, @EndDate DATETIME, @MinimumScore INT AS
BEGIN
SELECT TOP 200 p.Score, p.Title, p.Body, p.Id, p.CreationDate, u.DisplayName
  FROM dbo.Posts p WITH (INDEX = Score_CreationDate)						/* THIS IS NEW */
  INNER JOIN dbo.Users u ON p.OwnerUserId = u.Id
  WHERE p.CreationDate BETWEEN @StartDate AND @EndDate
    AND p.Score >= @MinimumScore
  ORDER BY p.Score DESC;
END
GO


/* Try our absolute worst case scenario first, which SHOULD build a query plan
that wants the index by CreationDate first: */
EXEC usp_TopScoringPostsByDateAndScore 
	@StartDate = '2008-07-31 21:42:52.667', 
	@EndDate = '2008-07-31 21:42:52.667',
	@MinimumScore = -100;
GO


/* Things to note in the actual plan:
* We get a seek on the Score_CreationDate index
* Even though Score -100 isn't selective
* Because SQL Server used the index hint

But if something happens with that index, like if someone renames it: */
EXEC sp_rename @objname = N'dbo.Posts.Score_CreationDate', 
	@newname = N'IX_Score_CreationDate', @objtype = N'INDEX';
GO


/* And then we run our query again: */
EXEC usp_TopScoringPostsByDateAndScore 
	@StartDate = '2008-07-31 21:42:52.667', 
	@EndDate = '2008-07-31 21:42:52.667',
	@MinimumScore = -100;
GO

/* 
     _.-^^---....,,--       
 _--                  --_  
<                        >)
|                         | 
 \._                   _./  
    ```--. . , ; .--'''       
          | |   |             
       .-=||  | |=-.   
       `-=#$%&%$#=-'   
          | ;  :|     
 _____.,-#%&$@%#&#~,._____
 
 
So yeah, not a big fan of index hints.

Hint the PARAMETERS instead, and then let SQL Server pick the appropriate index
at runtime. Plus, the parameter hints let SQL Server optimize for different
parallelism, memory grants, data changes over time, etc:
*/
CREATE OR ALTER PROC dbo.usp_TopScoringPostsByDateAndScore
	@StartDate DATETIME, @EndDate DATETIME, @MinimumScore INT AS
BEGIN
SELECT TOP 200 p.Score, p.Title, p.Body, p.Id, p.CreationDate, u.DisplayName
  FROM dbo.Posts p												/* INDEX HINT IS GONE */
  INNER JOIN dbo.Users u ON p.OwnerUserId = u.Id
  WHERE p.CreationDate BETWEEN @StartDate AND @EndDate
    AND p.Score >= @MinimumScore
  ORDER BY p.Score DESC
  OPTION (OPTIMIZE FOR (@MinimumScore = 100000));
END
GO


/* Is hinting for score alone enough? */
EXEC usp_TopScoringPostsByDateAndScore 
	@StartDate = '2009-01-01 10:00', 
	@EndDate = '2009-01-01 10:01',
	@MinimumScore = 1;
GO
EXEC usp_TopScoringPostsByDateAndScore 
	@StartDate = '2017-01-01', 
	@EndDate = '2017-12-31',
	@MinimumScore = 10000;
GO
/* And our worst case: */
EXEC usp_TopScoringPostsByDateAndScore 
	@StartDate = '2008-07-31 21:42:52.667', 
	@EndDate = '2008-07-31 21:42:52.667',
	@MinimumScore = -100;
GO



/* We can also hint both score and dates: */
CREATE OR ALTER PROC dbo.usp_TopScoringPostsByDateAndScore
	@StartDate DATETIME, @EndDate DATETIME, @MinimumScore INT AS
BEGIN
SELECT TOP 200 p.Score, p.Title, p.Body, p.Id, p.CreationDate, u.DisplayName
  FROM dbo.Posts p												/* INDEX HINT IS GONE */
  INNER JOIN dbo.Users u ON p.OwnerUserId = u.Id
  WHERE p.CreationDate BETWEEN @StartDate AND @EndDate
    AND p.Score >= @MinimumScore
  ORDER BY p.Score DESC
  OPTION (OPTIMIZE FOR (@MinimumScore = 100000, 
  @StartDate = '2008-07-31 21:42:52.667', 
  @EndDate = '2008-07-31 21:42:52.667'));
END
GO



/* Hints can be useful with dynamic SQL: */
CREATE OR ALTER PROC dbo.usp_TopScoringPostsByDateAndScore
	@StartDate DATETIME, @EndDate DATETIME, @MinimumScore INT AS
BEGIN
DECLARE @StringToExecute NVARCHAR(4000);
SET @StringToExecute = N'
	SELECT TOP 200 p.Score, p.Title, p.Body, p.Id, p.CreationDate, u.DisplayName
	  FROM dbo.Posts p
	  INNER JOIN dbo.Users u ON p.OwnerUserId = u.Id
	  WHERE p.CreationDate BETWEEN @StartDate AND @EndDate
		AND p.Score >= @MinimumScore
	  ORDER BY p.Score DESC ';

/* If they're asking for >60 days, it's big data, so get a fresh plan for it: */
IF DATEDIFF(DD, @StartDate, @EndDate) > 60
	SET @StringToExecute = @StringToExecute + N' OPTION (RECOMPILE) ';

EXEC sp_executesql @StringToExecute, 
	N'@StartDate DATETIME, @EndDate DATETIME, @MinimumScore INT',
	@StartDate, @EndDate, @MinimumScore;
END
GO


/* There are a huge number of hints available, and they keep growing with each
new version:
https://docs.microsoft.com/en-us/sql/t-sql/queries/hints-transact-sql-query?view=sql-server-ver15

I don't use these often, but when I do, these are the ones I like:

OPTIMIZE FOR specific variables:
Lets me pick which plan I want to aim for. Works well if the majority of my
queries have a similar pattern, like a narrow or wide date range.

OPTIMIZE FOR UNKNOWN:
I don't actually like this much because you're optimizing for the "average"
value, and that value can change a lot over time. However, if your query would
perform well if the "average" value worked well, and if you specifically want
to exclude an outlier plan (like Jon Skeet running first), then this works.
If you find yourself using this a lot, try the database-level setting for
disabling parameter sniffing instead (which can also be set differently for AG
secondaries, which have reporting-style big-data queries.)

MAX_GRANT_PERCENT:
If SQL Server believes a huge amount of memory is necessary for a query, but I
know that the predicate is just nonsargable, OR if I know the speed of this
query just doesn't matter (and I'm okay if it spills to disk), then this lets
me limit the grant.

MAXDOP:
You can actually pass in a HIGHER number here than the server's MAXDOP. Useful
if you need to run batch reports against something like a Dynamics database
that would otherwise get MAXDOP 1. When I do this, I tend to hint MAXDOP 8. I
don't usually want to take over *all* of the cores on a server. To be clear
though, this does NOT encourage a parallel plan.

OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))
This one encourages a parallel plan.

Cardinality estimation hotfixes:
There are hints you can use to ask for a newer or legacy CE, depending on
whether your database defaults to the old or new one.

QUERY_OPTIMIZER_COMPATIBILITY_LEVEL_n:
This is Microsoft's attempt to let ISVs ask for a specific CE, and thereby
maintain support on newer versions of SQL Server. If they have a query that
only performs well on the older (or a specific) compat level, they can ask for
it at the query level here. I've never met an ISV that had enough time to hint
all of their queries like this. Your mileage may vary.

QUERYTRACEON:
If you need a specific trace flag, you can do it with this syntax:
OPTION (QUERYTRACEON 4199, QUERYTRACEON 4137)

List of supported trace flags:
https://docs.microsoft.com/en-us/sql/t-sql/database-console-commands/dbcc-traceon-trace-flags-transact-sql
	* 4199: query optimizer behavior changes
	* 9398: disables Adaptive Joins
	* 9481: old CE (pre-2014) regardless of compat level
	* 11064: memory balancing for columnstore inserts

List of all trace flags, including unsupported:
https://github.com/ktaranov/sqlserver-kit/blob/master/SQL%20Server%20Trace%20Flag.md
	* 8671: spend more time compiling plans, ignore "good enough plan found"
	* 2453: table variables can trigger recompile when rows are inserted

I've seriously never done this in production, but I know a lot of folks that I
respect who have, so I'm leaving this here.

RECOMPILE:
But I'll dedicate a whole module to that.
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