/*
Mastering Parameter Sniffing
How Adaptive Memory Grants Mitigate Parameter Sniffing

v1.3 - 2020-11-19

https://www.BrentOzar.com/go/mastersniffing


This demo requires:
* SQL Server 2019 or newer
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

/* Our regular sensitive proc: */
CREATE OR ALTER PROC dbo.usp_SearchPostsByLocation
	@Location VARCHAR(100), @StartDate DATETIME, @EndDate DATETIME AS
BEGIN
/* Find the most recent posts from an area */
SELECT TOP 200 u.DisplayName, p.Title, p.Id, p.CreationDate,
	/* I added these columns to get a bigger sort: */
	u.Location, u.WebsiteUrl, u.AboutMe, u.EmailHash, p.Body
  FROM dbo.Posts p
  INNER JOIN dbo.Users u ON p.OwnerUserId = u.Id
  WHERE u.Location LIKE @Location
    AND p.CreationDate BETWEEN @StartDate AND @EndDate
  ORDER BY p.CreationDate DESC;
END
GO


/* I'm going to call this with recompile to show that some plan variations will
need a memory grant for the sort, and some will not: */

/* No sort - using the p.CreationDate index for the sort: */
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2008-01-01', @EndDate = '2014-01-01' WITH RECOMPILE; /* Big data, big dates */
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2009-01-01', @EndDate = '2009-02-01' WITH RECOMPILE; /* Big data, medium dates */
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01' WITH RECOMPILE; /* Big data, small dates */

/* These DO have a sort, so their grant size varies based on the data volume: */ 
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2008-01-01', @EndDate = '2014-01-01' WITH RECOMPILE; /* Medium data, big dates */
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2009-01-01', @EndDate = '2009-02-01' WITH RECOMPILE; /* Medium data, medium dates */
/* No sort here: */
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01' WITH RECOMPILE; /* Medium data, small dates */

/* Sort w/grant: */ 
EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2008-01-01', @EndDate = '2014-01-01' WITH RECOMPILE; /* Small data, big dates */
EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2009-01-01', @EndDate = '2009-02-01' WITH RECOMPILE; /* Small data, medium dates */
/* No sort, no grant: */
EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01' WITH RECOMPILE; /* Small data, small dates */
 
/* Sort w/grant, spills: */
EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2008-01-01', @EndDate = '2014-01-01' WITH RECOMPILE; /* Outlier data, big dates */
/* Sort w/grant: */
EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2009-01-01', @EndDate = '2009-02-01' WITH RECOMPILE; /* Outlier data, medium dates */
EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01' WITH RECOMPILE; /* Outlier data, small dates */
GO


/* So in terms of memory grants & spills, my two worst cases are:

* The Tiny Grant That Constantly Spills to TempDB
	1. Parameters are used that ask for a tiny memory grant
	2. Other parameters need a HUGE grant, but don't get it
	3. When they run, they spill to TempDB and take forever
	General symptom: unhappy users

* The Big Unused Grant:
	1. Parameters are used that ask for a large memory grant
	2. Other parameters don't need the grant
	3. SQL Server ends up leaving all the memory unused every time the query runs,
	   causing RESOURCE_SEMAPHORE waits. More info: 
	   https://www.brentozar.com/training/mastering-server-tuning-wait-stats-live-3-days-recording/2-5-memory-waits-resource_semaphore-38m/
	General symptom: unhappy sysadmins, low PLE.

We'll show the tiny grant first. Put a tiny grant plan in memory.
Which one should we use? */

EXEC sp_recompile 'usp_SearchPostsByLocation';
GO
/* Tiny grant goes in - check actual plan: */
EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2009-01-01', @EndDate = '2009-02-01';
GO
/* Now call it for big data: */
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2008-01-01', @EndDate = '2014-01-01';
GO

/* Well, that's not good. And try it again, and the same thing happens: */
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2008-01-01', @EndDate = '2014-01-01';
GO



/* That's the tiny-grant, big-spill situation.

Now let's see the opposite: a query that wants a large memory grant goes in first,
and then other parameters don't use it: */
EXEC sp_recompile 'usp_SearchPostsByLocation';
GO
/* This gets a grant: */
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Medium data, big dates */
GO
/* Now run it for tiny data: */
EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2009-01-01', @EndDate = '2009-02-01';
GO
/* And note the  yellow bang on the plan - we're just not using that memory.
Well, honestly, that isn't a big grant though - and if we run it for big data,
we actually do use it: */
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2008-01-01', @EndDate = '2014-01-01';
GO


