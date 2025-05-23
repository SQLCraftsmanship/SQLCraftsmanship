/*
Fundamentals of Query Tuning: How Parameters Affect Plans

v1.3 - 2023-11-05

https://www.BrentOzar.com/go/queryfund


This demo requires:
* Any supported version of SQL Server
* Any Stack Overflow database: https://www.BrentOzar.com/go/querystack

This first RAISERROR is just to make sure you don't accidentally hit F5 and
run the entire script. You don't need to run this:
*/
RAISERROR(N'Oops! No, don''t just hit F5. Run these demos one at a time.', 20, 1) WITH LOG;
GO


/* I'm using the 50GB medium Stack database: */
USE StackOverflow2013;
GO
/* Using 2017 compat level at first because 2017
is the minimum supported version for this class: */
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 140;
GO
/* And this stored procedure drops all nonclustered indexes: */
DropIndexes;
GO
/* It leaves clustered indexes in place though. 

Create a few indexes to support our queries: */
CREATE INDEX IX_Location ON dbo.Users(Location);
CREATE INDEX IX_UserId ON dbo.Comments(UserId);
CREATE INDEX IX_CreationDate ON dbo.Comments(CreationDate);
GO




SET STATISTICS IO ON;

/* 
We'll start with the same query we used in the first module.
Turn on actual query plans and run this:
*/
SELECT u.DisplayName, u.Id AS UserId, c.Id AS CommentId, c.Score, c.Text
  FROM dbo.Users u
  INNER JOIN dbo.Comments c ON u.Id = c.UserId
  WHERE u.Location = 'Helsinki, Finland'
    AND c.CreationDate BETWEEN '2013-08-01' AND '2013-08-30'
  ORDER BY c.Score DESC;
GO

/* 
Things to think about:

* What table was processed first? And second?
* How did we access these tables?

Let's try a more popular location: India.
*/
SELECT u.DisplayName, u.Id AS UserId, c.Id AS CommentId, c.Score, c.Text
  FROM dbo.Users u
  INNER JOIN dbo.Comments c ON u.Id = c.UserId
  WHERE u.Location = 'India'
    AND c.CreationDate BETWEEN '2013-08-01' AND '2013-08-30'
  ORDER BY c.Score DESC;
GO
/* 
Did that change:

 * The shape of the plan?
 * Our row estimates on each table?
 * The memory grants?
 * How SQL Server chose to access each table?



Things to think about as we change locations:

 * How many different plans have we seen so far?
 * How many plans might there be for all the different locations?
 * Is there maybe one plan that would work well for everyone?
 * Do we have some data outliers that need different plans?

Let's see the top locations:
*/
SELECT TOP 100 Location, COUNT(*) AS recs
  FROM dbo.Users
  GROUP BY Location
  ORDER BY COUNT(*) DESC;
GO
/*
And we're only changing the location - not even the dates!

Most queries are parameterized, like:
	* Stored procedures
	* Dynamic SQL
	* ORMs like Entity Framework and NHibernate

So let's see what happens when we use parameterized SQL:
*/
CREATE OR ALTER PROC dbo.usp_SearchComments
    @Location NVARCHAR(200),
    @StartDate DATETIME,
    @EndDate DATETIME AS
BEGIN
    SELECT u.DisplayName, u.Id AS UserId, c.Id AS CommentId, c.Score, c.Text
      FROM dbo.Users u
      INNER JOIN dbo.Comments c ON u.Id = c.UserId
      WHERE u.Location = @Location
        AND c.CreationDate BETWEEN @StartDate AND @EndDate
      ORDER BY c.Score DESC;
END
GO

/* 
You don't normally need to clear the plan cache, but this will help with
something I'm about to show you in a minute:
*/
DBCC FREEPROCCACHE;
GO

EXEC usp_SearchComments 'India', '2013-08-01', '2013-08-30';
GO
EXEC usp_SearchComments 'Helsinki, Finland', '2013-08-01', '2013-08-30';
GO
/*
When you have a parameterized, reusable query, SQL Server builds the plan
based on the first set of parameters that get used.

This is called parameter sniffing.

The first set of parameters is sniffed, and used to build the cached plan.

You can see the cached plans:
*/
SELECT TOP 100 * FROM sys.dm_exec_query_stats;

SELECT * FROM sys.dm_exec_query_plan(0x050008007ED2CF48E0021C479701000001000000000000000000000000000000000000000000000000000000);
GO

/* Or the modern way - sp_BlitzCache: */
EXEC sp_BlitzCache;
GO


/*
Look at the "Cached Execution Parameters" column in sp_BlitzCache. This is
built with the plan's first set of parameters, the compiled set.


These events (and others) can cause the cached plan to go away:

 * Restarting the SQL Server
 * DBCC FREEPROCCACHE
 * Rebuilding indexes on tables in the query
 * Updating statistics on tables in the query

Let's do one of those:
*/
ALTER TABLE dbo.Users REBUILD;
GO

