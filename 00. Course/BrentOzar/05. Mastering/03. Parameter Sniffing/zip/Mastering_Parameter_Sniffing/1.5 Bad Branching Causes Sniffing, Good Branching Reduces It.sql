/*
Mastering Parameter Sniffing
Bad Branching Causes Sniffing, Good Branching Reduces It

v1.0 - 2020-05-27

https://www.BrentOzar.com/go/mastersniffing


This demo requires:
* SQL Server 2017 or newer
* 2018-06 Stack Overflow database: https://www.BrentOzar.com/go/querystack

This first RAISERROR is just to make sure you don't accidentally hit F5 and
run the entire script. You don't need to run this:
*/
RAISERROR(N'Oops! No, don''t just hit F5. Run these demos one at a time.', 20, 1) WITH LOG;
GO
USE StackOverflow;
GO


/* The Users table has an index on Reputation: */
sp_BlitzIndex @TableName = 'Users'
GO

CREATE OR ALTER PROC dbo.usp_RptUsersByReputation @Reputation INT AS
BEGIN
	SELECT TOP 1000 *
	FROM dbo.Users
	WHERE Reputation = @Reputation
	ORDER BY DisplayName;
END
GO

/* These two get different plans: */
EXEC usp_RptUsersByReputation @Reputation = 2 WITH RECOMPILE;
EXEC usp_RptUsersByReputation @Reputation = 1 WITH RECOMPILE;

/* If the big data plan goes in first, they both perform as expected: */
sp_recompile 'usp_RptUsersByReputation';
GO
EXEC usp_RptUsersByReputation @Reputation = 1;
EXEC usp_RptUsersByReputation @Reputation = 2;
/* But there's are two drawbacks to this plan. What are they? */



/* If the tiny data plan goes in first, then the big one sucks: */
sp_recompile 'usp_RptUsersByReputation';
GO
EXEC usp_RptUsersByReputation @Reputation = 2;
EXEC usp_RptUsersByReputation @Reputation = 1;
GO


/* So let's say we truly need different plans, and we don't want to recompile
because this query is called thousands of times per minute.

Can we put in a branch and get two different plans? */
CREATE OR ALTER PROC dbo.usp_RptUsersByReputation @Reputation INT AS
BEGIN
	IF @Reputation = 1
		SELECT TOP 1000 *
		FROM dbo.Users
		WHERE Reputation = @Reputation
		ORDER BY DisplayName;
	ELSE
		SELECT TOP 1000 *
		FROM dbo.Users
		WHERE Reputation = @Reputation
		ORDER BY DisplayName;
END
GO

/* Do we still have parameter sniffing? Does it matter which one goes first? */
sp_recompile 'usp_RptUsersByReputation';
GO
EXEC usp_RptUsersByReputation @Reputation = 2;
EXEC usp_RptUsersByReputation @Reputation = 1;
GO



/* If I stick query hints in this, will I still have parameter sniffing? */
CREATE OR ALTER PROC dbo.usp_RptUsersByReputation @Reputation INT AS
BEGIN
	IF @Reputation = 1
		SELECT TOP 1000 *
		FROM dbo.Users WITH (INDEX = 1)
		WHERE Reputation = @Reputation
		ORDER BY DisplayName;
	ELSE
		SELECT TOP 1000 *
		FROM dbo.Users WITH (INDEX = IX_Reputation_Includes)
		WHERE Reputation = @Reputation
		ORDER BY DisplayName;
END
GO

/* Do we still have parameter sniffing? Does it matter which one goes first? */
sp_recompile 'usp_RptUsersByReputation';
GO
EXEC usp_RptUsersByReputation @Reputation = 2;
EXEC usp_RptUsersByReputation @Reputation = 1;
GO
/* Did the big data plan:
* Go parallel? Why?
* Estimate the right number of rows? Why?
* Estimate the right memory grant? Why?
*/




/* What if I build dynamic SQL? */
CREATE OR ALTER PROC dbo.usp_RptUsersByReputation @Reputation INT AS
BEGIN
	DECLARE @StringToExecute NVARCHAR(4000) = N'SELECT TOP 1000 * FROM dbo.Users
		WHERE Reputation = @Reputation
		ORDER BY DisplayName;';
	EXEC sp_executesql @StringToExecute, N'@Reputation INT', @Reputation;
END
GO


sp_recompile 'usp_RptUsersByReputation';
GO
EXEC usp_RptUsersByReputation @Reputation = 2;
EXEC usp_RptUsersByReputation @Reputation = 1;
GO






/* What if I build DIFFERENT dynamic SQL? */
CREATE OR ALTER PROC dbo.usp_RptUsersByReputation @Reputation INT AS
BEGIN
	DECLARE @StringToExecute NVARCHAR(4000) = N'SELECT TOP 1000 * FROM dbo.Users
		WHERE Reputation = @Reputation
		ORDER BY DisplayName;';

	IF @Reputation = 1
		SET @StringToExecute = @StringToExecute + N' /* Big data */';

	EXEC sp_executesql @StringToExecute, N'@Reputation INT', @Reputation;
END
GO


DBCC FREEPROCCACHE
GO
EXEC usp_RptUsersByReputation @Reputation = 2;
EXEC usp_RptUsersByReputation @Reputation = 1;
GO
/* Turn off actual plans: */
sp_BlitzCache;




