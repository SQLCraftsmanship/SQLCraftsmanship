
SELECT
	  session_id
	, connection_id
	, connect_time
	, GETDATE()						[GETDATE]
	, CONVERT(DATE, GETDATE())		[CONVERT_GETDATE_DATE]
    , CAST(GETDATE() AS DATE)		[CAST_GETDATE_DATE]
	, TRY_CONVERT(DATE, GETDATE())	[TRY_CONVERT_GETDATE_DATE]

	, CONVERT(TIME,GETDATE())		[CONVERT_GETDATE_TIME]
    , CAST(GETDATE() AS TIME)		[CAST_GETDATE_TIME]
    , TRY_CONVERT(TIME, GETDATE())	[TRY_CONVERT_GETDATE_TIME]

FROM sys.dm_exec_connections

/* ***************************************************************************************************************************************
SQL Server SYSDATETIME, SYSDATETIMEOFFSET and SYSUTCDATETIME Functions

	SQL Server High Precision Date and Time Functions have a scale of 7 and are:

	SYSDATETIME			– returns the date and time of the machine the SQL Server is running on
	SYSDATETIMEOFFSET	– returns the date and time of the machine the SQL Server is running on plus the offset from UTC
	SYSUTCDATETIME		- returns the date and time of the machine the SQL Server is running on as UTC
*************************************************************************************************************************************** */
-- higher precision functions 
SELECT SYSDATETIME() AS 'DateAndTime' /* return datetime2(7) */, SYSDATETIMEOFFSET() AS 'DateAndTime+Offset' /* datetimeoffset(7) */, SYSUTCDATETIME() AS 'DateAndTimeInUtc' -- returns datetime2(7)


/* ***************************************************************************************************************************************
SQL Server CURRENT_TIMESTAMP, GETDATE() and GETUTCDATE() Functions
	SQL Server Lesser Precision Data and Time Functions have a scale of 3 and are:

	CURRENT_TIMESTAMP	- returns the date and time of the machine the SQL Server is running on
	GETDATE()			- returns the date and time of the machine the SQL Server is running on
	GETUTCDATE()		- returns the date and time of the machine the SQL Server is running on as UTC
*************************************************************************************************************************************** */
-- lesser precision functions - returns datetime
SELECT CURRENT_TIMESTAMP AS 'DateAndTime', GETDATE() AS 'DateAndTime', GETUTCDATE() AS 'DateAndTimeUtc'; 


/* ***************************************************************************************************************************************
SQL Server DATENAME Function
	DATENAME – returns a string corresponding to the datepart specified

	date and time parts - RETURNS NVARCHAR 
*************************************************************************************************************************************** */
SELECT DATENAME(YEAR, GETDATE())        AS 'Year';        
SELECT DATENAME(QUARTER, GETDATE())     AS 'Quarter';     
SELECT DATENAME(MONTH, GETDATE())       AS 'Month';       
SELECT DATENAME(DAYOFYEAR, GETDATE())   AS 'DayOfYear';   
SELECT DATENAME(DAY, GETDATE())         AS 'Day';         
SELECT DATENAME(WEEK, GETDATE())        AS 'Week';        
SELECT DATENAME(WEEKDAY, GETDATE())     AS 'WeekDay';     
SELECT DATENAME(HOUR, GETDATE())        AS 'Hour';        
SELECT DATENAME(MINUTE, GETDATE())      AS 'Minute';      
SELECT DATENAME(SECOND, GETDATE())      AS 'Second';      
SELECT DATENAME(MILLISECOND, GETDATE()) AS 'MilliSecond'; 
SELECT DATENAME(MICROSECOND, GETDATE()) AS 'MicroSecond'; 
SELECT DATENAME(NANOSECOND, GETDATE())  AS 'NanoSecond';  
SELECT DATENAME(ISO_WEEK, GETDATE())    AS 'Week';   


/* ***************************************************************************************************************************************
SQL Server DATEPART Function
	DATEPART – returns an integer corresponding to the datepart specified
	date and time parts - RETURNS INT
*************************************************************************************************************************************** */
SELECT DATEPART(YEAR, GETDATE())        AS 'Year';   
SELECT DATEPART(QUARTER, GETDATE())     AS 'Quarter';     
SELECT DATEPART(MONTH, GETDATE())       AS 'Month';       
SELECT DATEPART(DAYOFYEAR, GETDATE())   AS 'DayOfYear';   
SELECT DATEPART(DAY, GETDATE())         AS 'Day';         
SELECT DATEPART(WEEK, GETDATE())        AS 'Week';        
SELECT DATEPART(WEEKDAY, GETDATE())     AS 'WeekDay';     
SELECT DATEPART(HOUR, GETDATE())        AS 'Hour';        
SELECT DATEPART(MINUTE, GETDATE())      AS 'Minute';      
SELECT DATEPART(SECOND, GETDATE())      AS 'Second';      
SELECT DATEPART(MILLISECOND, GETDATE()) AS 'MilliSecond'; 
SELECT DATEPART(MICROSECOND, GETDATE()) AS 'MicroSecond'; 
SELECT DATEPART(NANOSECOND, GETDATE())  AS 'NanoSecond';  
SELECT DATEPART(ISO_WEEK, GETDATE())    AS 'Week';  


