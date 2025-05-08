/*
Fundamentals of Parameter Sniffing
Mo Choices, Mo Problems

v1.1 - 2020-05-26

https://www.BrentOzar.com/go/snifffund


This demo requires:
* SQL Server 2016 or newer
* 50GB Stack Overflow 2013 database: https://www.BrentOzar.com/go/querystack

This first RAISERROR is just to make sure you don't accidentally hit F5 and
run the entire script. You don't need to run this:
*/
RAISERROR(N'Oops! No, don''t just hit F5. Run these demos one at a time.', 20, 1) WITH LOG;
GO


/* Continue this demo after running the prior module.
  We're reusing the same setups from there.

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

So:
* The more parameters you have,
* And the more tables you join,
* And the more features SQL Server could use (like adaptive joins and batch mode),
* The more possible plans you have,
* And the worse parameter sniffing becomes.

For example, if I add an index on Posts:
*/
CREATE INDEX CreationDate ON dbo.Posts(CreationDate);
GO


/* Here's our proc text as a reminder - note that it's ordering by CreationDate DESC: */
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

/* Does this give us even more possible plans? Do any of these use the new index? */

EXEC usp_SearchPostsByLocation 'India' WITH RECOMPILE; /* Big data */

EXEC usp_SearchPostsByLocation 'Netherlands' WITH RECOMPILE; /* Middle data */

EXEC usp_SearchPostsByLocation 'Near Stonehenge' WITH RECOMPILE; /* Small data */

EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao' WITH RECOMPILE; /* Outlier: few people, many posts */
GO




/* And what if our stored procedure gets more complex? */
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