/* Similar tactic: different child stored procedures. */
CREATE OR ALTER PROC dbo.usp_RptUsersByReputation @Reputation INT AS
BEGIN
	IF @Reputation = 1
		EXEC usp_RptUsersByReputation_BigData @Reputation = @Reputation;
	ELSE
		EXEC usp_RptUsersByReputation_SmallData @Reputation = @Reputation;
END
GO


CREATE OR ALTER PROC dbo.usp_RptUsersByReputation_BigData @Reputation INT AS
BEGIN
	SELECT TOP 1000 *
	FROM dbo.Users
	WHERE Reputation = @Reputation
	ORDER BY DisplayName;
END
GO

CREATE OR ALTER PROC dbo.usp_RptUsersByReputation_SmallData @Reputation INT AS
BEGIN
	SELECT TOP 1000 *
	FROM dbo.Users
	WHERE Reputation = @Reputation
	ORDER BY DisplayName;
END
GO
/* THE TWO CHILD STORED PROCS ARE IDENTICAL, but because they're different
queries, they both get parameter sniffing independently, each producing their
own execution plans: */

DBCC FREEPROCCACHE
GO
EXEC usp_RptUsersByReputation @Reputation = 2;
EXEC usp_RptUsersByReputation @Reputation = 1;
GO
/* Turn off actual plans: */
sp_BlitzCache;
GO

/* Benefits of child procs:

* The optimal plan for both can change automatically over time
* Or code can be hand-tuned for each one (like different optimizer hints)

Drawbacks:

* The same code is now in two procs, making maintainability a little harder

* One IF branch and two child procs may not be enough: the more possible plans
  a query has, the more branching you're tempted to build, and it'll be hard

* The right trigger value might change over time, like if Stack Overflow
  suddenly gives people 100 reputation points on joining instead of 1


Child procs are especially powerful when you have joins, and you want the join
decisions to be postponed until after you've found out how many rows are in the
driver table of the query:
*/
CREATE OR ALTER PROC dbo.usp_RptUsersByReputation_Joins @Reputation INT AS
BEGIN
	SELECT TOP 1000 *
	FROM dbo.Users u
		INNER JOIN dbo.Posts p ON u.Id = p.OwnerUserId
		INNER JOIN dbo.Comments c ON p.Id = c.PostId
		INNER JOIN dbo.Users uCommenter ON c.UserId = uCommenter.Id
		INNER JOIN dbo.Badges b ON uCommenter.Id = b.UserId
	WHERE u.Reputation = @Reputation
	ORDER BY u.DisplayName;
END
GO


/* If you call this for @Reputation = 2, only a few users will come out, and
you wouldn't mind a few index seeks on the join tables.

If you call it for @Reputation = 1, you're better off with giant table scans
and a giant memory grant.

Start with a pre-check of how many users match in the driver table:
*/
CREATE OR ALTER PROC dbo.usp_RptUsersByReputation_Joins @Reputation INT AS
BEGIN
	IF 10000 < (SELECT COUNT(*) FROM dbo.Users WHERE Reputation = @Reputation)
		EXEC usp_RptUsersByReputation_Joins_BigData @Reputation = @Reputation;
	ELSE
		EXEC usp_RptUsersByReputation_Joins_SmallData @Reputation = @Reputation;
END
GO


/* Or: */
CREATE OR ALTER PROC dbo.usp_RptUsersByReputation_Joins @Reputation INT AS
BEGIN
	CREATE TABLE #MatchingUsers (Id INT);
	INSERT INTO #MatchingUsers (Id)
		SELECT Id
		FROM dbo.Users
		WHERE Reputation = @Reputation;

	IF 10000 < (SELECT COUNT(*) FROM #MatchingUsers)
		EXEC usp_RptUsersByReputation_Joins_BigData @Reputation = @Reputation;
	ELSE
		EXEC usp_RptUsersByReputation_Joins_SmallData @Reputation = @Reputation;
END
GO

/* Because then you can use the temp table in the child stored procs: */
CREATE OR ALTER PROC dbo.usp_RptUsersByReputation_Joins_BigData @Reputation INT AS
BEGIN
	SELECT TOP 1000 *
	FROM #MatchingUsers m
		INNER JOIN dbo.Users u ON m.Id = u.Id
		INNER JOIN dbo.Posts p ON u.Id = p.OwnerUserId
		INNER JOIN dbo.Comments c ON p.Id = c.PostId
		INNER JOIN dbo.Users uCommenter ON c.UserId = uCommenter.Id
		INNER JOIN dbo.Badges b ON uCommenter.Id = b.UserId
	WHERE u.Reputation = @Reputation
	ORDER BY u.DisplayName;
END
GO



/* 
What to take away from this demo:

* All of the code in a batch gets compiled at once initially.

* If you want a different plan, you have to:

	* Ask for it - like with a RECOMPILE hint

	* Change a lot of data, forcing stats to update

	* Postpone compilation for part of the query:
	  (like build a child stored procedure or dynamic SQL)

	* Comment injection can be super powerful and low maintenance

* But when you do any of the above, you're building technical debt: if the
  data distribution changes over time, you may need to revisit the triggers
  you used to spawn the branching logic.

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