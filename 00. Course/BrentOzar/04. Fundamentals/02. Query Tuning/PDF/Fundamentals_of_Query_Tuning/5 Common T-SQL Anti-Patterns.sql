/*
Fundamentals of Query Tuning: Common T-SQL Anti-Patterns

v1.3 - 2023-11-05

https://www.BrentOzar.com/go/queryfund


This demo requires:
* Any supported version of SQL Server
* Any Stack Overflow database: https://www.BrentOzar.com/go/querystack

This first RAISERROR is just to make sure you don't accidentally hit F5 and
run the entire script. You don't need to run this:
*/
RAISERROR(N'Oops! No, don''t just hit F5. Run these demos one at a time.', 20, 1) WITH LOG;
GO


/* I'm using the 50GB medium Stack database: */
USE StackOverflow2013;
GO
/* Using 2017 compat level at first because 2017
is the minimum supported version for this class: */
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 140;
GO
/* And this stored procedure drops all nonclustered indexes: */
DropIndexes;
GO
/* It leaves clustered indexes in place though. 

Create a few indexes to support our queries: */
CREATE INDEX IX_Location ON dbo.Users(Location);
CREATE INDEX UpVotes_DownVotes ON dbo.Users(UpVotes, DownVotes);
CREATE INDEX DownVotes_UpVotes ON dbo.Users(DownVotes, UpVotes);
GO




SET STATISTICS IO ON;




/* When the query is easy to understand, 
SQL Server can do a good job of estimating row counts: */
SELECT *
  FROM dbo.Users u
  WHERE u.Location = 'Helsinki, Finland'
  ORDER BY u.Reputation DESC;
GO


/* But what happens if we obscure the WHERE clause? 
Does SQL Server still give good estimates? */
SELECT *
  FROM dbo.Users u
  WHERE u.Location = UPPER('Helsinki, Finland')
  ORDER BY u.Reputation DESC;


/* The estimate is suddenly way off.
It doesn't impact the shape or performance of
the query plan, though: run them both, and
you can see the plan works fine.

But not for all values we might search for: */
SELECT *
  FROM dbo.Users u
  WHERE u.Location = 'India'
  ORDER BY u.Reputation DESC;

SELECT *
  FROM dbo.Users u
  WHERE u.Location = UPPER('India')
  ORDER BY u.Reputation DESC;
GO



/* This is a theme you'll see through your career.

T-SQL anti-patterns (like functions in the WHERE clause):

* Might cause cardinality estimation problems

* But those problems may only cause plan changes
  for SOME parameters, and not others

* Or might be universally bad

* Might not be immediately obvious in the query plan

* Might change over time, like in newer versions
  of SQL Server and Azure SQL DB

In this module, my goal is to point out the
most common anti-patterns 
that cause the most problems,
but even these won't cause problems ALL the time. */


/* The top 4:
1. Functions in the FROM & below (WHERE, JOIN, GROUP BY, etc)
2. Implicit conversions
3. Comparing the contents of 2 columns on 1 table
4. Table variables  */



/* 1. FUNCTIONS IN THE FROM & BELOW



We touched on this a little with LTRIM/RTRIM,
but let's use a more modern example: STRING_SPLIT. */

CREATE OR ALTER PROC dbo.usp_GetUsersInLocation
	@Location NVARCHAR(100) AS
BEGIN
	SELECT *
	  FROM dbo.Users u
	  WHERE u.Location = @Location
	  ORDER BY u.Reputation DESC;
END
GO
/* When the WHERE is straightforward, estimates are good: */
EXEC usp_GetUsersInLocation N'India';
GO

/* But let's say we wanna handle multiple locations: */
CREATE OR ALTER PROC dbo.usp_GetUsersInLocation
	@Location NVARCHAR(1000) AS
BEGIN
	SELECT *
	  FROM dbo.Users u
	  WHERE u.Location IN 
		(SELECT value FROM STRING_SPLIT(@Location, N','))
	  ORDER BY u.Reputation DESC;
END
GO
EXEC usp_GetUsersInLocation N'India';
GO
/* The problems:

* SQL Server doesn't know what the string will split into
  until after the query is already running

* SQL Server doesn't know how many values STRING_SPLIT
  will produce, and it guesses 50

* SQL Server doesn't know what those 50 locations will be,
  so it uses the density vector: the average location size

* The estimates are made-up garbage, so the plan is bad


But keep in mind:

* If you really passed in 40-50-60 rows, it'd be fine

* If those 40-50-60 rows were average location sizes
  (not India), you'd also be fine

So again, this is why T-SQL anti-patterns can be tricky:
sometimes, they're okay. Sometimes, they're not.

Generally speaking, anytime you see a function in
the FROM & down, you're going to get a surprise when
SOME values run - but not all.

This applies to:
* System functions (processing strings, dates, security, etc)
* User-defined functions (scalars, table-valued functions)
* CLR functions (plus the newer Java, R, Python type stuff)

Generally speaking, avoid putting any functions
in the FROM/JOIN/WHERE/GROUP/etc unless you've
proven that the function placement is harmless in your
specific SQL Server version & compatibility level.
*/






