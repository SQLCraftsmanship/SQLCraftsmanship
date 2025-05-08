
/******************************************************************************************************************************************
-- WORKING WITH JSON

-- Index

	-- Intro

	-- 1. JSON types

	-- 2. IMPORT data to SQL from JSON
		-- 2.1 OPENJSON()
		--	Without var
		--  With var
		--  Into a table

	-- 3. EXPORT data to JSON format from table 
		-- 3.1 FOR JSON PATH, ROOT('Sales') 

	-- 4. JSON Functions
		-- 4.1 ISJSON(@JSON)
		-- 4.2 JSON_VALUE(@JSON, 'xxx')
		-- 4.3 JSON_VALUE(@JSON, 'xxx') 
		-- 4.4 JSON_QUERY(@JSON, 'xxx')
		-- 4.5 JSON_MODIFY(@JSON, 'xxx', 'xxx')
		-- 4.6 SELECT with WHERE

	-- 5. FOR JSON PATH

	-- Reference
	https://docs.microsoft.com/en-us/sql/relational-databases/json/json-data-sql-server?view=sql-server-ver15
	https://www.mssqltips.com/sqlservertip/6884/sql-json-examples-display-transfer/?utm_source=dailynewsletter&utm_medium=email&utm_content=headline&utm_campaign=20210607
	https://www.youtube.com/watch?v=vljkDorNiuw
	https://www.youtube.com/watch?v=auc-fFGJUTI

	-- Open datasets published in JSON
		Data.gov
		Datasf.org
		Data.cityofNewYork.us

******************************************************************************************************************************************/

-- Intro
--JSON data format (Java Script Object Notation) is a popular open file format for exchanging data between applications as well as receiving data from 
--a server.

--While JSON is native to JavaScript, the JSON data format is widely used for exchanging data between any pair of applications – neither of which need 
--to include JavaScript. Another common JSON use case is to store data on a server for download to client applications. You can think of a JSON data 
--object as roughly analogous in purpose to a SQL Server table.

--Many database professionals prefer using JSON to XML for representing and exchanging data because JSON is perceived to be a simpler, lighter weight 
--data storage format.

--Perhaps the most distinctive JSON feature is that data is stored in key-value pairs. Each distinct key within the set of key-value pairs in some JSON 
--formatted text is roughly analogous to a column in a SQL Server table. A key name instance must appear in double quotes. A colon delimiter (:) 
--separates the key name from the JSON value. The value for a key can be embraced by double quotes, no double quotes, or even be missing depending on 
--the data type for a value.

--    * String data type values must be embraced in double quotes.
--    * Number data type values should not be embraced in double quotes.
--    * Null data type values indicate a missing value for a key on that row. You can also specify a missing value with a null value for a key.

--Aside from string, number, and null data types, JSON data formatting also supports Boolean, array, and object data types.

--    * A Boolean key can be associated with values of either true or false.
--    * An array key-value pair is an ordered set of two or more values. An array data type instance must have its own key name. Each value within an 
--	  array can be a string (varchar, nvarchar), number (int, numreric) or a null value. The collection of values within an array must be separated 
--	  by commas. You can think of an array as a tuple with a name. An array data type must be wrapped in square brackets ([]). A key-value pair for 
--	  an array can be specified within a JSON document at the top level or within another object, such as a JSON data object instance.
--    * A JSON data object is a collection of one or more key-value pairs. The set of key-value pairs for an object must be embraced in curly braces 
--	  ({}). If there is more than one key-value pair within a data object type instance, then the pairs must be separated by commas. Each nested key 
--	  name can appear just once per data object type instance. The key-value pairs within an object data type can be any data type. Data object 
--	  instances can be nested within other JSON objects or they can be top-level instances within a JSON document. When a data object instance is 
--	  nested within another data object, then the nested object should have a key name. Top-level data object instances do not require key names, 
--	  but top-level object instances should be separated by commas from one another within a JSON document.



-- 1. JSON type
	-- 0 is for a null type
	-- 1 is for a string type
	-- 2 is for a number type
	-- 3 is for a Boolean type
	-- 4 is for an array type
	-- 5 is for an object type

	DECLARE @JSON NVARCHAR(MAX) = N'{ 
	   "String_value" : "JSON key name and type values",
	   "Number_value" : 12,
	   "Number_value" : 12.3456,
	   "Boolean_value": true,
	   "Boolean_value": false, 
	   "Null_value"   : null, 
	   "Array_value"  : ["r","m","t","g","a"], 
	   "Object_value" : {"obj":"ect"} 
	}';


