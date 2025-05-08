/*
Mastering Parameter Sniffing
1.1 How Index Tuning Reduces the Stench

v1.1 - 2022-02-08

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




/* We'll start with a fairly simple proc: */
CREATE OR ALTER PROC dbo.usp_TopScoringPostsByDate
	@StartDate DATETIME, @EndDate DATETIME AS
BEGIN
SELECT TOP 200 p.Score, p.Title, p.Body, p.Id, p.CreationDate, u.DisplayName
  FROM dbo.Posts p
  INNER JOIN dbo.Users u ON p.OwnerUserId = u.Id
  WHERE p.CreationDate BETWEEN @StartDate AND @EndDate
  ORDER BY p.Score DESC;
END
GO

/* And remember that we have this index: */
CREATE INDEX CreationDate ON dbo.Posts(CreationDate);


/* If I pass in a very selective date range, I get an index seek + key lookups: */
EXEC usp_TopScoringPostsByDate 
@StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01' WITH RECOMPILE;

/* A less selective range gets a table scan, and it's rightfully slow: */
EXEC usp_TopScoringPostsByDate 
@StartDate = '2017-01-01', @EndDate = '2017-12-31' WITH RECOMPILE;

/* We can fix this by reducing the number of key lookups we do.

We can't cover the entire query: they're asking for the Body of the post. 
That's big. But remember from Fundamentals of Index Tuning: an ORDER BY with a
TOP is basically a WHERE clause.

Armed with that, how could we reduce our key lookups?
*/











CREATE INDEX CreationDate_Score ON dbo.Posts(CreationDate, Score);
GO
/* But now think about the Posts component of the query: */
SELECT TOP 200 CreationDate, Score
  FROM dbo.Posts
  WHERE CreationDate BETWEEN '2017-12-01' AND '2017-12-31'
  ORDER BY Score DESC;
GO

/* The index is sorted by both CreationDate AND Score.

So what will our query plan look like?

/poll "The query plan will:" "Have an index seek and a TOP" "Have an index seek, then a sort by CreationDate, then a TOP" "Have an index scan" "Have a table scan" anonymous limit 1

Let's find out.
*/



/* Index visualization query: */
SELECT CreationDate, Score
  FROM dbo.Posts
  WHERE CreationDate BETWEEN '2017-12-01' AND '2017-12-31'
  ORDER BY CreationDate, Score;


/* So basically, EITHER of these indexes would have the same plan here: */
CREATE INDEX CreationDate_Score ON dbo.Posts(CreationDate, Score);
GO
CREATE INDEX CreationDate_Inc ON dbo.Posts(CreationDate) INCLUDE (Score);
GO


/* Don't get too hung up on chasing "perfect."

Perfect is the enemy of good.

Armed with either of these indexes, how does our plan look now: */
CREATE OR ALTER PROC dbo.usp_TopScoringPostsByDate
	@StartDate DATETIME, @EndDate DATETIME AS
BEGIN
SELECT TOP 200 p.Score, p.Title, p.Body, p.Id, p.CreationDate, u.DisplayName
  FROM dbo.Posts p
  INNER JOIN dbo.Users u ON p.OwnerUserId = u.Id
  WHERE p.CreationDate BETWEEN @StartDate AND @EndDate
  ORDER BY p.Score DESC;
END
GO

/* If I pass in a very selective date range, I get an index seek + key lookups: */
EXEC usp_TopScoringPostsByDate 
@StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01' WITH RECOMPILE;

/* Now try the less selective range: */
EXEC usp_TopScoringPostsByDate 
@StartDate = '2017-01-01', @EndDate = '2017-12-31' WITH RECOMPILE;
GO

/* Not so good. What if we put the tiny data plan in memory first? */
sp_recompile 'usp_TopScoringPostsByDate';
GO
EXEC usp_TopScoringPostsByDate 
@StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01';
/* Then run the big one? */
EXEC usp_TopScoringPostsByDate 
@StartDate = '2017-01-01', @EndDate = '2017-12-31';
GO




/* The problem is the location of the sort.

SQL Server usually puts the index seek + key lookup right next to each other,
and then sorts the data AFTER it finds the rows.

What if we:
1. Used the index to find the rows we want
2. Sort them
3. Did the 200 key lookups later?

To do that, we'll need to coach SQL Server. Here's one way: */
CREATE OR ALTER PROC dbo.usp_TopScoringPostsByDate_CTE
	@StartDate DATETIME, @EndDate DATETIME AS
BEGIN
WITH RowsIWant AS (SELECT TOP 200 p.Score, p.CreationDate, p.Id
					FROM dbo.Posts p
					WHERE p.CreationDate BETWEEN @StartDate AND @EndDate
					ORDER BY p.Score DESC
)

SELECT TOP 200 pKeyLookup.Score, pKeyLookup.Title, pKeyLookup.Body, 
	pKeyLookup.Id, pKeyLookup.CreationDate, u.DisplayName
  FROM RowsIWant r
  INNER JOIN dbo.Posts pKeyLookup ON r.Id = pKeyLookup.Id
  INNER JOIN dbo.Users u ON pKeyLookup.OwnerUserId = u.Id
  ORDER BY r.Score DESC;
END
GO
sp_recompile 'usp_TopScoringPostsByDate_CTE';
GO
EXEC usp_TopScoringPostsByDate_CTE 
@StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01';
/* Then run the big one? */
EXEC usp_TopScoringPostsByDate_CTE 
@StartDate = '2017-01-01', @EndDate = '2017-12-31';
GO


/* It's kinda like an index hint, but without naming the index.

Sometimes a CTE won't work, and you need to break it up with temp tables: */
CREATE OR ALTER PROC dbo.usp_TopScoringPostsByDate_TempTables
	@StartDate DATETIME, @EndDate DATETIME AS
