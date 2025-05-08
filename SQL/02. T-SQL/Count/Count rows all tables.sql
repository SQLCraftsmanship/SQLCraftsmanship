
/*******************************************************************************************************
Title
	Count rows all tables

Ref
	https://www.mssqltips.com/sqlservertip/2537/sql-server-row-count-for-all-tables-in-a-database/

Description
	There are four approuch to do this task.

	1. SYS.PARTITIONS			 [Catalog View]
	https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-partitions-transact-sql?view=sql-server-ver16

	2. SYS.DM_DB_PARTITION_STATS [DMV]

	3. sp_MSforeachtable		 [System Stored Procedure]
	4. COALESCE()				 [SQL Function]

For Testing
	SET NOCOUNT ON

	-------------------------------------------------------------------------------------------
	-- Table with PK, one millon of records
	-------------------------------------------------------------------------------------------
	IF OBJECT_ID(N'dbo.TestOne', N'U') IS NOT NULL
	BEGIN
		DROP TABLE dbo.TestOne;
	END;
	GO
	CREATE TABLE dbo.TestOne
	(
		id integer NOT NULL IDENTITY CONSTRAINT [PK dbo.Test (id)] PRIMARY KEY,
		c1 integer NOT NULL,
		padding char(45) NOT NULL DEFAULT ''
	);
	GO


	DECLARE @i AS INT
	SET @i = 0

	BEGIN TRANSACTION
		WHILE(@i < 1000000)
		BEGIN   
			INSERT INTO dbo.TestOne (c1) values(@i)
			SET @i += 1
		END
	COMMIT TRANSACTION
	GO


	SELECT COUNT(*) FROM dbo.TestOne

	-------------------------------------------------------------------------------------------
	-- Table with PK, lest amount of records
	-------------------------------------------------------------------------------------------
	IF OBJECT_ID(N'dbo.TestTwo', N'U') IS NOT NULL
	BEGIN
		DROP TABLE dbo.TestTwo;
	END;
	GO
	CREATE TABLE dbo.TestTwo
	(
		id integer NOT NULL IDENTITY CONSTRAINT [PK dbo.TestTwo (id)] PRIMARY KEY,
		c1 integer NOT NULL,
		padding char(45) NOT NULL DEFAULT ''
	);
	GO

	DECLARE @i AS INT
	SET @i = 0

	BEGIN TRANSACTION
		WHILE(@i < 499999)
		BEGIN   
			INSERT INTO dbo.TestTwo (c1) values(@i)
			SET @i += 1
		END
	COMMIT TRANSACTION
	GO


	SELECT COUNT(*) FROM dbo.TestTwo

	-------------------------------------------------------------------------------------------
	-- Table with Heap
	-------------------------------------------------------------------------------------------
	IF OBJECT_ID(N'dbo.TestTree', N'U') IS NOT NULL
	BEGIN
		DROP TABLE dbo.TestTree;
	END;
	GO
	CREATE TABLE dbo.TestTree
	(
		c1 integer NOT NULL,
		padding char(45) NOT NULL DEFAULT ''
	);
	GO

	DECLARE @i AS INT
	SET @i = 0

	BEGIN TRANSACTION
		WHILE(@i < 325444)
		BEGIN   
			INSERT INTO dbo.TestTree (c1) values(@i)
			SET @i += 1
		END
	COMMIT TRANSACTION
	GO

	SELECT COUNT(*) FROM dbo.TestTree

	-------------------------------------------------------------------------------------------
	-- Table with NC only
	-------------------------------------------------------------------------------------------
	IF OBJECT_ID(N'dbo.Testfour', N'U') IS NOT NULL
	BEGIN
		DROP TABLE dbo.Testfour;
	END;
	GO
	CREATE TABLE dbo.Testfour
	(
		c1 integer NOT NULL,
		padding char(45) NOT NULL DEFAULT ''
	);
	GO

	CREATE NONCLUSTERED INDEX IX_NC_Testfour_c1 ON dbo.Testfour(c1)

	DECLARE @i AS INT
	SET @i = 0

	BEGIN TRANSACTION
		WHILE(@i < 20000)
		BEGIN   
			INSERT INTO dbo.Testfour (c1) values(@i)
			SET @i += 1
		END
	COMMIT TRANSACTION
	GO

	SELECT COUNT(*) FROM dbo.Testfour

	-------------------------------------------------------------------------------------------
	-- Table with NC and PK
	-------------------------------------------------------------------------------------------
	IF OBJECT_ID(N'dbo.Testfive', N'U') IS NOT NULL
	BEGIN
		DROP TABLE dbo.Testfive;
	END;
	GO
	CREATE TABLE dbo.Testfive
	(
		id integer NOT NULL IDENTITY CONSTRAINT [PK dbo.TestFive (id)] PRIMARY KEY,
		c1 integer NOT NULL,
		padding char(45) NOT NULL DEFAULT ''
	);
	GO

	CREATE NONCLUSTERED INDEX IX_NC_Testfive_c1 ON dbo.Testfive(c1)

	DECLARE @i AS INT
	SET @i = 0

	BEGIN TRANSACTION
		WHILE(@i < 20000)
		BEGIN   
			INSERT INTO dbo.Testfive(c1) values(@i)
			SET @i += 1
		END
	COMMIT TRANSACTION
	GO

	SELECT COUNT(*) FROM dbo.Testfive
*******************************************************************************************************/

