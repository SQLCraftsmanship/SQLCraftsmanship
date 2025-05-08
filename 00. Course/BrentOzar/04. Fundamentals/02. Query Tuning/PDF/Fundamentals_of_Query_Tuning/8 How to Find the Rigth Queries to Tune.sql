/*
Fundamentals of Query Tuning: sp_BlitzCache Lab Setup

v1.0 - 2019-06-30

https://www.BrentOzar.com/go/queryfund


This demo requires:
* Any supported version of SQL Server
* Any Stack Overflow database: https://www.BrentOzar.com/go/querystack

Before running this setup script, restore the Stack Overflow database.

This script will take a couple of minutes to create indexes & stored procs.
*/
USE [StackOverflow2013]
GO
DropIndexes;
GO
/* Create a few indexes to support our queries: */
CREATE INDEX IX_Location ON dbo.Users(Location);
CREATE INDEX IX_UserId ON dbo.Comments(UserId);
CREATE INDEX IX_CreationDate ON dbo.Comments(CreationDate);
CREATE INDEX IX_VoteTypeId_PostId ON dbo.Votes(VoteTypeId, PostId);
GO



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


CREATE OR ALTER PROC dbo.usp_rpt_PopularLocations AS
  SELECT TOP 100 Location, COUNT(*) AS UserCount
    FROM dbo.Users u
    GROUP BY Location
    ORDER BY COUNT(*) DESC;
GO



CREATE OR ALTER PROC dbo.usp_UsersInTop5Locations AS
BEGIN
WITH TopLocations AS (SELECT TOP 5 Location
  FROM dbo.Users
  WHERE Location <> ''
  GROUP BY Location
  ORDER BY COUNT(*) DESC)
SELECT u.*
  FROM TopLocations t
    INNER JOIN dbo.Users u ON t.Location = u.Location
  ORDER BY u.DisplayName;
END
GO


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







CREATE OR ALTER PROC [dbo].[usp_rpt_ControversialPosts] AS
BEGIN
/* Source: http://data.stackexchange.com/stackoverflow/query/466/most-controversial-posts-on-the-site */
set nocount on 

declare @VoteStats table (PostId int, up int, down int);

insert @VoteStats
select
    PostId, 
    up = sum(case when VoteTypeId = 2 then 1 else 0 end), 
    down = sum(case when VoteTypeId = 3 then 1 else 0 end)
from Votes
where VoteTypeId in (2,3)
group by PostId;

select top 500 p.Id as [Post Link] , v.up, v.down 
from @VoteStats v
join Posts p on PostId = p.Id
where v.down > (v.up * 0.5) and p.CommunityOwnedDate is null and p.ClosedDate is null
order by v.up desc;
END
GO


CREATE OR ALTER PROC [dbo].[usp_UsersOutracingMe] @UserId INT AS
BEGIN
/* Source: http://data.stackexchange.com/stackoverflow/query/6925/newer-users-with-more-reputation-than-me */


SELECT u.Id as [User Link], u.Reputation, u.Reputation - me.Reputation as Difference
FROM dbo.Users me 
INNER JOIN dbo.Users u 
	ON u.CreationDate > me.CreationDate
	AND u.Reputation > me.Reputation
WHERE me.Id = @UserId

END
GO





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
MYSQL
/*
Fundamentals of Query Tuning: Run the Workload

v1.0 - 2019-06-30

https://www.BrentOzar.com/go/queryfund


This demo requires:
* Any supported version of SQL Server
* Any Stack Overflow database: https://www.BrentOzar.com/go/querystack

Before running this setup script, restore the Stack Overflow database and do
the index & stored proc setup scripts shown in the prior script.

This script will run for tens of minutes - but even if you just let it run for
a few minutes, you'll have enough stuff in your plan cache to start analysis.
You can cancel it whenever you want.
*/
USE [StackOverflow2013]
GO
DBCC FREEPROCCACHE
GO
DECLARE @Counter INT = 1
WHILE @Counter < 10
    BEGIN
    EXEC usp_rpt_PopularLocations;
    EXEC usp_UsersInTop5Locations;
    EXEC dbo.usp_CommentBattles @UserId1 = 26837, @UserId2 = 1504529;
    EXEC dbo.usp_CommentBattles @UserId1 = 505088, @UserId2 = 22656;
    EXEC dbo.usp_CommentBattles @UserId1 = 17034, @UserId2 = 22656;
    EXEC usp_UsersOutracingMe @UserId = 22656;
    EXEC usp_UsersOutracingMe @UserId = 26837;
    EXEC usp_UsersOutracingMe @UserId = 2723201;
    EXEC usp_SearchComments 'India', '2013-08-01', '2013-08-30';
    EXEC usp_SearchComments 'Helsinki, Finland', '2013-08-01', '2013-08-30';
    EXEC usp_SearchComments 'Helsinki, Finland', '2008-01-01', '2020-12-31';
    EXEC usp_SearchComments 'India', '2008-01-01', '2020-12-31';
    IF @Counter IN (4, 7, 10)
        EXEC usp_rpt_ControversialPosts;
    SET @Counter = @Counter + 1;