-- 2. IMPORT data to SQL from JSON
-- 2.1 OPENJSON()

-- Method I. Example I
-- JSON directly. This export the JSON to a table format.
SELECT  
	Number, Word
FROM OPENJSON('[{"number": 11,  "word": "Yan-a-dik"}, 
	{"number": 12,  "word": "Tan-a-dik"}, 
	{"number": 13,  "word": "Tethera-dik"}, 
	{"number": 14,  "word": "Pethera-dik"}, 
	{"number": 15,  "word": "Bumfit"}, 
	{"number": 16,  "word": "Yan-a-bumtit"}, 
	{"number": 17,  "word": "Tan-a-bumfit"}, 
	{"number": 18,  "word": "Tethera-bumfit"}, 
	{"number": 19,  "word": "Pethera-bumfit"}, 
	{"number": 20,  "word": "Figgot"}]')

WITH (   
		 Number INT			'$.number'
	   , Word   VARCHAR(30) '$.word'
	 )


-- Method I. Example II
-- Same before but use a string var. This return 3 columns 1 Key, 2 Value and 3 Type
DECLARE @JSON NVARCHAR(MAX) = N'{ 
   "String_value" : "JSON key name and type values",
   "Number_value" : 12,
   "Number_value" : 12.3456,
   "Boolean_value": true,
   "Boolean_value": false,
   "Null_value"   : null,
   "Array_value"  : ["r","m","t","g","a"],
   "Object_value" : {"obj":"ect", "Titulos Locales":14}
}';
SELECT * FROM OPENJSON(@JSON);

-- Method I. Example III
-- Same before but use a string var to insert an objetc inside a string. Return only one record
DECLARE @JSON NVARCHAR(MAX) = N'[{ 
   "String_value" : "JSON key name and type values",
   "Number_value" : 12,
   "Number_value" : 12.3456,
   "Boolean_value": true,
   "Boolean_value": false, 
   "Null_value"   : null, 
   "Array_value"  : ["r","m","t","g","a"], 
	"Object_value" : {"obj":"ect", "Titulos Locales":14} 
}]';
SELECT * FROM OPENJSON(@JSON);

-- Method I. Example IV
-- Same example but using a date field
DECLARE @JSON NVARCHAR(MAX);
SET @JSON = N'[
	{"id": 2, "age": 25},
	{"id": 5, "dob": "2005-11-04T12:00:00"}
]';
SELECT * FROM OPENJSON(@JSON);

-- Method I. Example V
-- Nested object
DECLARE @JSON NVARCHAR(MAX);
SET @JSON = N'[
	{"id": 2, "info": {"name": "John", "surname": "Smith"}, "age": 25},
	{"id": 5, "info": {"name": "Jane", "surname": "Smith"}, "dob": "2005-11-04T12:00:00"}
]';
SELECT * FROM OPENJSON(@JSON)

-- Method I. Example VI
-- Nested object and selected fields like we want to see it
DECLARE @JSON NVARCHAR(MAX);
SET @JSON = N'[
  {"id": 2, "info": {"name": "John", "surname": "Smith"}, "age": 25},
  {"id": 5, "info": {"name": "Jane", "surname": "Smith"}, "dob": "2005-11-04T12:00:00"}
]';

SELECT *
FROM OPENJSON(@JSON)
WITH (
    id			 INT		  '$.id'		  ,
    firstName	 NVARCHAR(50) '$.info.name'   ,
    lastName	 NVARCHAR(50) '$.info.surname',
    age			 INT		  '$.age'		  , -- It's the same if we put '$.age' or not
    dateOfBirth  DATETIME2	  '$.dob'		  , -- Full date
    dateOfBirthB DATETIME     '$.dob'		  , -- Added by me. Another format of date
	dateOfBirthC DATE	      '$.dob'		    -- Added by me. Another format of date
  );


-- Method I. Example VII
-- Nested object and selected fields like we want to see it
DECLARE @JSON NVARCHAR(MAX) = N'{
	"Orders" :
	[
		{
			"Order" : { "Number": "SO43659",
						"Date" : "2011-05-31T00:00:00" },
			"Account": "Microsoft",
            "Item": { "Price":59.59,
                      "Quantity":1 }
        },
		{
			"Order" : { "Number": "SO43660",
						"Date" : "2011-06-01T00:00:00" },
			"Account": "Nokia",
            "Item": { "Price":24.99,
                      "Quantity":3 }
        }
    ]
}'