/* 2. IMPLICIT CONVERSIONS 

To demo it, I'm going to change one of the Stack Overflow
columns to be more similar to real-world tables. Let's
change WebsiteURL from NVARCHAR to VARCHAR: */
ALTER TABLE dbo.Users
	ALTER COLUMN WebsiteUrl VARCHAR(200);

CREATE INDEX WebsiteUrl ON dbo.Users(WebsiteUrl);
GO

SELECT *
	FROM dbo.Users
	WHERE WebsiteUrl = 'https://www.brentozar.com'

SELECT *
	FROM dbo.Users
	WHERE WebsiteUrl = N'https://www.brentozar.com'

/*

* We get a scan, not a seek

* The estimates are usually way off, too

* SQL Server up-converts what's in the table 
  to match the incoming data type

* CPU use goes up linearly with the number 
  of rows/columns to be converted
*/



/* This can hit you really hard on joins, so check the fields you join on: */
WITH ProblematicColumns AS  (
SELECT COLUMN_NAME
  FROM INFORMATION_SCHEMA.COLUMNS c1
  GROUP BY COLUMN_NAME
  HAVING COUNT(DISTINCT DATA_TYPE) > 1
)
SELECT c.*
  FROM ProblematicColumns pc
  INNER JOIN INFORMATION_SCHEMA.COLUMNS c ON pc.COLUMN_NAME = c.COLUMN_NAME
  ORDER BY c.COLUMN_NAME, c.DATA_TYPE;
GO







/* 3. COMPARING COLUMNS


When you're only looking at one column at a time,
SQL Server can use statistics on that column
to guess how many rows will match: */

SELECT COUNT(*) FROM dbo.Users WHERE UpVotes > 1000000;
SELECT COUNT(*) FROM dbo.Users WHERE DownVotes > 1000000;

/* And the estimates are also good if
we're looking at both columns independently: */
SELECT * FROM dbo.Users
WHERE UpVotes > 1000000
  AND DownVotes > 1000000;

/* But as soon as we get both columns involved
in a single comparison: */
SELECT COUNT(*) FROM dbo.Users
WHERE UpVotes + DownVotes > 1000000000; /* More zeroes */



SELECT COUNT(*) FROM dbo.Users
WHERE UpVotes + DownVotes < 1000000000;



SELECT 739714.0 / (SELECT COUNT(*) FROM dbo.Users);


/* SQL Server has tons of those hard-coded estimates,
but the worst offenders are:
* Comparing or doing math on 2 columns in the same table
* Or even 2 columns in DIFFERENT tables

To learn some of the hard-coded rules, watch these:
https://sqlbits.com/Speakers/Dave_Ballantyne
*/






/* 4. TABLE VARIABLES */

DECLARE @Users TABLE (Id INT PRIMARY KEY CLUSTERED, DisplayName NVARCHAR(40));

INSERT INTO @Users (Id, DisplayName)
	SELECT Id, DisplayName
	FROM dbo.Users;

SELECT TOP 1000 *
	FROM @Users
	ORDER BY DisplayName;
GO
/* Problems:

* SQL Server only estimated 1 row would be in the table variable

* Because of that, it underestimated memory,
  and the sort spilled to disk

* It probably should have put in parallelism, too 


One way to fix that: add OPTION RECOMPILE: */

DECLARE @Users TABLE (Id INT PRIMARY KEY CLUSTERED, DisplayName NVARCHAR(40));

INSERT INTO @Users (Id, DisplayName)
	SELECT Id, DisplayName
	FROM dbo.Users;

SELECT TOP 1000 *
	FROM @Users
	ORDER BY DisplayName OPTION (RECOMPILE);
GO



/* Another way to fix it: SQL 2019 compat level: */
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 150;
GO
DECLARE @Users TABLE (Id INT PRIMARY KEY CLUSTERED, DisplayName NVARCHAR(40));

INSERT INTO @Users (Id, DisplayName)
	SELECT Id, DisplayName
	FROM dbo.Users;

SELECT TOP 1000 *
	FROM @Users
	ORDER BY DisplayName;
GO

/* Just be aware that table variables still have a gotcha: */
DECLARE @MyGarage TABLE (Car VARCHAR(50));
BEGIN TRAN
	INSERT INTO @MyGarage VALUES('1964 Porsche 356 SC');
	INSERT INTO @MyGarage VALUES('1969 Porsche 911');
	INSERT INTO @MyGarage VALUES('2023 Land Rover Defender');
COMMIT
SELECT * FROM @MyGarage;
GO



DECLARE @MyGarage TABLE (Car VARCHAR(50));
BEGIN TRAN
	INSERT INTO @MyGarage VALUES('1964 Porsche 356 SC');
	INSERT INTO @MyGarage VALUES('1969 Porsche 911');
	INSERT INTO @MyGarage VALUES('2023 Land Rover Defender');
ROLLBACK
SELECT * FROM @MyGarage;

/* Table variables (like all variables) 
are not part of transactions. */





/*
This is really the start of a lifelong journey.
The more you learn about SQL Server, the more
you'll start to recognize queries that COMPILE,
but produce bad estimations or behaviors.
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