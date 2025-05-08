/*
Fundamentals of Parameter Sniffing
How to React to Parameter Sniffing Emergencies

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


/* Put the bad plan into cache: */
usp_UsersByReputation @Reputation = 2;
GO
/* See that performance tanked: */
usp_UsersByReputation @Reputation = 1;
GO
/* Run them back and forth a few times to populate the plan cache: */
usp_UsersByReputation @Reputation = 2;
GO 5
usp_UsersByReputation @Reputation = 1;
GO 5


/* When the emergency strikes:

* Identify the one bad plan by using sp_BlitzCache
* Save the one bad plan to disk or table for later troubleshooting
* Free the one bad plan from cache
* Identify the new plan that goes in cache instead, and save the newly good
  one for later troubleshooting too
*/
sp_BlitzCache;
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