SELECT * FROM OPENJSON(@JSON, N'$.Orders')
WITH
	(
		Number	 NVARCHAR(200)  '$.Order.Number',
		[Date]	 DATETIME		'$.Order.Date'  ,
		Customer NVARCHAR(200)	'$.Account'     ,
		Quantity INT			'$.Item.Quantity'
	);


-- ***********************************************************************************************************************************************
-- ***********************************************************************************************************************************************
-- ***********************************************************************************************************************************************

-- Method II. Example I
-- Create a JSON inside a var and insert the records in a table.
DROP TABLE IF EXISTS [dbo].[jsonTesting]

DECLARE @JSON NVARCHAR(MAX) = N'[
	{"number": 11,  "word": "Yan-a-dik"}, 
	{"number": 12,  "word": "Tan-a-dik"}, 
	{"number": 13,  "word": "Tethera-dik"}, 
	{"number": 14,  "word": "Pethera-dik"}, 
	{"number": 15,  "word": "Bumfit"}, 
	{"number": 16,  "word": "Yan-a-bumtit"}, 
	{"number": 17,  "word": "Tan-a-bumfit"}, 
	{"number": 18,  "word": "Tethera-bumfit"}, 
	{"number": 19,  "word": "Pethera-bumfit"}, 
	{"number": 20,  "word": "Figgot"}]'

SELECT *
	INTO [dbo].[jsonTesting]
FROM OPENJSON(@JSON)
WITH ( [number]	INT,
       [word]	NVARCHAR(50) )

SELECT * FROM [dbo].[jsonTesting];


-- Method II. Example II
-- Same before witH other JSON
DROP TABLE IF EXISTS [dbo].[sym_price_vol]
GO

DECLARE @JSON NVARCHAR(MAX);

SET @JSON = N'[
	{ "ticker_sym": "TSLA", 
	  "date"	  : "2021-04-19T12:00:00", 
	  "open"      : 719.60, 
	  "close"     : 714.63, 
	  "vol"       : 39597000 },

	{ "ticker_sym": "TSLA", 
	  "date"	  : "2021-04-16T12:00:00", 
	  "open"	  : 728.65, 
	  "close"	  : 739.78, 
	  "vol"		  : 27924000 },

	{ "ticker_sym": "MSFT", 
	  "date"      : "2021-04-19", 
	  "open"      : 260.19, 
	  "close"     : 258.74, 
	  "vol"       : 23195800 },

	{ "ticker_sym": "MSFT", 
	  "date"	  : "2021-04-16", 
	  "open"	  : 259.47, 
	  "close"	  : 260.74, 
	  "vol"		  : 24856900 }
]';

SELECT *
	INTO [dbo].[sym_price_vol]
FROM OPENJSON(@JSON)
WITH (
      [ticker_sym]	NVARCHAR(20),
      [date]		DATE		,
      [open]		MONEY		,
      [close]		MONEY		,
      [vol]			BIGINT
    )

SELECT * FROM [dbo].[sym_price_vol]


-- Method II. Example III
-- Same before witH other JSON
DROP TABLE IF EXISTS [dbo].[sym_attributes]
GO

DECLARE @JSON NVARCHAR(MAX);
SET @JSON = N'[
	{ "ticker_sym": "TSLA", 
	  "shortName" : "Tesla, Inc.",
	  "sector"    : "Consumer Cyclical",
	  "industry"  : "Auto Manufacturers" },

	{ "ticker_sym": "MSFT", 
	  "shortName" : "Microsoft Corporation",
	  "sector"    : "Technology",
	  "industry"  : "Software—Infrastructure"}
]';

SELECT *
	INTO [dbo].[sym_attributes]
FROM OPENJSON(@JSON)
WITH (
		[ticker_sym] NVARCHAR(20),
		[shortName]  NVARCHAR(50),
		[sector]	 NVARCHAR(50),
		[industry]   NVARCHAR(50)
	)

SELECT * FROM [dbo].[sym_attributes]


-- Display two populated tables from json values from points Method II. Example II and III
SELECT * FROM [dbo].[sym_price_vol]
SELECT * FROM [dbo].[sym_attributes]
 