/* That's how everything worked up to SQL Server 2019.

In SQL Server 2016, Microsoft introduced adaptive memory grants, but they only
activated 'em for queries that had a columnstore index on one of the tables,
because that activated Batch Mode processing.
*/
CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI_Empty ON dbo.Users(Age) WHERE Age = -1;
GO
SELECT * FROM dbo.Users WHERE Age = -1;
GO
/* Nada. But that empty filtered index - just the presence of it - means that
SQL Server will suddenly consider Batch Mode, even on 2017 compat level.

Sometimes that helps! Let's take a look: */
EXEC sp_recompile 'usp_SearchPostsByLocation';
GO
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Medium data, big dates */
GO


/* Things to keep in mind:

* My query doesn't refer to Age
* My query doesn't use that index on Age, nor any statistics on Age
* I'm still on 2017 compat level
* NOTHING ABOUT MY QUERY SHOULD HAVE GONE SO TERRIBLY WRONG

To see what's happening, run this in another window and look at the plan,
hovering your mouse over each operator, looking at Batch Mode, AND look at
the memory grant this query gets:
*/
sp_BlitzWho;
GO


/* The good news, is, uh, ... we didn't spill to disk.

The bad news is:
* Memory grant size
* Memory grant used
* Users are gathering at the door with pitchforks

There's a silver lining though: Batch Mode enables adaptive memory grants:
* Desired memory	= 
* Requested memory	= 
* Granted memory	= 
* Used memory		= 

And run it again: */
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Medium data, big dates */
GO

/* But I think the empty nonclustered columnstore index trick is a REALLY bad
way to get adaptive grants. Let's drop that and do it the right way: */
DROP INDEX NCCI_Empty ON dbo.Users;
GO
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 150; /* 2019, which enables adaptive grants on rowstore indexes */
GO
/* And try it again: */
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Medium data, big dates */
GO
/* Make a note:
* Desired memory	= 
* Requested memory	= 
* Granted memory	= 
* Used memory		= 

And run it again: */
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Medium data, big dates */
GO
/* Well, it's, uh, "adapting" alright. Third try's a charm, maybe? */
EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Medium data, big dates */
GO
/* As you continue to run it, it will continue to adapt. However, it's always
adapting to the LAST time the query ran. Now try it with tiny data: */
EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2009-01-01', @EndDate = '2009-02-01';
GO
/* SQL Server goes into a full on panic, thinking it WAY overestimated.
It'll "fix" that next time around, lowering the grant: */
EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2009-01-01', @EndDate = '2009-02-01';
GO

/* But now call it for big data, and it'll spill to disk: */
EXEC usp_SearchPostsByLocation 'India', @StartDate = '2008-01-01', @EndDate = '2014-01-01';
GO

/* Spotting this can be really tricky. Turn off actual plans: */
sp_BlitzCache @SortOrder = 'spills';
GO
/* Things to look for:

* Wide variance in spills to disk
* Wide variance between min & max memory grant KB

To learn more about this feature:
https://docs.microsoft.com/en-us/sql/relational-databases/performance/intelligent-query-processing?view=sql-server-ver15#row-mode-memory-grant-feedback

To turn it off for specific queries:
OPTION (USE HINT ('DISABLE_ROW_MODE_MEMORY_GRANT_FEEDBACK')); 

To turn it off for the database altogether while keeping 2019 compat level: */
ALTER DATABASE SCOPED CONFIGURATION SET ROW_MODE_MEMORY_GRANT_FEEDBACK = OFF;
ALTER DATABASE SCOPED CONFIGURATION SET BATCH_MODE_MEMORY_GRANT_FEEDBACK = OFF;
GO




/* 
What to take away from this demo:

* Batch Mode Memory Grant Feedback was a really useful feature in 2016-2017
  because columnstore indexes got HUGE memory grants back then.

* I'm not a fan of the empty columnstore index trick to get batch mode on
  rowstore tables: it can backfire pretty hard. (I'm a fan of batch mode where
  it's appropriate, but 2-3 second OLTP queries ain't where it's at yet.)

* Row Mode Memory Grant Feedback is a lot sketchier. If you have parameter-
  sensitive queries, you can ride the grant rollercoaster and performance can
  be way worse than a single stable grant (either too high or too low.)

* This is one feature I turn off at OLTP shops, but love it for reporting
  systems.

* Mostly I just want you to be aware that the feature exists, and that it
  CAUSES (not cures) parameter sniffing problems by making a predictable plan
  less predictable (and more worse.)

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