-- 	1. SYS.PARTITIONS [Catalog View]
SELECT
	  QUOTENAME(SCHEMA_NAME(sOBJ.schema_id)) + '.' + QUOTENAME(sOBJ.Name) AS [TableName]
	, SUM(sPTN.Rows) AS [RowCount]
FROM
	SYS.OBJECTS AS sOBJ
JOIN
	SYS.PARTITIONS AS sPTN
ON  sOBJ.object_id = sPTN.object_id
WHERE
	sOBJ.type = 'U'
AND sOBJ.is_ms_shipped = 0x0 -- Object is created by an internal SQL Server component.
AND sPTN.index_id < 2 -- 0=Heap, 1=Clustered

GROUP BY sOBJ.schema_id, sOBJ.Name
	
	/**************************************************************************************************************************************
	What happend if you have a NC in the table?
	If you have a NC on the table, this sys.view are gonna show 2 records. One for the Heap or Primary Key and the second one for the NC.
	In both records the number of rows are the same. That is why we need to filter [index_id] column.
	**************************************************************************************************************************************/


-- 2. SYS.DM_DB_PARTITION_STATS [DMV]
SELECT
        QUOTENAME(SCHEMA_NAME(sOBJ.schema_id)) + '.' + QUOTENAME(sOBJ.name) AS [TableName]
      , SUM(sdmvPTNS.row_count) AS [RowCount]
FROM
      SYS.OBJECTS AS sOBJ
JOIN  SYS.DM_DB_PARTITION_STATS AS sdmvPTNS
ON    sOBJ.object_id = sdmvPTNS.object_id

WHERE 
      sOBJ.type = 'U'
AND sOBJ.is_ms_shipped = 0x0
AND sdmvPTNS.index_id < 2

GROUP BY sOBJ.schema_id, sOBJ.name

ORDER BY [TableName]
GO

	/**************************************************************************************************************************************
	What happend if you have a NC in the table?
	Idem before

	SYS.PARTITIONS vs SYS.DM_DB_PARTITION_STATS
	
	**************************************************************************************************************************************/


-- 3. sp_MSforeachtable [System Stored Procedure]
-- This approach can be used for testing purposes but it is not recommended for use in any production code. 
-- sp_MSforeachtable is an undocumented system stored procedure and may change anytime without prior notification from Microsoft.
DECLARE @TableRowCounts TABLE 
(
	  [TableName] VARCHAR(128)
	, [RowCount]  INT
)

INSERT INTO @TableRowCounts ([TableName], [RowCount])
EXEC sp_MSforeachtable 'SELECT ''?'' [TableName], COUNT(*) [RowCount] FROM ?';

SELECT 
	  [TableName]
	, [RowCount]
FROM @TableRowCounts
ORDER BY [TableName]
GO

	/**********************************************
	Que info tenemos en la web para este SP?
	sp_MSforeachtable
	**********************************************/


-- 4. COALESCE() [SQL Function]
DECLARE @QueryString NVARCHAR(MAX)

SELECT @QueryString = COALESCE(@QueryString + ' UNION ALL ','')
                      + 'SELECT '
                      + '''' + QUOTENAME(SCHEMA_NAME(sOBJ.schema_id))
                      + '.' + QUOTENAME(sOBJ.name) + '''' + ' AS [TableName]
                      , COUNT(*) AS [RowCount] FROM '
                      + QUOTENAME(SCHEMA_NAME(sOBJ.schema_id))
                      + '.' + QUOTENAME(sOBJ.name) + ' WITH (NOLOCK) '
FROM SYS.OBJECTS AS sOBJ

WHERE
    sOBJ.type = 'U'
AND sOBJ.is_ms_shipped = 0x0

ORDER BY SCHEMA_NAME(sOBJ.schema_id), sOBJ.name ;

	SELECT @QueryString
	EXEC sp_executesql @QueryString
GO
