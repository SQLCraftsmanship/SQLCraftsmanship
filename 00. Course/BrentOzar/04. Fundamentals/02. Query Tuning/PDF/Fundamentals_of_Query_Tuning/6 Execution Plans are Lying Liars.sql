/*
EXECUTION PLANS ARE LYING LIARS

v1.3 - 2023-11-05

https://www.BrentOzar.com/go/queryfund


Here's what you're going to learn in this demo:

* The parts of execution plans that you can't trust
* How to use sp_BlitzCache to find which queries to focus on
* Why it's so important to read the warnings before opening a plan

We are NOT going to tune the queries you're about to see.
I crafted these queries just to show you how much SQL Server lies.

This demo requires:
* Any supported version of SQL Server
* Any Stack Overflow database: https://www.BrentOzar.com/go/querystack

This first RAISERROR is just to make sure you don't accidentally hit F5 and
run the entire script. You don't need to run this:
*/
RAISERROR(N'Oops! No, don''t just hit F5. Run these demos one at a time.', 20, 1) WITH LOG;
GO



/* Set things up */
USE StackOverflow2013;
GO
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




/*
I hate to be the one to break this to you, but query plans lie to you. A lot.

Turn on actual plans and run this - it's going to take 1-3 minutes (or more)
depending on your server's hardware. The first query will finish nearly
instantly, and you can start reviewing its plan for some laughs before the
second query finishes minutes later.
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
*/






/*
                             @@@
                             @@@
                              @@@
                              @@@
                      @@@@@@@@@@@@@@@@@@@@@@ 
                    @@@@@@@@@@@@@@@@@@@@@@@@@@
                  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                @@@@@@@@ @@@@@@@@@@@@@@@@ @@@@@@@@
              @@@@@@@@@   @@@@@@@@@@@@@@   @@@@@@@@@
            @@@@@@@@@@     @@@@@@@@@@@@     @@@@@@@@@@
           @@@@@@@@@@       @@@@  @@@@       @@@@@@@@@@
           @@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@
           @@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@
           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
           @@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@
            @@@@@@@@  @@ @@ @@ @@ @@ @@ @@ @  @@@@@@@@
              @@@@@@@                        @@@@@@@
                @@@@@@  @@ @@ @@ @@ @@ @@ @ @@@@@@
                  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                    @@@@@@@@@@@@@@@@@@@@@@@@@@
                      @@@@@@@@@@@@@@@@@@@@@@




                             MUHAHAHA

I do *use* execution plans for tuning.

They're just not where I *start*.


To show you where I start, turn off actual query plans, and run sp_BlitzCache:
*/
sp_BlitzCache @SortOrder = 'cpu'
GO



/*
sp_BlitzCache lists the queries in your plan cache, and what's wrong with them.
Other useful sort orders include reads, executions, memory grant, and duration.

My tuning work involves:
* Running sp_BlitzCache to figure out which queries I need to focus on first
* Reading the warnings list to know what to look for when I open the plan
* Open the plan, but then read it with a suspicious eye
*/



/* SQL Server 2019 does help one thing though - the function gets inlined: */
ALTER DATABASE [StackOverflow2013] SET COMPATIBILITY_LEVEL = 150
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
To learn more about this topic, here are a few links:

Compare Showplan feature:
https://blogs.msdn.microsoft.com/sql_server_team/comparison-tool-released-with-latest-ssms/
Open two query plans in SSMS, and compare them to see differences. Great for
before/after checks or A/B testing, especially when changing indexes for the
same query.

Watch Brent Tune Queries:
https://www.BrentOzar.com/go/tunequeries
Free video series where I walk you through tuning a query, showing different
tools that I use.

Official SQL Server Management Studio blog:
https://cloudblogs.microsoft.com/sqlserver/?product=sql-server-management-studio
When Microsoft releases new features in SSMS, they tend to blog about it here.
*/










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