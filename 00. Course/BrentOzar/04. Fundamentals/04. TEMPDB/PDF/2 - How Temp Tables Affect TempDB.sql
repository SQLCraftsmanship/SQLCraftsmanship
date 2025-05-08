/*
Fundamentals of TempDB: How Temp Tables Affect TempDB, Part 1: One Query at a Time
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


USE tempdb;
GO
/* Let's create a real table: */
DROP TABLE IF EXISTS dbo.Users_temp;
CREATE TABLE dbo.Users_temp 
	(Id INT,
	 DisplayName NVARCHAR(40),
	 Location NVARCHAR(100));

INSERT INTO dbo.Users_temp(Id, DisplayName, Location)
	SELECT Id, DisplayName, Location
	FROM StackOverflow2013.dbo.Users;
GO

/* When you run a query that would benefit from
having statistics on a column, like this, when
SQL Server needs to guess the memory required
for the sort: */
SELECT TOP 1000 *
	FROM dbo.Users_temp
	WHERE DisplayName = N'Abhishek'
	ORDER BY Location;
GO


/* Then SQL Server automatically adds a system-
created statistic on that column. You can see it
in Object Explorer, or with sp_BlitzIndex: */
sp_BlitzIndex @TableName = 'Users_temp';

/* In order to build and maintain those statistics,
SQL Server has to read data pages and compute stuff,
and that takes time. It's worth the overhead,
though, because it makes queries faster.


Now let's try the same thing with a temp table: */
CREATE TABLE #Users_temp 
	(Id INT,
	 DisplayName NVARCHAR(40),
	 Location NVARCHAR(100));

INSERT INTO #Users_temp(Id, DisplayName, Location)
	SELECT Id, DisplayName, Location
	FROM StackOverflow2013.dbo.Users;

SELECT TOP 1000 *
	FROM #Users_temp
	WHERE DisplayName = N'Abhishek'
	ORDER BY Location;
GO
/* The same statistics process needs to happen, but
it's a little harder to see since temp tables
don't show up in Object Explorer: */
SELECT * FROM sys.all_objects WHERE name LIKE '#Users_temp%'


sp_BlitzIndex @TableName = '#Users_temp_________________________________________________________________________________________________________00000000002C';
GO
/* Things to discuss:
* The table has stats just like a real table
* The table has an actual size just like a real table


Temp tables are kinda like real tables, except:
* They get special names behind the scenes
* They're only accessible per-session: one session
	shouldn't be able to read someone else's data

But temp tables also get some optimizations that
aren't immediately obvious when you're creating
just one table at a time.

Let's create a stored procedure that will do some
dumb work: */
DROP TABLE #Users_temp;
GO
USE StackOverflow2013
GO

CREATE OR ALTER PROC dbo.usp_GetUsers 
	@Location NVARCHAR(100), @DisplayName NVARCHAR(40) AS
BEGIN
	CREATE TABLE #Users
		(Id INT,
		 DisplayName NVARCHAR(40),
		 Location NVARCHAR(100));

	INSERT INTO #Users(Id, DisplayName, Location)
		SELECT Id, DisplayName, Location
		FROM dbo.Users
		WHERE Location = @Location;

	SELECT TOP 1000 *
		FROM #Users
		WHERE DisplayName = @DisplayName
		ORDER BY Location;

	DROP TABLE #Users;
END
GO

/* Turn on actual plans: */
EXEC usp_GetUsers @Location = N'India', @DisplayName = N'Abhishek'

/* How did your estimates vs actuals look?

Here's what happened:
1. SQL Server created a temp table
2. We loaded it
3. When the SELECT ran, SQL Server realized it
	needed statistics on the temp table, so it read
	the temp table and created the stats
4. SQL Server read the temp table for the SELECT


Now, run this, but BEFORE you run it, think about
which of the above 4 steps SQL Server will do: */
EXEC usp_GetUsers @Location = N'Russia', @DisplayName = N'Aleksey'
GO

/* How did your estimates vs actuals look?

Guess which TWO steps SQL Server didn't actually do:
1. SQL Server created a temp table
2. We loaded it
3. When the SELECT ran, SQL Server realized it
	needed statistics on the temp table, so it read
	the temp table and created the stats
4. SQL Server read the temp table for the SELECT

Let's prove it by adding a DBCC SHOW_STATISTICS
in the proc to show the contents of the stats:
*/
CREATE OR ALTER PROC dbo.usp_GetUsers 
	@Location NVARCHAR(100), @DisplayName NVARCHAR(40) AS
BEGIN
	CREATE TABLE #Users
		(Id INT,
		 DisplayName NVARCHAR(40),
		 Location NVARCHAR(100));

	INSERT INTO #Users(Id, DisplayName, Location)
		SELECT Id, DisplayName, Location
		FROM dbo.Users
		WHERE Location LIKE @Location;

	SELECT TOP 1000 *
		FROM #Users
		WHERE DisplayName = @DisplayName
		ORDER BY Location;

	/* THIS IS NEW: */
	DBCC SHOW_STATISTICS('tempdb..#Users', DisplayName)

	DROP TABLE #Users;
END
GO


/* Try one: */
EXEC usp_GetUsers @Location = N'India', @DisplayName = N'Abhishek'

/* Then run it for another: */
EXEC usp_GetUsers @Location = N'Russia', @DisplayName = N'Aleksey'

/* Try freeing the plan cache: */
DBCC FREEPROCCACHE;
GO


/* Now try Russia first: */
EXEC usp_GetUsers @Location = N'Russia', @DisplayName = N'Aleksey'

