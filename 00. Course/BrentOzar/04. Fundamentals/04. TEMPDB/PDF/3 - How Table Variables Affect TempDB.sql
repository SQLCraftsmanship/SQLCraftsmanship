/*
Fundamentals of TempDB: How Table Variables Affect TempDB, Part 1: One Query at a Time
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


/* In the last session, we created a temp table
and saw how SQL Server automatically created
statistics on it to help build better plans.

Let's try the same thing with a table variable,
starting in SQL Server 2017 compat mode. (You
can use 2016 compat mode if you're running the
class on a 2016 VM. Also, turn on actual plans. */
USE StackOverflow2013;
GO
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 140;
GO
DECLARE @Users_temp TABLE
	(Id INT,
	 DisplayName NVARCHAR(40),
	 Location NVARCHAR(100));

INSERT INTO @Users_temp(Id, DisplayName, Location)
	SELECT Id, DisplayName, Location
	FROM StackOverflow2013.dbo.Users;

SELECT TOP 1000 *
	FROM @Users_temp
	WHERE DisplayName = N'Abhishek'
	ORDER BY Location;

SELECT * FROM sys.all_objects WHERE name LIKE '%Users_temp%'
GO
/* Things to discuss:

* The estimates on the select from the table
	variable are wrong.
* SQL Server doesn't know how many rows are in it.
* SQL Server sure as heck doesn't know how many
	rows will match a specific value either!

* The table variable doesn't show up in sys.all_objects
* It's not really a table: it behaves more like a
	variable (those don't go in all_objects either)

At first, this sounds bad, because the estimates
are wrong.

However...what if the estimates AREN'T wrong?
What if we're not searching for Abhishek?
*/
DECLARE @Users_temp TABLE
	(Id INT,
	 DisplayName NVARCHAR(40),
	 Location NVARCHAR(100));

INSERT INTO @Users_temp(Id, DisplayName, Location)
	SELECT Id, DisplayName, Location
	FROM StackOverflow2013.dbo.Users;

SELECT TOP 1000 *
	FROM @Users_temp
	WHERE DisplayName = N'Brent Ozar'
	ORDER BY Location;
GO
/* If the number of rows we're getting out of the
table variable don't really matter because:

* They're low (like under 100), or
* We're not doing anything with the rows after we
	get them, like we're not sorting them or
	joining them to any other objects

Then table variables have a cool advantage:
	* They don't have stats
	* But that also means they don't trigger recompiles

Use the same stored proc we had last time: */
CREATE OR ALTER PROC dbo.usp_GetUsers_TableVariable
	@Location NVARCHAR(100), @DisplayName NVARCHAR(40) AS
BEGIN
	DECLARE @Users TABLE
		(Id INT,
		 DisplayName NVARCHAR(40),
		 Location NVARCHAR(100));

	INSERT INTO @Users(Id, DisplayName, Location)
		SELECT Id, DisplayName, Location
		FROM dbo.Users
		WHERE Location = @Location;

	SELECT TOP 1000 *
		FROM @Users
		WHERE DisplayName = @DisplayName
		ORDER BY Location;
END
GO

/* Run this with actual plan on and note that the
estimates are just 1 row: */
EXEC usp_GetUsers_TableVariable @Location = N'India', @DisplayName = N'Abhishek'
/* Why 1 row?
	* SQL Server doesn't know how many total rows 
	  are in the table variable, AND
	* SQL Server doesn't know the data distribution
	  either, like the breakdown per name
*/

/* Then while we measure recompiles in another
window: */
EXEC dbo.sp_HumanEvents @event_type = 'recompilations', @seconds_sample = 10
GO

/* Run these: */
EXEC usp_GetUsers_TableVariable @Location = N'India', @DisplayName = N'Abhishek'
EXEC usp_GetUsers_TableVariable @Location = N'Russia', @DisplayName = N'Aleksey'
EXEC usp_GetUsers_TableVariable @Location = N'India', @DisplayName = N'Abhishek'
EXEC usp_GetUsers_TableVariable @Location = N'Russia', @DisplayName = N'Aleksey'
EXEC usp_GetUsers_TableVariable @Location = N'India', @DisplayName = N'Abhishek'
EXEC usp_GetUsers_TableVariable @Location = N'Russia', @DisplayName = N'Aleksey'
GO


/* So to recap table variables so far:

* They don't get statistics, so:
* Bad news: estimates are usually off, but
* Good news: they don't recompile as contents change

Something changed in SQL Server 2019, though: */
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 150; /* 2019 */
GO

/* Run this with actual plan on: */
EXEC usp_GetUsers_TableVariable @Location = N'India', @DisplayName = N'Abhishek'
/* Before, we had an estimate of 1 row because:
	* SQL Server didn't know how many total rows 
	  are in the table variable, AND
	* SQL Server didn't know the data distribution
	  either, like the breakdown per name

But now, hover your mouse over the table variable
scan and look at Estimated Number of Rows to be Read.

In SQL Server 2019:
	* SQL Server DOES know how many rows are in it, but
	* Still doesn't know the data distribution per name

In some ways, this is an improvement, but in
other ways, it's a drawback, because watch what
happens if you run it for a DIFFERENT value:
*/
EXEC usp_GetUsers_TableVariable @Location = N'Russia', @DisplayName = N'Aleksey'

/* Look at the table variable scan estimates:

* The estimated number of rows TO BE READ is the same
* The estimated number of rows TO BE FOUND is the same

This is NOT THE SAME THING that happens with
temp tables. THIS IS DIFFERENT.

With temp table stats reuse:
	* You could inherit someone else's table stats
	* You could inherit their estimates, too
	* Those estimates could change as the temp
	  table's contents changed as queries run

With table variables:
	* You WILL inherit the total number of rows in
	  in the object from the compiled plan
	* There are no column stats (data distribution)
	  to inherit, so these are just consistently wrong
	* This has less to do with temp tables, and more
	  like conventional parameter sniffing problems
*/


/* What you learned in this session:

Table variables are okay if:

* Your query brings back a few rows, and
* The contents (data distribution) of those
  rows don't matter at all, and
* You're not doing anything with the data
  (like you're not sorting it or joining it
  to other tables)
* You need to prevent recompilations
* You don't care if you inherit someone else's
  plan (because all the data is tiny anyway
  no matter what parameters people use)

But be aware that:

* Even though they don't show up in all_objects,
  they still take up space in TempDB.

* Starting in SQL Server 2019, the first params
  for a proc will cause the plan to be built with
  an understanding of the number of rows in the
  table variable (but not an understanding of the
  data distribution, because there are no stats)

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