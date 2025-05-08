/*
Fundamentals of TempDB: How Execution Plans Use TempDB
v1.0 - 2020-12-06
https://www.BrentOzar.com/go/tempdbfun


This demo requires:
* SQL Server 2016 or newer
* Any Stack Overflow database: https://www.BrentOzar.com/go/querystack

This first RAISERROR is just to make sure you don't accidentally hit F5 and
run the entire script. You don't need to run this:
*/
RAISERROR(N'Oops! No, don''t just hit F5. Run these demos one at a time.', 20, 1) WITH LOG;
GO
USE StackOverflow2013;
GO
/* Use the newest compat level your server supports,
but not SQL Server 2019 yet.
130 = 2016, 140 = 2017. */
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 130;
GO
DropIndexes;
GO
CREATE INDEX IX_OwnerUserId ON dbo.Posts(OwnerUserId) INCLUDE (Score, Title);
GO



CREATE OR ALTER PROC dbo.usp_UsersInTopLocation AS
BEGIN
WITH TopLocation AS (SELECT TOP 1 Location
  FROM dbo.Users
  WHERE Location <> ''
  GROUP BY Location
  ORDER BY COUNT(*) DESC)
SELECT u.*
  FROM TopLocation
    INNER JOIN dbo.Users u ON TopLocation.Location = u.Location
  ORDER BY DisplayName;
END
GO
 
/* Run this with actual plans on: */
DBCC FREEPROCCACHE;

EXEC usp_UsersInTopLocation
GO
/* Things to discuss:

* Estimates vs actuals through query
* Memory grant: ____ KB
* Memory used: ____ KB
* How many operators spilled

Run it again. Do things improve? 



To find queries having the problem, turn off actual plans and run:
*/
sp_BlitzCache @SortOrder = 'spills'
/* Things to note:
* Memory grant: granted, used
* Spills: min, max, total, avg

In this case, adding more memory won't help:
the query just doesn't want enough memory.

To learn a few ways to fix it with index & query
tuning, watch my Fundamentals of Query Tuning:
https://BrentOzar.com/go/queryfund


SQL Server 2019 has a way to fix it though:
*/
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 150;
ALTER DATABASE SCOPED CONFIGURATION SET LAST_QUERY_PLAN_STATS = ON;
GO
DBCC FREEPROCCACHE;

EXEC usp_UsersInTopLocation
GO
/* Things to discuss:

* Estimates vs actuals through query
* Memory grant: ____ KB (is this higher?)
* Memory used: ____ KB
* How many operators spilled

Now we have a different problem:
we got granted too much memory!

Try running it a few more times to see
if it gets better/worse: */
EXEC usp_UsersInTopLocation
GO 10

/* Turn off actual plans: */
sp_BlitzCache;
GO
/* Look at these columns:
* Minimum Memory Grant KB
* Maximum Memory Grant KB

* Minimum Used Grant KB
* Maximum Used Grant KB

* Spills - min, max, total, avg


That's a query that behaves the same way every
time because it doesn't have parameters. If we
use a more complex proc:
*/
CREATE OR ALTER PROC dbo.usp_UsersByReputation @Reputation INT AS
    SELECT TOP 100000 u.Id, p.Title, p.Score
        FROM dbo.Users u
        JOIN dbo.Posts p ON p.OwnerUserId = u.Id
        WHERE u.Reputation = @Reputation
        ORDER BY p.Score DESC;
GO
 
/* And run it: */
DBCC FREEPROCCACHE;

/* Turn on actual plans: */ 
EXEC usp_UsersByReputation @Reputation = 1;
GO
 
 
 
/* Check out that adaptive join:
* Adaptive threshold in tooltip
* Over threshold: do an index scan
* Under: do a seek

* Also, note that nothing spills.
 
Try another reputation: */
EXEC usp_UsersByReputation @Reputation = 2;
GO
/* It chooses the seek, but...we have a yellow bang.

SQL Server is about to adjust the memory grant
downwards because we left too much unused. Try
it again: */
EXEC usp_UsersByReputation @Reputation = 2;

/* And the memory grant goes down.

But now try the big one again: */
EXEC usp_UsersByReputation @Reputation = 1;
GO


/* Turn OFF actual plans, and: */
sp_BlitzCache
/* Look at the:

* Query plan - last actual plan enabled
* Min/max memory grants
* Spills (!!!)
*/


/* Takeaways from this:

* This TempDB consumer is particularly hard to
  predict: it's different on a query-by-query
  basis, and changes with SQL Server versions.

* Microsoft's trying to make it better with
  adaptive memory grants, but right now, it's
  worse instead of better.

* To look for queries causing spills, run: 
  sp_BlitzCache @SortOrder = 'spills'

* In their plans, look for:
  * Sorts
  * Hash matches
  * Adaptive joins

During the break, check your own production
server's plan cache to see which queries have
been spilling the most to disk:
*/
sp_BlitzCache @SortOrder = 'spills';
GO
/* And scroll across to the Total Spills column. */



/*
License: Creative Commons Attribution-ShareAlike 4.0 Unported (CC BY-SA 4.0)
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
* No additional restrictions — You may not apply legal terms or technological 
  measures that legally restrict others from doing anything the license permits.
*/