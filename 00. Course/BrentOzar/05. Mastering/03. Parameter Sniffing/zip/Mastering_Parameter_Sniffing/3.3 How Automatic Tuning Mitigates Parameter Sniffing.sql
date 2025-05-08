/*
Mastering Parameter Sniffing
How Automatic Tuning Mitigates Parameter Sniffing

v1.3 - 2021-04-28

https://www.BrentOzar.com/go/mastersniffing


This demo requires:
* SQL Server 2017 or newer
* 2018-06 Stack Overflow database: https://www.BrentOzar.com/go/querystack

This first RAISERROR is just to make sure you don't accidentally hit F5 and
run the entire script. You don't need to run this:
*/
RAISERROR(N'Oops! No, don''t just hit F5. Run these demos one at a time.', 20, 1) WITH LOG;
GO

/* Set the stage with the right server options & database config: */
USE StackOverflow;
GO
EXEC DropIndexes @TableName = 'Posts', @ExceptIndexNames = 'CreationDate_Score';
GO
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Posts') AND name = 'CreationDate_Score')
	CREATE INDEX CreationDate_Score ON dbo.Posts(CreationDate, Score);
GO




/* Turn on Query Store with ridiculously frequent capture settings,
BUT ONLY FOR DEMO PURPOSES. YOU SHOULD NEVER LOG EVERY MINUTE.
*/
ALTER DATABASE [StackOverflow] SET QUERY_STORE = ON
GO
ALTER DATABASE [StackOverflow] SET QUERY_STORE 
	(OPERATION_MODE = READ_WRITE, 
	DATA_FLUSH_INTERVAL_SECONDS = 60, 
	INTERVAL_LENGTH_MINUTES = 1)
GO
ALTER DATABASE [StackOverflow] SET QUERY_STORE CLEAR;
GO
ALTER DATABASE CURRENT
SET AUTOMATIC_TUNING ( FORCE_LAST_GOOD_PLAN = OFF ); 
GO




CREATE OR ALTER PROC dbo.usp_SearchPostsToAnswer 
	@ScoreMin INT, 
	@AnswerCountMin INT, 
	@CommentCountMin INT AS
SELECT TOP 1000 *
  FROM dbo.Posts
  WHERE Score >= @ScoreMin
    AND AnswerCount >= @AnswerCountMin
	AND CommentCount >= @CommentCountMin
  ORDER BY CreationDate DESC;
GO

/* These get different execution plans: */
EXEC usp_SearchPostsToAnswer 1, 0, 0 WITH RECOMPILE; /* Single-threaded */
EXEC usp_SearchPostsToAnswer 250, 10, 10 WITH RECOMPILE; /* Single-threaded */
EXEC usp_SearchPostsToAnswer 1000, 10, 10 WITH RECOMPILE; /* Parallel */
GO


/* So depending on which one goes in first,
we have different parameter sniffing issues: */

sp_recompile 'usp_SearchPostsToAnswer'
GO
EXEC usp_SearchPostsToAnswer 1, 0, 0
EXEC usp_SearchPostsToAnswer 250, 10, 10
EXEC usp_SearchPostsToAnswer 1000, 10, 10 /* Used to be parallel */
GO

sp_recompile 'usp_SearchPostsToAnswer'
GO
EXEC usp_SearchPostsToAnswer 250, 10, 10
EXEC usp_SearchPostsToAnswer 1, 0, 0
EXEC usp_SearchPostsToAnswer 1000, 10, 10


sp_recompile 'usp_SearchPostsToAnswer'
GO
EXEC usp_SearchPostsToAnswer 1000, 10, 10 /* Parallel */
EXEC usp_SearchPostsToAnswer 250, 10, 10
EXEC usp_SearchPostsToAnswer 1, 0, 0 /* Uh oh (doesn't need to finish) */
GO






/* Automatic tuning is supposed to fix this: */
ALTER DATABASE CURRENT
SET AUTOMATIC_TUNING ( FORCE_LAST_GOOD_PLAN = ON ); 
GO


/* Start with the single-threaded small data plan
so that we have a "good" plan in history: */
sp_recompile 'usp_SearchPostsToAnswer'
GO
EXEC usp_SearchPostsToAnswer 1, 0, 0
GO 5
EXEC usp_SearchPostsToAnswer 250, 10, 10
GO 5
EXEC usp_SearchPostsToAnswer 1000, 10, 10
GO 5

/* Rebuild an index, which also updates stats,
which also frees the plan from cache: */
ALTER INDEX CreationDate_Score ON dbo.Posts REBUILD;
GO


/* Now put the parallel plan in cache: */
EXEC usp_SearchPostsToAnswer 1000, 10, 10
GO 5
EXEC usp_SearchPostsToAnswer 250, 10, 10
GO 5

/* But unfortunately, this will take several minutes...
or will it? */
EXEC usp_SearchPostsToAnswer 1, 0, 0
GO 5


/* Go check out top resource consuming queries
in the Query Store reports. */


/* See what automatic tuning is up to: */
SELECT reason, score,
      script = JSON_VALUE(details, '$.implementationDetails.script'),
      planForceDetails.*,
      estimated_gain = (regressedPlanExecutionCount + recommendedPlanExecutionCount)
                  * (regressedPlanCpuTimeAverage - recommendedPlanCpuTimeAverage)/1000000,
      error_prone = IIF(regressedPlanErrorCount > recommendedPlanErrorCount, 'YES','NO')
FROM sys.dm_db_tuning_recommendations
CROSS APPLY OPENJSON (Details, '$.planForceDetails')
    WITH (  [query_id] int '$.queryId',
            regressedPlanId int '$.regressedPlanId',
            recommendedPlanId int '$.recommendedPlanId',
            regressedPlanErrorCount int,
            recommendedPlanErrorCount int,
            regressedPlanExecutionCount int,
            regressedPlanCpuTimeAverage float,
            recommendedPlanExecutionCount int,
            recommendedPlanCpuTimeAverage float
          ) AS planForceDetails;
GO


/* What to take away from this demo:

Automatic Tuning aka Automatic Plan Forcing requires:

* Query Store turned on for the database
* AUTOMATIC_TUNING ( FORCE_LAST_GOOD_PLAN = ON ) for the database
* At least 2 different query plans in Query Store's
  captured history

Then, when a query uses way more CPU:

* The query has to finish executing
  (this doesn't change mid-flight)
* Query Store will try forcing one of the previous plans

But Automatic Tuning doesn't work as well when:

* Anything changes about the query - because it'll
  have a new hash, and the previous plans won't be
  linked to it - which also means forced plans are
  time bombs for developers
* You only have one plan in the history
* You've never run those outlier parameters before
* When there isn't one plan that works well for
  all of the parameters (which is what we typically
  run into in this class)
* You can't turn on Query Store

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