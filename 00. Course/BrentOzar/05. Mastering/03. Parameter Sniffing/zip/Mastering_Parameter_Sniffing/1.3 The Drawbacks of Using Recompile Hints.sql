/*
Mastering Parameter Sniffing
The Drawbacks of Using Recompile Hints

v1.2 - 2021-02-16

https://www.BrentOzar.com/go/mastersniffing


This demo requires:
* SQL Server 2017 or newer
* 2018-06 Stack Overflow database: https://www.BrentOzar.com/go/querystack

This first RAISERROR is just to make sure you don't accidentally hit F5 and
run the entire script. You don't need to run this:
*/
RAISERROR(N'Oops! No, don''t just hit F5. Run these demos one at a time.', 20, 1) WITH LOG;
GO


/* Set the stage with the right server options & database config. We'll be 
doing this repeatedly for a few modules, and this script should be idempotent. */
USE StackOverflow;
GO
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
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 140; /* 2017, not 2019 yet */
GO
EXEC sys.sp_configure N'cost threshold for parallelism', N'50' /* Keep small queries serial */
GO
EXEC sys.sp_configure N'max degree of parallelism', N'4' /* Let queries go parallel */
GO
RECONFIGURE
GO
DBCC FREEPROCCACHE;
GO


/* We've been hitting a wall when we have a really big choice to make:
   which table should we process first? */
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

/* If we run them all with recompile hints, they all add up to <10 seconds: */
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
/* Their actual plans are all over the place! 

If we truly want every one of them to get their own plan, we can just redefine
the stored procedure with a recompile hint built right in: 
*/
CREATE OR ALTER PROC dbo.usp_SearchPostsByLocation	
	@Location VARCHAR(100), @StartDate DATETIME, @EndDate DATETIME AS
BEGIN
/* Find the most recent posts from an area */
SELECT TOP 200 u.DisplayName, p.Title, p.Id, p.CreationDate
  FROM dbo.Posts p
  INNER JOIN dbo.Users u ON p.OwnerUserId = u.Id
  WHERE u.Location LIKE @Location
    AND p.CreationDate BETWEEN @StartDate AND @EndDate
  ORDER BY p.CreationDate DESC
  OPTION (RECOMPILE)			/* THIS IS NEW */;
END
GO


/* We don't have to ask for a recompile - it's even easier & faster! */
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Big data, big dates */
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Big data, medium dates */
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Big data, small dates */
 
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Medium data, big dates */
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Medium data, medium dates */
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Medium data, small dates */
 
EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Small data, big dates */
EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Small data, medium dates */
EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Small data, small dates */
 
EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Outlier data, big dates */
EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Outlier data, medium dates */
EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Outlier data, small dates */
GO


/* There are 3 drawbacks: 

1. The plans may still not actually be good: if SQL Server has estimation
   problems, it may still pick bad indexes, grants, orders, etc. That's a
   separate problem - that's just plain old query tuning. We cover that in
   Mastering Query Tuning.

2. The statement-level metrics disappear from cache: note the number of
   executions for the proc and for the statement:
*/
sp_BlitzCache;

/*
3. Each time the query is compiled, there's a CPU hit. This isn't bad in a
   small stored proc like ours, but it can be a big deal as:
	
	* You build the hint into more queries

	* You build the hint into LARGER queries (that take more CPU time to compile)

You can see the overhead in each actual plan by looking at its compilation CPU
and compilation time metrics, but ain't nobody got time for that.

Let's see the overhead with sp_HumanEvents: 
https://www.erikdarlingdata.com/sp_humanevents/
*/

/* Start this in another window: */
EXEC dbo.sp_HumanEvents @event_type = 'recompilations', @seconds_sample = 30;
GO

/* Then run our workload again: */
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Big data, big dates */
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Big data, medium dates */
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Big data, small dates */
 
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Medium data, big dates */
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Medium data, medium dates */
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Medium data, small dates */
 
EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Small data, big dates */
EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Small data, medium dates */
EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Small data, small dates */
 
EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Outlier data, big dates */
EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Outlier data, medium dates */
EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Outlier data, small dates */
GO