/* And then try the query again, but this time run Helsinki first: */
EXEC usp_SearchComments 'Helsinki, Finland', '2013-08-01', '2013-08-30';
GO
EXEC usp_SearchComments 'India', '2013-08-01', '2013-08-30';
GO

/*
When you have a slow query:

* If it doesn't have parameters, that's easy to investigate.
* If it has parameters, and it's ALWAYS slow, that's easy too.
* If it has parameters, and it's only SOMETIMES slow, that's really tricky.

I'm not going to go into details on parameter sniffing here, but I'm going to
give you a few resources on how to identify when it's happening, how to react
to parameter sniffing emergencies, and how to tune your queries to be less
susceptible to parameter sniffing:

* Free video on parameter sniffing: https://BrentOzar.com/go/sniff

* My classes: Fundamentals of Parameter Sniffing,
  Mastering Parameter Sniffing

* Long article: Slow in the Application, Fast in SSMS by Erland Sommarskog
  https://www.sommarskog.se/query-plan-mysteries.html

The reason I'm mentioning parameter sniffing, is that I just need you
to understand that you can tune a query so that it works well with some
parameters, but not others.

When you have a parameter-driven query, you need to:

 * Collect a set of parameters for tuning:
    * Commonly called ones that users care a lot about
    * Outliers with very small data sets
    * Outliers with very large data sets
    * Outliers where SQL Server estimates rows incorrectly
 * Armed with that, then you:
    * Tune indexes or queries so that one plan works better for everyone, or
    * Run the query with each set of parameters, getting its plan
    * Measure how the different plans perform with different inputs

To get the set of common parameters, you can:

* Ask the users
* Query the tables (looking for outliers)
* Check the plan cache (but these are just the compiled parameters)
* Run a Profiler trace or Extended Events session capturing them as they run

We dig more into those in the Mastering Parameter Sniffing class.

This has been a problem for decades. In SQL Server 2022,
Microsoft introduced a new feature designed to help:
Parameter-Sensitive Plan Optimization - I'll call it PSPO.
*/
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 160; /* 2022 */
GO
/* Clear the plan cache, then try the queries again: */
DBCC FREEPROCCACHE;
GO
EXEC usp_SearchComments 'Helsinki, Finland', '2013-08-01', '2013-08-30';
GO
EXEC usp_SearchComments 'India', '2013-08-01', '2013-08-30';
GO

/* Hmm, SQL Server still reused the same plans. Try the opposite order: */
DBCC FREEPROCCACHE;
GO
EXEC usp_SearchComments 'India', '2013-08-01', '2013-08-30';
GO
EXEC usp_SearchComments 'Helsinki, Finland', '2013-08-01', '2013-08-30';
GO

/* PSPO doesn't save us here. It does work
in some situations, though. To learn more:
https://www.brentozar.com/archive/2022/08/pspo-how-sql-server-2022-tries-to-fix-parameter-sniffing/
*/



/* Here's an exercise for the next break.
Say someone brought you this query to tune: */
CREATE OR ALTER PROC dbo.usp_CommentBattles 
    @UserId1 INT,
    @UserId2 INT AS
BEGIN
WITH Battles AS (SELECT c1.PostId, c1.Score AS User1Score, c2.Score AS User2Score
                    FROM dbo.Comments c1
                    INNER JOIN dbo.Comments c2 ON c1.PostId = c2.PostId AND c1.Id <> c2.Id
                    WHERE c1.UserId = @UserId1
                      AND c2.UserId = @UserId2
)
SELECT User1Victories = COALESCE(SUM(CASE WHEN b.User1Score > b.User2Score THEN 1 ELSE 0 END),0),
       User2Victories = COALESCE(SUM(CASE WHEN b.User1Score < b.User2Score THEN 1 ELSE 0 END),0),
       Draws          = COALESCE(SUM(CASE WHEN b.User1Score = b.User2Score THEN 1 ELSE 0 END),0)
  FROM Battles b;
END
GO


/* Your mission: Find outlier values for @UserId1 and @UserId2. */



/*
License: Creative Commons Attribution-ShareAlike 3.0 Unported (CC BY-SA 3.0)
More info: https://creativecommons.org/licenses/by-sa/3.0/

You are free to:
* Share - copy and redistribute the material in any medium or format
* Adapt - remix, transform, and build upon the material for any purpose, even 
  commercially

Under the following terms:
* Attribution - You must give appropriate credit, provide a link to the license,
  and indicate if changes were made.
* ShareAlike - If you remix, transform, or build upon the material, you must
  distribute your contributions under the same license as the original.
*/