/*
Fundamentals of Parameter Sniffing
The Kinds of Queries that are Susceptible to Parameter Sniffing

v1.0 - 2020-04-30

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


/* Add a few indexes to let SQL Server choose: */
CREATE INDEX Location ON dbo.Users(Location);
CREATE INDEX OwnerUserId ON dbo.Posts(OwnerUserId);
GO


/* A bad query, but... */
CREATE OR ALTER PROC dbo.usp_SearchPostsByLocation @Location VARCHAR(100) AS
BEGIN
/* Find the most recent posts from an area */
SELECT TOP 200 u.DisplayName, p.Title, p.Id, p.CreationDate
  FROM dbo.Posts p
  INNER JOIN dbo.Users u ON p.OwnerUserId = u.Id
  WHERE UPPER(u.Location) LIKE UPPER(@Location)
  ORDER BY p.CreationDate DESC
END
GO



/* Big data */
EXEC usp_SearchPostsByLocation 'India' WITH RECOMPILE;

/* Middle data */
EXEC usp_SearchPostsByLocation 'Netherlands' WITH RECOMPILE;

/* Small data */
EXEC usp_SearchPostsByLocation 'Near Stonehenge' WITH RECOMPILE;
GO

/* In this case, all parameters produce the same execution plan.

This isn't parameter sniffing: it's the exact OPPOSITE.
We always get the SAME plan.

This isn't parameter sniffing: it's just a plain ol' bad execution plan because
of the explicit conversion: */
  WHERE UPPER(u.Location) LIKE UPPER(@Location)
GO


/* 
Which means we get:
* Consistently bad estimates
* Scans instead of seeks
* Huge memory grants
* Huge parallelism waits even to produce a tiny amount of rows


And you would probably want to fix that. You could fix it by removing the
explicit conversion since this database isn't case senstive anyway: */


/* Better version, but... */
CREATE OR ALTER PROC dbo.usp_SearchPostsByLocation @Location VARCHAR(100) AS
BEGIN
/* Find the most recent posts from an area */
SELECT TOP 200 u.DisplayName, p.Title, p.Id, p.CreationDate
  FROM dbo.Posts p
  INNER JOIN dbo.Users u ON p.OwnerUserId = u.Id
  WHERE u.Location LIKE @Location			/* No explicit conversion */
  ORDER BY p.CreationDate DESC
END
GO




/* Big data */
EXEC usp_SearchPostsByLocation 'India' WITH RECOMPILE;

/* Middle data */
EXEC usp_SearchPostsByLocation 'Netherlands' WITH RECOMPILE;

/* Small data */
EXEC usp_SearchPostsByLocation 'Near Stonehenge' WITH RECOMPILE;
GO



/* And NOW we're troubleshooting parameter sniffing.

Parameter sniffing requires two things:

1. Sniffed parameters, AND
2. Different execution plans.

The first one is easy. But what produces the second one? Decisions:

WHERE:

* How many rows will come out?

SELECT:

* What columns do we need, and which indexes have them?
* Should we do an index seek w/key lookup, or a table scan?

FROM, JOIN:

* Which table should we process first?
* How many rows will we find in the rest of the tables?
* How will we access those tables: seek + key lookup, or scan?

GROUP BY, ORDER BY:

* How many rows will be involved?
* How much memory should we grant? (How much data will we need to sort?)
* How many threads should we use? (Meaning, how much work needs to be done?)


In our simple query here, with India and Near Stonehenge, SQL Server produces
the right estimates, so we basically have two different plans, both of which
have correct estimates.

However, there's another level. For every one of those questions, think about:

* What would cause the estimates to be too low?
* What would cause the estimates to be too high?


Take another look at our query:
*/
CREATE OR ALTER PROC dbo.usp_SearchPostsByLocation @Location VARCHAR(100) AS
BEGIN
/* Find the most recent posts from an area */
SELECT TOP 200 u.DisplayName, p.Title, p.Id, p.CreationDate
  FROM dbo.Posts p
  INNER JOIN dbo.Users u ON p.OwnerUserId = u.Id
  WHERE u.Location LIKE @Location
  ORDER BY p.CreationDate DESC
END
GO


/* What if SQL Server guessed the right number of Users, but:

* That location never posted any questions or answers (has no rows in Posts), or
* That location posted WAY more questions or answers than average

Let's find outliers: first, popular locations with no posts:
*/
SELECT u.Location, COUNT(DISTINCT u.Id) AS UserCount
FROM dbo.Users u
  LEFT OUTER JOIN dbo.Posts p ON u.Id = p.OwnerUserId
GROUP BY u.Location
HAVING COUNT(DISTINCT P.Id) = 0
ORDER BY COUNT(DISTINCT u.Id) DESC;
GO


/* And try a few of those: */
EXEC usp_SearchPostsByLocation 'Almaty, Almaty Region, Kazakhstan' WITH RECOMPILE;
EXEC usp_SearchPostsByLocation 'Surabaya, Republik Indonesia' WITH RECOMPILE;
EXEC usp_SearchPostsByLocation 'Yokohama' WITH RECOMPILE;






/* Then, one-person locations with a ton of posts: */
SELECT TOP 100 Location, COUNT(DISTINCT u.Id) AS UserCount, COUNT(DISTINCT p.Id) AS PostCount 
FROM dbo.Users u
INNER JOIN dbo.Posts p ON u.Id = p.OwnerUserId
GROUP BY u.Location
HAVING COUNT(DISTINCT u.Id) = 1
ORDER BY COUNT(DISTINCT p.Id) DESC;

/* And try a few of those: */
EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao' WITH RECOMPILE;
EXEC usp_SearchPostsByLocation 'Forest of Dean, United Kingdom' WITH RECOMPILE;
EXEC usp_SearchPostsByLocation 'Västervåla, Sweden' WITH RECOMPILE;


/* Ah-ha! 

Now we have TWO separate problems:
1. Parameter sniffing
2. Incorrect estimates for SOME parameters



If India goes in first:
* The small locations suffer
* India does fine
* The outlier locations do fine

If the small locations go in first:
* The small locations do fine
* India suffers
* The outlier locations suffer

If the outlier locations go in first:
* The small locations do fine
* India suffers
* The outlier locations suffer
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