/* The compilation overhead on a simple query
like that isn't bad. However, add more of these:
 * Statements
 * Joins
 * Partitions
 * Plan choices
And compilation time gets worse. To illustrate it,
I'm going to partition the Users table by
CreationDate: */


/* Create a numbers table with 1M rows: */
DROP TABLE IF EXISTS dbo.Numbers;
GO
CREATE TABLE Numbers (Number  int  not null PRIMARY KEY CLUSTERED);
;WITH
  Pass0 as (select 1 as C union all select 1), --2 rows
  Pass1 as (select 1 as C from Pass0 as A, Pass0 as B),--4 rows
  Pass2 as (select 1 as C from Pass1 as A, Pass1 as B),--16 rows
  Pass3 as (select 1 as C from Pass2 as A, Pass2 as B),--256 rows
  Pass4 as (select 1 as C from Pass3 as A, Pass3 as B),--65536 rows
  Pass5 as (select 1 as C from Pass4 as A, Pass4 as B),--Bigint
  Tally as (select row_number() over(order by C) as Number from Pass5)
INSERT dbo.Numbers
        (Number)
    SELECT Number
        FROM Tally
        WHERE Number <= 1000000;
GO

/* Create date partition function by day since Stack Overflow's origin,
modified from Microsoft Books Online: 
https://docs.microsoft.com/en-us/sql/t-sql/statements/create-partition-function-transact-sql?view=sql-server-ver15#BKMK_examples

DROP PARTITION SCHEME [DatePartitionScheme];
DROP PARTITION FUNCTION [DatePartitionFunction];
*/
DECLARE @DatePartitionFunction nvarchar(max) = 
    N'CREATE PARTITION FUNCTION DatePartitionFunction (datetime) 
    AS RANGE RIGHT FOR VALUES (';  
DECLARE @i datetime = '2008-06-01';
WHILE @i <= GETDATE()
BEGIN  
SET @DatePartitionFunction += '''' + CAST(@i as nvarchar(20)) + '''' + N', ';  
SET @i = DATEADD(DAY, 1, @i);  
END  
SET @DatePartitionFunction += '''' + CAST(@i as nvarchar(20))+ '''' + N');';  
EXEC sp_executesql @DatePartitionFunction;  
GO  

/* Create matching partition scheme, but put everything in Primary: */
CREATE PARTITION SCHEME DatePartitionScheme  
AS PARTITION DatePartitionFunction  
ALL TO ( [PRIMARY] ); 
GO


DROP TABLE IF EXISTS dbo.Users_partitioned;
GO
CREATE TABLE [dbo].[Users_partitioned](
	[Id] [int] NOT NULL,
	[AboutMe] [nvarchar](max) NULL,
	[Age] [int] NULL,
	[CreationDate] [datetime] NOT NULL,
	[DisplayName] [nvarchar](40) NOT NULL,
	[DownVotes] [int] NOT NULL,
	[EmailHash] [nvarchar](40) NULL,
	[LastAccessDate] [datetime] NOT NULL,
	[Location] [nvarchar](100) NULL,
	[Reputation] [int] NOT NULL,
	[UpVotes] [int] NOT NULL,
	[Views] [int] NOT NULL,
	[WebsiteUrl] [nvarchar](200) NULL,
	[AccountId] [int] NULL
) ON [PRIMARY];
GO

CREATE CLUSTERED INDEX CreationDate_Id ON 
	dbo.Users_partitioned (Id)
	ON DatePartitionScheme(CreationDate);
GO

INSERT INTO dbo.Users_partitioned (Id, AboutMe, Age,
	CreationDate, DisplayName, DownVotes, EmailHash,
	LastAccessDate, Location, Reputation, UpVotes,
	Views, WebsiteUrl, AccountId)
SELECT Id, AboutMe, Age,
	CreationDate, DisplayName, DownVotes, EmailHash,
	LastAccessDate, Location, Reputation, UpVotes,
	Views, WebsiteUrl, AccountId
	FROM dbo.Users;
GO
CREATE INDEX Location_Aligned 
	ON dbo.Users_partitioned(Location);
CREATE INDEX Location_NotAligned 
	ON dbo.Users(Location) ON [PRIMARY];
GO