BEGIN
CREATE TABLE #RowsIWant (Id INT);
INSERT INTO #RowsIWant (Id)
	SELECT TOP 200 p.Id
		FROM dbo.Posts p
		WHERE p.CreationDate BETWEEN @StartDate AND @EndDate
		ORDER BY p.Score DESC;

SELECT TOP 200 pKeyLookup.Score, pKeyLookup.Title, pKeyLookup.Body, 
	pKeyLookup.Id, pKeyLookup.CreationDate, u.DisplayName
  FROM #RowsIWant r
  INNER JOIN dbo.Posts pKeyLookup ON r.Id = pKeyLookup.Id
  INNER JOIN dbo.Users u ON pKeyLookup.OwnerUserId = u.Id
  ORDER BY pKeyLookup.Score DESC;
END
GO
sp_recompile 'usp_TopScoringPostsByDate_TempTables';
GO
EXEC usp_TopScoringPostsByDate_TempTables 
@StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01';
/* Then run the big one */
EXEC usp_TopScoringPostsByDate_TempTables 
@StartDate = '2017-01-01', @EndDate = '2017-12-31';
GO

/* You can still have outliers though: */
EXEC usp_TopScoringPostsByDate 
@StartDate = '1970-01-01', @EndDate = '2039-12-31';
/* If you needed to make THAT fast, then you really need two different plans.
   More on that later. */


/* Fixing parameter sniffing with indexes is all about giving SQL Server a
narrower copy of the data to reduce the blast radius.

Sometimes we have to encourage SQL Server to use the index by breaking the
work up into different phases.

WE STILL HAVE PARAMETER SNIFFING. These plans can have different:
* Parallelism
* Memory grants

But they will at least look CLOSER than they looked before, and it may not
matter AS MUCH which one goes in first.

If your biggest challenge in a parameter sniffing problem is deciding between
an index seek vs key lookup, your goal is to reduce the number of key lookups
that SQL Server is forced to do. Give it enough in the index to let it do the
filtering necessary.

The index helps you find the rows you want.

Once you've found the rows you want, 100-10,000 key lookups isn't a big deal
at all (and the numbers may go even higher on bigger databases.) Although if
someone says they want more than 10,000 rows on a single report, I'm like look,
buddy, it's time to do table scans.

That was a relatively simple filtering problem on one table:
*/
GO
CREATE OR ALTER PROC dbo.usp_TopScoringPostsByDate
	@StartDate DATETIME, @EndDate DATETIME AS
BEGIN
SELECT TOP 200 p.Score, p.Title, p.Body, p.Id, p.CreationDate, u.DisplayName
  FROM dbo.Posts p
  INNER JOIN dbo.Users u ON p.OwnerUserId = u.Id
  WHERE p.CreationDate BETWEEN @StartDate AND @EndDate
  ORDER BY p.Score DESC;
END
GO


/* But what if the choice is between TWO indexes? */
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


/* If we call it for a narrow date range, we can do our filtering on the index: */
EXEC usp_TopScoringPostsByDateAndScore 
	@StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01',
	@MinimumScore = 1 WITH RECOMPILE;
GO

/* But if we call it for a wide date range, and a narrow score filter: */
EXEC usp_TopScoringPostsByDateAndScore 
	@StartDate = '2016-01-01', @EndDate = '2016-12-31',
	@MinimumScore = 10000 WITH RECOMPILE;
GO


/* Now, an index on Score would be way more effective - because there just
aren't a lot of rows that match that narrow predicate.

If we had an index on Score, CreationDate: */
CREATE INDEX Score_CreationDate ON dbo.Posts(Score, CreationDate);
GO

/* Then SQL Server will pick it when the score is very selective: */
EXEC usp_TopScoringPostsByDateAndScore 
	@StartDate = '2016-01-01', @EndDate = '2016-12-31',
	@MinimumScore = 10000 WITH RECOMPILE;
GO


/* But not when the date is very selective, and the score isn't: */
EXEC usp_TopScoringPostsByDateAndScore 
	@StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01',
	@MinimumScore = 1 WITH RECOMPILE;
GO



/* Here we have a NEW problem.

Our problem is NOT choosing between an index seek + key lookup vs a table scan.

Our problem is choosing between TWO DIFFERENT INDEXES on the same table.

Index tuning doesn't help here.




And let's take it up a notch and filter on two tables at once: */
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
/* That's actually really similar to the above proc - but now, SQL Server's
biggest challenge is determining WHICH TABLE to process first, and THEN which
index to use on that table.


When the User.Location is very selective, 
it makes sense to find the users in that location first, then look up their posts.

When the Post.CreationDate range is very selective,
it makes sense to find the posts in that date range first,
then look up the users to see if they match.

If BOTH are very selective, it doesn't really matter which plan we pick.

If NEITHER is very selective, we'll probably end up with table scans.

Index tuning alone isn't going to be enough here: when SQL Server has to choose
which table to process first, indexing each table isn't going to be enough.




What to take away from this demo:

* If the biggest problem you're trying to solve is the choice between
  an index seek + key lookup versus a table scan,
  your goal is to find the parts of the filtering & sorting that require key
  lookups, and see if you can move those to the index instead.

* Even the index alone may not cut it: if we can't fully cover the query, we
  may need to break the query into phases so that we can do a sort before we
  do a key lookup.

* If the biggest problem is choosing between two indexes on the same table,
  index tuning can help, but it's probably not going to be the only solution
  by itself. We're probably also going to have to introduce branching logic
  or a recompile hint to let ourselves get different query plans for different
  sets of parameters.

* If the biggest problem you're trying to solve is which table to process first
  because different parameters should focus on different tables, indexes alone
  won't be enough.
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