END


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
MYSQL
/*
Fundamentals of Query Tuning: How to Find the Right Queries to Tune

v1.1 - 2022-06-29

https://www.BrentOzar.com/go/queryfund


This demo requires:
* Any supported version of SQL Server
* Any Stack Overflow database: https://www.BrentOzar.com/go/querystack


By default, sp_BlitzCache finds your most resource-intensive queries by sorting
the plan cache by CPU. These two are the same thing:
*/
EXEC sp_BlitzCache;
GO
EXEC sp_BlitzCache @SortOrder = 'cpu';
GO


/* 
There are TONS of sort orders.

In a production environment, you'll see wildly different queries depending on
which way you sort your plan cache.

And you need to focus on the most important bottlenecks first - because you're
always going to have "bad" queries in the plan cache. The key is knowing where
to focus your tuning time.

To know that, we need to find our server's top wait type:
*/
EXEC sp_BlitzFirst @SinceStartup = 1;
GO


EXEC sp_BlitzFirst;
GO


EXEC sp_BlitzFirst @ExpertMode = 1;
GO



/*
Decoder ring for the 6 most common wait types:

CXPACKET: queries going parallel to read a lot of data or do a lot of CPU work.
Sort by CPU and by READS.

LCK%: locking, so look for long-running queries. Sort by DURATION, and look for
the warning of "Long Running, Low CPU." That's probably a query being blocked.

PAGEIOLATCH: reading data pages that aren't cached in RAM. Sort by READS.

RESOURCE_SEMAPHORE: queries can't get enough workspace memory to start running.
Sort by MEMORY GRANT, although that isn't available in older versions of SQL.

SOS_SCHEDULER_YIELD: CPU pressure, so sort by CPU.

WRITELOG: writing to the transaction log for delete/update/insert (DUI) work.
Sort by WRITES.
*/

EXEC sp_BlitzCache @SortOrder = 'reads'

/*
Note that you can also sort by averages, too:
*/
EXEC sp_BlitzCache @SortOrder = 'avg reads'
GO



/* Before you open a query plan, it's crucial to read
sp_BlitzCache's warnings. Execution plans are lying liars.
Let's prove it: */

DropIndexes;
GO
ALTER DATABASE [StackOverflow2013] SET COMPATIBILITY_LEVEL = 140
GO

CREATE OR ALTER FUNCTION dbo.fnGetPostType ( @PostTypeId INT )
RETURNS NVARCHAR(50)
    WITH RETURNS NULL ON NULL INPUT,
         SCHEMABINDING
AS
    BEGIN
        DECLARE @PostType NVARCHAR(50);
        SELECT  @PostType = [Type]
        FROM    dbo.PostTypes
        WHERE   Id = @PostTypeId;

        IF @PostType IS NULL
            SET @PostType = 'Unknown';
        RETURN @PostType;
    END;
GO

DBCC FREEPROCCACHE;
GO




/* Turn on actual plans and run this.
It'll take minutes depending on your hardware.

The first query will finish nearly instantly, 
and you can start reviewing its plan for some 
laughs before the second query finishes later.
*/
SELECT u.AboutMe, c.Text, p.Body, b.Name, v.BountyAmount
  FROM dbo.Users u
    CROSS JOIN dbo.Posts p
    CROSS JOIN dbo.Comments c
    CROSS JOIN dbo.Badges b
    CROSS JOIN dbo.Votes v
  WHERE u.Reputation + u.UpVotes < 0
  ORDER BY u.AboutMe, c.Text, p.Body, b.Name, v.BountyAmount;
GO
SELECT p.Title AS QuestionTitle, 
        dbo.fnGetPostType(p.PostTypeId) AS PostType, 
        c.CreationDate, c.Score, c.Text,
        CAST(p.CreationDate AS NVARCHAR(50)) AS QuestionDate
FROM dbo.Users u
LEFT OUTER JOIN dbo.Comments c ON u.Id = c.UserId
LEFT OUTER JOIN dbo.Posts p ON c.PostId = p.ParentId
WHERE u.DisplayName = 'Brent Ozar';
GO


/*
Some of the lies in here include:

* The costs - everywhere you see a percentage, it's an estimated cost, not the
  actual cost, even when you're looking at the actual plans. The top query's
  100% cost is meaningless.
* The missing index request - it's only showing the first one, and it's awful.
  It's suggesting we need to cover the Comments.Text field, which will double
  the size of the table.
* The arrow sizes - in estimated plans, they're based off the estimated rows
  that will be output by the operator. In actual plans, they're based off the
  number of rows READ by the operator.
* The type conversion warning - says it will affect cardinality estimate, but
  it simply can't. The CreationDate isn't used for anything but output.
* The wait stats - note the query runtime compared to the wait times.
* Contents of functions - in this case, fnGetPostType is querying the PostTypes
  table, but you don't even see that table in the plan, the stats IO, or waits.
* The SELECT tooltip's "Degree of Parallelism" implies 0, aka unlimited, but
  this query was single-threaded.


Run sp_BlitzCache and check out the query's warnings:
*/
sp_BlitzCache
GO

/* We do what we can to expose those lies. */







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