/* Then India: */
EXEC usp_GetUsers @Location = N'India', @DisplayName = N'Abhishek'


/* THIS IS TWO DIFFERENT ISSUES:

1. Parameter sniffing, but also
2. THE TEMP TABLE'S STATS ARE NOT CHANGING!

WE ARE ACTUALLY SEEING SOMEONE ELSE'S STATS.

You can try this in another window too: */
EXEC usp_GetUsers @Location = N'India', @DisplayName = N'Abhishek'
GO

/* Here's what's happening:

1. SQL Server created a temp table - WE'RE NOT DOING THIS!
2. We loaded it
3. When the SELECT ran, SQL Server realized it
	needed statistics on the temp table, so it read
	the temp table and created the stats - WE'RE NOT DOING THIS EITHER!
4. SQL Server read the temp table for the select


Temp tables have a tricky optimization:
their structure and their statistics can be reused
across different sessions. This is part of the
magic that helps temp tables run faster.

However, depending on what you DO to the temp
tables, you can change that behavior. Temp
tables get cached if they're created with a
single CREATE, and then not changed afterwards.
For example, here I've added an index to the
temp table, and now each time I run it, I get
unique stats just for that temp table: */

CREATE OR ALTER PROC dbo.usp_GetUsers 
	@Location NVARCHAR(100), @DisplayName NVARCHAR(40) AS
BEGIN
	CREATE TABLE #Users
		(Id INT,
		 DisplayName NVARCHAR(40),
		 Location NVARCHAR(100));

	/* THIS IS NEW */
	CREATE INDEX Id ON #Users(Id);

	INSERT INTO #Users(Id, DisplayName, Location)
		SELECT Id, DisplayName, Location
		FROM dbo.Users
		WHERE Location LIKE @Location;

	SELECT TOP 1000 *
		FROM #Users
		WHERE DisplayName = @DisplayName
		ORDER BY Location;

	DBCC SHOW_STATISTICS('tempdb..#Users', DisplayName)

	DROP TABLE #Users;
END
GO

/* Try one: */
EXEC usp_GetUsers @Location = N'India', @DisplayName = N'Abhishek'

/* Then run it for another: */
EXEC usp_GetUsers @Location = N'Russia', @DisplayName = N'Aleksey'

/* This might seem like a good thing: you might
think you WANT to get fresh statistics every time
your query runs. However, there's a dark side:
each time you get fresh numbers, you're also
forcing SQL Server to build new statistics and
recompile the execution plan.

You can see this happening by running Erik's
sp_HumanEvents in another window:
*/
EXEC dbo.sp_HumanEvents @event_type = 'recompilations', @seconds_sample = 10
GO

/* While you run a few of these: */
EXEC usp_GetUsers @Location = N'India', @DisplayName = N'Abhishek'
EXEC usp_GetUsers @Location = N'Russia', @DisplayName = N'Aleksey'
EXEC usp_GetUsers @Location = N'India', @DisplayName = N'Abhishek'
EXEC usp_GetUsers @Location = N'Russia', @DisplayName = N'Aleksey'
EXEC usp_GetUsers @Location = N'India', @DisplayName = N'Abhishek'
EXEC usp_GetUsers @Location = N'Russia', @DisplayName = N'Aleksey'
GO


/* Whereas if we go back to the earlier version
of the stored proc that doesn't create an index: */
CREATE OR ALTER PROC dbo.usp_GetUsers 
	@Location NVARCHAR(100), @DisplayName NVARCHAR(40) AS
BEGIN
	CREATE TABLE #Users
		(Id INT,
		 DisplayName NVARCHAR(40),
		 Location NVARCHAR(100));

	INSERT INTO #Users(Id, DisplayName, Location)
		SELECT Id, DisplayName, Location
		FROM dbo.Users
		WHERE Location LIKE @Location;

	SELECT TOP 1000 *
		FROM #Users
		WHERE DisplayName = @DisplayName
		ORDER BY Location;

	/* THIS IS NEW: */
	DBCC SHOW_STATISTICS('tempdb..#Users', DisplayName)

	DROP TABLE #Users;
END
GO



/* Then these don't get recompiles: */
EXEC usp_GetUsers @Location = N'India', @DisplayName = N'Abhishek'
EXEC usp_GetUsers @Location = N'Russia', @DisplayName = N'Aleksey'
EXEC usp_GetUsers @Location = N'India', @DisplayName = N'Abhishek'
EXEC usp_GetUsers @Location = N'Russia', @DisplayName = N'Aleksey'
EXEC usp_GetUsers @Location = N'India', @DisplayName = N'Abhishek'
EXEC usp_GetUsers @Location = N'Russia', @DisplayName = N'Aleksey'
GO


/* What you learned in this session:

* Temp tables have 2 cool optimizations that help
	queries run faster, especially when we have a
	lot of queries that keep creating/dropping temp
	tables:

	1. Their structure can be reused across sessions
	2. Their statistics can be reused, too

* Even if you explicitly drop a temp table, you
	still get these optimizations.

* However, if you modify a temp table after it's
	created, you lose these optimizations, but
	you GAIN more accurate statistics (at the
	expense of slower temp table creation, stats
	updates, and higher CPU for recompilations.)

* It's up to you to figure out which one you want:
	* Temp table reuse, or
	* New temp tables each time

There are a lot more code behaviors that influence
whether you get temp table & statistics reuse:
https://www.brentozar.com/archive/2020/11/paul-white-explains-temp-table-caching-3-ways/

*/

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