/* ***************************************************************************************************************************************
SQL Server DAY, MONTH and YEAR Functions
	DAY		– returns an integer corresponding to the day specified
	MONTH	– returns an integer corresponding to the month specified
	YEAR	– returns an integer corresponding to the year specified
*************************************************************************************************************************************** */
SELECT DAY(GETDATE())   AS 'Day';
SELECT MONTH(GETDATE()) AS 'Month';
SELECT YEAR(GETDATE())  AS 'Year';


/* ***************************************************************************************************************************************
SQL Server DATEFROMPARTS, DATETIME2FROMPARTS, DATETIMEFROMPARTS, DATETIMEOFFSETFROMPARTS, SMALLDATETIMEFROMPARTS and  TIMEFROMPARTS Functions
	DATEFROMPARTS			– returns a date from the date specified
	DATETIME2FROMPARTS		– returns a datetime2 from part specified
	DATETIMEFROMPARTS		– returns a datetime from part specified
	DATETIMEOFFSETFROMPARTS - returns a datetimeoffset from part specified
	SMALLDATETIMEFROMPARTS	- returns a smalldatetime from part specified
	TIMEFROMPARTS			- returns a time from part specified
	
	date and time from parts
*************************************************************************************************************************************** */

SELECT DATEFROMPARTS(2019,1,1)                         AS 'Date';          -- returns date
SELECT DATETIME2FROMPARTS(2019,1,1,6,0,0,0,1)          AS 'DateTime2';     -- returns datetime2
SELECT DATETIMEFROMPARTS(2019,1,1,6,0,0,0)             AS 'DateTime';      -- returns datetime
SELECT DATETIMEOFFSETFROMPARTS(2019,1,1,6,0,0,0,0,0,0) AS 'Offset';        -- returns datetimeoffset
SELECT SMALLDATETIMEFROMPARTS(2019,1,1,6,0)            AS 'SmallDateTime'; -- returns smalldatetime
SELECT TIMEFROMPARTS(6,0,0,0,0)                        AS 'Time';          -- returns time


/* ***************************************************************************************************************************************
SQL Server DATEDIFF and DATEDIFF_BIG Functions
	DATEDIFF 	 - returns the number of date or time datepart boundaries crossed between specified dates as an int
	DATEDIFF_BIG - returns the number of date or time datepart boundaries crossed between specified dates as a bigint

	Date and Time Difference
*************************************************************************************************************************************** */
SELECT DATEDIFF(DAY, 2019-31-01, 2019-01-01)      AS 'DateDif'    -- returns int
SELECT DATEDIFF_BIG(DAY, 2019-31-01, 2019-01-01)  AS 'DateDifBig' -- returns bigint

/* ***************************************************************************************************************************************
SQL Server DATEADD, EOMONTH, SWITCHOFFSET and TODATETIMEOFFSET Functions
	DATEADD 		 - returns datepart with added interval as a datetime
	EOMONTH 		 – returns last day of month of offset as type of start_date
	SWITCHOFFSET 	 - returns date and time offset and time zone offset
	TODATETIMEOFFSET - returns date and time with time zone offset
	
	Modify date and time
*************************************************************************************************************************************** */
SELECT DATEADD(DAY,1,GETDATE())        AS 'DatePlus1';          -- returns data type of the date argument
SELECT EOMONTH(GETDATE(),1)            AS 'LastDayOfNextMonth'; -- returns start_date argument or date
SELECT SWITCHOFFSET(GETDATE(), -6)     AS 'NowMinus6';          -- returns datetimeoffset
SELECT TODATETIMEOFFSET(GETDATE(), -2) AS 'Offset';             -- returns datetimeoffse


/* ***************************************************************************************************************************************
SQL Server ISDATE Function to Validate Date and Time Values
	ISDATE – returns int - Returns 1 if a valid datetime type and 0 if not
	Validate date and time - returns int
*************************************************************************************************************************************** */
SELECT ISDATE(GETDATE()) AS 'IsDate'; 
SELECT ISDATE(NULL) AS 'IsDate';