CREATE OR ALTER PROC dbo.usp_SearchPostsByLocation_Partitioned
	@Location VARCHAR(100), @StartDate DATETIME, @EndDate DATETIME AS
BEGIN
/* Find the most recent posts from an area */
SELECT TOP 200 u.DisplayName, p.Title, p.Id, p.CreationDate
  FROM dbo.Posts p
  INNER JOIN dbo.Users_partitioned u ON p.OwnerUserId = u.Id
  WHERE u.Location LIKE @Location
    AND p.CreationDate BETWEEN @StartDate AND @EndDate
  ORDER BY p.CreationDate DESC
  OPTION (RECOMPILE);
END
GO




/* Start this in another window: */
EXEC dbo.sp_HumanEvents @event_type = 'recompilations', @seconds_sample = 30;
GO

/* Then run our workload again: */
EXEC usp_SearchPostsByLocation_Partitioned 'India', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Big data, big dates */
EXEC usp_SearchPostsByLocation_Partitioned 'India', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Big data, medium dates */
EXEC usp_SearchPostsByLocation_Partitioned 'India', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Big data, small dates */
 
EXEC usp_SearchPostsByLocation_Partitioned 'Netherlands', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Medium data, big dates */
EXEC usp_SearchPostsByLocation_Partitioned 'Netherlands', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Medium data, medium dates */
EXEC usp_SearchPostsByLocation_Partitioned 'Netherlands', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Medium data, small dates */
 
EXEC usp_SearchPostsByLocation_Partitioned 'Near Stonehenge', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Small data, big dates */
EXEC usp_SearchPostsByLocation_Partitioned 'Near Stonehenge', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Small data, medium dates */
EXEC usp_SearchPostsByLocation_Partitioned 'Near Stonehenge', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Small data, small dates */
 
EXEC usp_SearchPostsByLocation_Partitioned 'Willemstad, Curaçao', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Outlier data, big dates */
EXEC usp_SearchPostsByLocation_Partitioned 'Willemstad, Curaçao', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Outlier data, medium dates */
EXEC usp_SearchPostsByLocation_Partitioned 'Willemstad, Curaçao', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Outlier data, small dates */
GO










/* Last note: if you're gonna do recompilations 
in the real world, never put the hint on the
outside of the stored procedure like this: */
CREATE OR ALTER PROC dbo.usp_SearchPostsByLocation				/* This is bad: */
	@Location VARCHAR(100), 
	@StartDate DATETIME, @EndDate DATETIME WITH RECOMPILE AS
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


/* Put them on the inside like this: */
CREATE OR ALTER PROC dbo.usp_SearchPostsByLocation
	@Location VARCHAR(100), 
	@StartDate DATETIME, @EndDate DATETIME AS
BEGIN
/* Find the most recent posts from an area */
SELECT TOP 200 u.DisplayName, p.Title, p.Id, p.CreationDate
  FROM dbo.Posts p
  INNER JOIN dbo.Users u ON p.OwnerUserId = u.Id
  WHERE u.Location LIKE @Location
    AND p.CreationDate BETWEEN @StartDate AND @EndDate
  ORDER BY p.CreationDate DESC
  OPTION (RECOMPILE);									/* This is less bad */
END
GO
/* Because you'll get some (but not all) monitoring in the plan cache: */

DBCC FREEPROCCACHE;
GO
/* Then run our workload again: */
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Big data, big dates */
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Big data, medium dates */
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Big data, small dates */
 
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Medium data, big dates */
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Medium data, medium dates */
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Medium data, small dates */
 
EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Small data, big dates */
EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Small data, medium dates */
EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Small data, small dates */
 
EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Outlier data, big dates */
EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Outlier data, medium dates */
EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Outlier data, small dates */
GO

sp_BlitzCache;




/*
What to take away from this demo:

* If you truly need different plans for every parameter set, statement-level 
  recompile hints are the way to go.

* I just only use these when the query runs less than a few times per minute,
  or else the overhead of this (plus the rest of the queries where I end up
  REQUIRING recompile hints) can add up to a big deal.

* The easy way to see if it's a big deal on your server already:
  sp_HumanEvents by Erik Darling.

  https://www.erikdarlingdata.com/sp_humanevents/

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