-- JOIN two tables populated with json data from points Method II. Example II and III
SELECT 
	  sym_price_vol.*
	, sym_attributes.shortName
	, sym_attributes.sector
	, sym_attributes.industry
FROM [dbo].[sym_attributes]
JOIN [dbo].[sym_price_vol]
ON   sym_attributes.ticker_sym = sym_price_vol.ticker_sym


-- ***********************************************************************************************************************************************
-- ***********************************************************************************************************************************************
-- ***********************************************************************************************************************************************

-- 3. EXPORT data to JSON format from table 
	-- 3.1 FOR JSON PATH, ROOT('Sales') 

-- Example I
USE [AdventureWorks2016]
GO
SELECT TOP 3
	  SalesOrderID	   AS [OrderId]
	, SalesOrderNumber AS [OrderNumber]
	, OrderDate
	, CustomerID
	, SubTotal
FROM Sales.SalesOrderHeader
FOR JSON PATH

-- Example II
USE [AdventureWorks2016]
GO
SELECT TOP 3
	  SalesOrderID	   AS [OrderId]
	, SalesOrderNumber AS [OrderNumber]
	, OrderDate
	, CustomerID
	, SubTotal
FROM Sales.SalesOrderHeader
FOR JSON PATH, ROOT('Sales')

-- Example III
USE [AdventureWorks2016]
GO
SELECT TOP 3
	  SalesOrderID	   AS [Sales.OrderId]
	, SalesOrderNumber AS [Sales.OrderNumber]
	, OrderDate
	, CustomerID
	, SubTotal
FROM Sales.SalesOrderHeader
FOR JSON PATH, ROOT('Sales') 


-- ***********************************************************************************************************************************************
-- ***********************************************************************************************************************************************
-- ***********************************************************************************************************************************************

-- 4. JSON Functions
	-- 4.1 ISJSON(@JSON)
	-- 4.2 JSON_VALUE(@JSON, 'xxx')
	-- 4.3 JSON_VALUE(@JSON, 'xxx') 
	-- 4.4 JSON_QUERY(@JSON, 'xxx')
	-- 4.5 JSON_MODIFY(@JSON, 'xxx', 'xxx')
	-- 4.6 SELECT with WHERE

DECLARE @JSON NVARCHAR(MAX) = 
N'{
	"Name"    : "Lucas",
	"Surname" : "Liberatori",
	"Born"    : {"DoB": "1981-01-15", "Town":"Capital Federal", "Country":"Argentina"},
	"NBA Stat": {"pts":15000, "ppg":11.8, "rebounds":9326, "rpg":8.2, "blocks": 1631, "bpg":1.4},
	"Teams"   : ["Los Angeles Lakers", "Sacramento Kings", "Partizan"],
	"Career": [
		{"teams":"Sloga", "period":{"start":1983, "end":1986}},
		{"teams":"Partizan", "period":{"start":1986, "end":1989}},
		{"teams":"Los Angeles Laker", "period":{"start":1989, "end":1996}},
		{"teams":"Sacramento Kings", "period":{"start":1996, "end":2004}},
		{"teams":"Los Angeles Laker", "period":{"start":2004, "end":2005}}],
	"Bio":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccccccccccccccccccccccccdddddddddddddddddddddddddddddddddddddddeeeeeeeeeeeeeeeeeeeeeeeeeeeeefffffffffffffffffffffffffffffffffffffffffffffffffgggggggggggggggggggggggggggggggggghhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiijjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk"
}'

-- Return 1 if it's a JSON
SELECT ISJSON(@JSON)

-- Return the value from the key Name
SELECT JSON_VALUE(@JSON, '$.Name')
-- Return the value from the key Born.DoB
SELECT JSON_VALUE(@JSON, '$.Born.DoB')
-- Return the value from the key Career.period.start in the position 2
SELECT JSON_VALUE(@JSON, '$.Career[2].period.start')
-- This not return the all object
SELECT JSON_VALUE(@JSON, '$.Born')
-- Return an error because name is with upper case no low case and we put strict, with lax return null.
SELECT JSON_VALUE(@JSON, 'strict $.name')

