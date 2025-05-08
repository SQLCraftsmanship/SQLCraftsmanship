/*
Mastering Parameter Sniffing
How Adaptive Joins Help, and How to Get 'Em

v1.1 - 2020-08-07

https://www.BrentOzar.com/go/mastersniffing


This demo requires:
* SQL Server 2017 or newer for columnstore indexes, 2019 for rowstore
* 2018-06 Stack Overflow database: https://www.BrentOzar.com/go/querystack


Restore your database to its default indexed configuration before this demo.


This first RAISERROR is just to make sure you don't accidentally hit F5 and
run the entire script. You don't need to run this:
*/
RAISERROR(N'Oops! No, don''t just hit F5. Run these demos one at a time.', 20, 1) WITH LOG;
GO
USE StackOverflow;
GO
EXEC sys.sp_configure N'cost threshold for parallelism', N'50' /* Keep small queries serial */
GO
EXEC sys.sp_configure N'max degree of parallelism', N'4' /* Let queries go parallel */
GO
RECONFIGURE
GO
/* Rename an obscure index to make it easier to understand the demo: */
sp_rename N'dbo.Posts._dta_index_Posts_5_85575343__K14_K16_K7_K1_K2_17', 
	N'OwnerUserId_PostTypeId_CommunityOwnedDate_AcceptedAnswerId_Inc', N'index';
GO


/* Let's start with 2017: */
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 140;
GO

/* And we'll build a parameter-sensitive proc: */
CREATE OR ALTER PROC dbo.usp_TopScoringPostsByReputation @Reputation INT AS
    SELECT TOP 100000 u.Id, p.Score, AcceptedAnswerId
        FROM dbo.Users u
        JOIN dbo.Posts p ON p.OwnerUserId = u.Id
        WHERE u.Reputation = @Reputation
        ORDER BY p.Score DESC;
GO

/* And run it with a few different parameters to see if it has different plan choices: */
EXEC usp_TopScoringPostsByReputation @Reputation = 1 WITH RECOMPILE;
EXEC usp_TopScoringPostsByReputation @Reputation = 2 WITH RECOMPILE; 
EXEC usp_TopScoringPostsByReputation @Reputation = 4 WITH RECOMPILE; 
GO

/* The number of rows we find in Users will dramatically impact the next thing
SQL Server decides to do.

Starting with SQL Server 2019, he understands that, and he has a new join type:
*/
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 150; /* 2019 */
GO
EXEC usp_TopScoringPostsByReputation @Reputation = 1;
GO



/* Check out that adaptive join:
* Adaptive threshold in tooltip
* Over threshold: do an index scan
* Under: do a seek



Try another reputation, and it chooses the seek: */
EXEC usp_TopScoringPostsByReputation @Reputation = 2;
GO


/* 
THAT IS AWESOME! Good stuff:
* It's like caching two plans
* Even better, you get just one line in the plan cache with total metrics

Not-so-good stuff:
* Only works for SELECTS, not modifications
* Compat mode 140 or higher (can't hint for this in lower compat levels)
* Query has to be in batch mode (either 2017 w/a columnstore index, or 2019)
* It doesn't replace branching logic: it doesn't pick which table to process
  first or which index to use on a table


Really, really bad stuff - run it again:
*/
EXEC usp_TopScoringPostsByReputation @Reputation = 1;
GO


/* What's causing this?


ARGH, our arch-nemesis. I wish that feature would just be disabled on adaptive
joins because after all, they're adaptive BECAUSE the amount of data keeps
changing back and forth. They're going to constantly spill. If you know you're
going to get adaptive joins on a plan, then this is probably a good idea:
*/
ALTER DATABASE SCOPED CONFIGURATION SET ROW_MODE_MEMORY_GRANT_FEEDBACK = OFF;
ALTER DATABASE SCOPED CONFIGURATION SET BATCH_MODE_MEMORY_GRANT_FEEDBACK = OFF;
GO
/* Or hint it in the query: */
CREATE OR ALTER PROC dbo.usp_TopScoringPostsByReputation @Reputation INT AS
    SELECT TOP 100000 u.Id, p.Score, AcceptedAnswerId
        FROM dbo.Users u
        JOIN dbo.Posts p ON p.OwnerUserId = u.Id
        WHERE u.Reputation = @Reputation
        ORDER BY p.Score DESC
		OPTION (USE HINT('DISABLE_BATCH_MODE_MEMORY_GRANT_FEEDBACK'));
GO
/* So now when you run it, you can get stable grants: */
EXEC usp_TopScoringPostsByReputation @Reputation = 1;
EXEC usp_TopScoringPostsByReputation @Reputation = 2;
EXEC usp_TopScoringPostsByReputation @Reputation = 1;
GO

/* There's just one little problem: these are still vulnerable to sniffing.
Rebuild the indexes table to flush out the plan cache for this table: */
ALTER TABLE dbo.Users REBUILD;
GO

/* And then run the query again, but for a different starting parameter: */
EXEC usp_TopScoringPostsByReputation @Reputation = 2;


/* Aaaaaand no adaptive join. In fact, these 3 get 3 different plans now: */
EXEC usp_TopScoringPostsByReputation @Reputation = 1 WITH RECOMPILE;
EXEC usp_TopScoringPostsByReputation @Reputation = 2 WITH RECOMPILE;
EXEC usp_TopScoringPostsByReputation @Reputation = 4 WITH RECOMPILE;
GO


/* If you want an adaptive join, you can't hint it: you have to figure out
which parameters are likely to get 'em, and then hint those: */
CREATE OR ALTER PROC dbo.usp_TopScoringPostsByReputation @Reputation INT AS
    SELECT TOP 100000 u.Id, p.Score, AcceptedAnswerId
        FROM dbo.Users u
        JOIN dbo.Posts p ON p.OwnerUserId = u.Id
        WHERE u.Reputation = @Reputation
        ORDER BY p.Score DESC
		OPTION (USE HINT('DISABLE_BATCH_MODE_MEMORY_GRANT_FEEDBACK'),
				OPTIMIZE FOR(@Reputation = 1));
GO

/* So now even if reputation = 2 goes first, the adaptive join goes in cache: */
EXEC usp_TopScoringPostsByReputation @Reputation = 2;

/* 
What to take away from this demo:

* Adaptive joins are a cool way to cache two plans for the same query.

* They have a lot of restrictions, and they don't solve a lot of scenarios yet.

* Memory grant feedback is their Achilles' heel: you probably don't want to use
  those two features together, at least not in the same query.

* They only help with parameter sniffing if you can actually get them in the
  plan: but they're also VICTIMS of parameter sniffing in that many params
  won't actually trigger them. To get them, you need the first set of params
  to push a lot of data through.
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