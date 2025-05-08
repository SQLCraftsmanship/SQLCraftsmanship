/*
Fundamentals of Parameter Sniffing
How SQL Server 2022 Fixes Easy Sniffing Problems

v1.0 - 2022-06-06

This demo requires:
* SQL Server 2022 or newer
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
EXEC sys.sp_configure N'cost threshold for parallelism', N'50' /* Keep small queries serial */
GO
EXEC sys.sp_configure N'max degree of parallelism', N'4' /* Let queries go parallel */
GO
RECONFIGURE
GO
SET STATISTICS IO, TIME ON;
GO
CREATE INDEX IX_Reputation ON dbo.Users(Reputation)
GO
CREATE OR ALTER PROCEDURE dbo.usp_UsersByReputation
  @Reputation int
AS
SELECT TOP 10000 *
FROM dbo.Users
WHERE Reputation=@Reputation
ORDER BY DisplayName;
GO

/* So far, we've had problems running these back to back: */
EXEC dbo.usp_UsersByReputation @Reputation =1;
GO
EXEC dbo.usp_UsersByReputation @Reputation =2;
GO

/* SQL Server 2022 introduces a new fix:
Parameter Sensitive Plan (PSP) Optimization.
To enable it, go into 2022 compat level: */
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 160; /* 2022 */
GO


/* Turn on actual plans and try the first one: */
EXEC dbo.usp_UsersByReputation @Reputation =1;
GO
/* Right-click on the Select, click Properties:
* Dispatcher
* Statistics Info

Try the next reputation: */
EXEC dbo.usp_UsersByReputation @Reputation =2;
GO
/* Check Dispatcher, Statistics Info again.

Another: */
EXEC dbo.usp_UsersByReputation @Reputation =3;
GO
/* Note:
* Estimated vs actual
* Memory grant on sort
* Query text with hint

Another: */
EXEC dbo.usp_UsersByReputation @Reputation =0;
GO
/* Note:
* Estimated vs actual
* Memory grant on sort
* Query text with hint

So how's this look in the plan cache?
*/
sp_BlitzCache;
GO
/* Note: statements are no longer linked
to their parent stored procedure.

This basically breaks all monitoring tools.
The tools still work - but they have no idea
what's calling the query. */



/* Some query-level hints will turn it off: */
CREATE OR ALTER PROCEDURE dbo.usp_UsersByReputation
  @Reputation int
AS
SELECT TOP 10000 *
FROM dbo.Users
WHERE Reputation=@Reputation
ORDER BY DisplayName
OPTION (RECOMPILE) /* ADDED THIS */;
GO
EXEC dbo.usp_UsersByReputation @Reputation =1;
GO


/* And you can turn it off manually: */
CREATE OR ALTER PROCEDURE dbo.usp_UsersByReputation
  @Reputation int
AS
SELECT TOP 10000 *
FROM dbo.Users
WHERE Reputation=@Reputation
ORDER BY DisplayName
OPTION (DISABLE_OPTIMIZED_PLAN_FORCING) /* THIS IS NEW */;
GO
EXEC dbo.usp_UsersByReputation @Reputation =1;
GO
/* Well, Books Online says that'll work, at least:
https://docs.microsoft.com/en-us/sql/t-sql/queries/hints-transact-sql-query?view=sql-server-ver16

But a lot is still in flux:
* How it'll actually work at release time
* Whether Microsoft will fix the statement identification
* How it'll affect the total number of cached plans available
* If it'll be Enterprise Edition only

And even then, it only fixes the simplest
equality searches. It doesn't work on things
like ranges: */
CREATE OR ALTER PROCEDURE dbo.usp_UsersByReputation
  @MinReputation int, @MaxReputation int
AS
SELECT TOP 10000 *
FROM dbo.Users
WHERE Reputation BETWEEN @MinReputation AND @MaxReputation
ORDER BY DisplayName;
GO
EXEC dbo.usp_UsersByReputation 150, 151;
GO
/* Note plan shape, est rows, then: */
EXEC dbo.usp_UsersByReputation 1, 2;
GO


/* Our jobs are safe for another decade. */



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