-- This is the explanation of the point below
/***************************************************************************************************************************************************
Path mode (lax or strict)

	At the beginning of the path expression, optionally declare the path mode by specifying the keyword lax or strict. The default is lax.

	In lax mode, the function returns empty values if the path expression contains an error. For example, if you request the value $.name, 
	and the JSON text doesn't contain a name key, the function returns null, but does not raise an error.

	In strict mode, the function raises an error if the path expression contains an error.

	The following query explicitly specifies lax mode in the path expression.

	Example
		DECLARE @json NVARCHAR(MAX);
		SET @json=N'{}';
		SELECT * FROM OPENJSON(@json, N'lax $.info');
		SELECT JSON_VALUE(@JSON, 'strict $.Name')
***************************************************************************************************************************************************/

-- This return the completed object
SELECT JSON_QUERY(@JSON, '$.Born')  -- Este Si te devuelve el objeto entero siendo este un {}
SELECT JSON_QUERY(@JSON, '$.Teams') -- Este Si te devuelve el objeto entero siendo este un []
SELECT JSON_QUERY(@JSON, '$.NBA Stat') -- Este Si te devuelve el objeto entero


-- This return the completed JSON but change the Name
SELECT JSON_MODIFY(@JSON, '$.Name', 'Lucas Damian')
-- This delete Name from the JSON
SELECT JSON_MODIFY(@JSON, '$.Name', NULL)
-- This add 'Racing CLub' to the Teams key
SELECT JSON_MODIFY(@JSON, 'append $.Teams', 'Racing Club')
-- Change but with problem in the "\". "Born":"{\"DoB\":\"02\/03\/1981\", \"Town\":\"Argentina\"}"
SELECT JSON_MODIFY(@JSON, '$.Born', '{"DoB":"02/03/1981", "Town":"Argentina"}')
-- Change but without problem in the "\". "Born":{"DoB":"02/03/1981", "Town":"Argentina"}
SELECT JSON_MODIFY(@JSON, '$.Born', JSON_QUERY('{"DoB":"02/03/1981", "Town":"Argentina"}'))


-- This return the value from the key 'Bio' and the name of the column is [value]
SELECT value FROM OPENJSON(@JSON) WHERE [Key] = 'Bio'
-- This return the value from the key 'Bio' and the name of the column is [Bio]
SELECT Bio   FROM OPENJSON(@JSON) WITH (Bio NVARCHAR(MAX))
-- This return all values from Born key in three columns [DoB], [Town] and [Country]
SELECT * FROM OPENJSON(@JSON, '$.Born') WITH (DoB DATETIME2, Town NVARCHAR(50), Country NVARCHAR(50))
-- This return all values from Born key in three lines
SELECT * FROM OPENJSON(@JSON, '$.Born')
-- This return three columns with info from the keys Teams and Period.Start and Period.End
SELECT * FROM OPENJSON(@JSON, '$.Career')
	WITH (
		  teams     NVARCHAR(50)
		, StartYear INT '$.period.start'
		, EndYear   INT '$.period.end'
	)
-- This return three columns with info from the keys Teams, Period.Start and Period.End
SELECT * FROM OPENJSON(@JSON, '$.Career')
	WITH (
		  teams  NVARCHAR(50)
		, period NVARCHAR(MAX) AS JSON
	)



-- ***********************************************************************************************************************************************
-- ***********************************************************************************************************************************************
-- ***********************************************************************************************************************************************

-- 5. FOR JSON PATH

-- Example I
-- [{"X":1,"Y":2,"Z":3}]
SELECT 
	  1 AS X
	, 2 AS Y
	, 3 AS Z
	, NULL AS Nothing
FOR JSON PATH

-- Example II
-- [{"Point":{"x":1,"y":2},"z":3}]
SELECT 
	  1 AS "Point.x"
	, 2 AS "Point.y"
	, 3 AS z
FOR JSON PATH

-- Example III
-- [{"x":1,"y":2},{"x":3,"y":4}]
WITH src(x,y) AS 
	(	SELECT 1 AS x, 2 AS y 
			UNION
		SELECT 3 AS x, 4 AS y)
SELECT * FROM src
FOR JSON PATH

-- Example IV
-- {"x":1,"y":2,"z":3}
SELECT 1 AS x, 2 AS y, 3 AS z 
FOR JSON PATH, WITHOUT_ARRAY_WRAPPER

-- Example VI
-- {"RACING":[{"x":1,"y":2,"z":3}]}
SELECT 1 AS x, 2 AS y, 3 AS z 
FOR JSON PATH, ROOT('RACING')



