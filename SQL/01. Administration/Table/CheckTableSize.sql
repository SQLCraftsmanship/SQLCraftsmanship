
-- Step 1: Get Server Name
SELECT @@SERVERNAME AS [Server Name]

-- Step 2: Check CDC Status
USE master
GO
SELECT name, is_cdc_enabled 
FROM sys.databases 
WHERE name IN ('TraceManager_v1')
GO

-- Step 3: Enabled CDC on DBs
USE TraceManager_v1
GO
EXEC sys.sp_cdc_enable_db
GO

-- Step 4: Get Tables without PK/UQ
-- The db [SupplyChainOps] has 69 tables without PK or UQ.
-- EXEC master.dbo.usp_ListTablesWithoutPKorUQ @DatabaseName = 'TraceServices_v1';

USE master;
GO

IF OBJECT_ID('dbo.usp_ListTablesWithoutPKorUQ', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_ListTablesWithoutPKorUQ;
GO

CREATE PROCEDURE dbo.usp_ListTablesWithoutPKorUQ
    @DatabaseName SYSNAME
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate that the database exists and is online
    IF NOT EXISTS (
        SELECT 1
        FROM sys.databases
        WHERE name = @DatabaseName
          AND state = 0 -- ONLINE
    )
    BEGIN
        RAISERROR('Database "%s" does not exist or is not online.', 16, 1, @DatabaseName);
        RETURN;
    END

    DECLARE @SQL NVARCHAR(MAX);

    SET @SQL = '
    USE ' + @DatabaseName + ';

    WITH TablesWithNoPKorUQ AS (
        SELECT 
            t.object_id,
            s.name AS SchemaName,
            t.name AS TableName
        FROM 
            sys.tables t
            INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE 
            t.is_ms_shipped = 0
            AND NOT EXISTS (
                SELECT 1
                FROM sys.key_constraints kc
                WHERE 
                    kc.parent_object_id = t.object_id
                    AND kc.type IN (''PK'', ''UQ'')
            )
    )
    SELECT 
        t.SchemaName,
        t.TableName,
        --SUM(p.rows) AS RowCount,
        ''No PK or Unique Constraint'' AS Reason
    FROM 
        TablesWithNoPKorUQ t
        LEFT JOIN sys.partitions p 
            ON t.object_id = p.object_id 
            AND p.index_id IN (0, 1)
    WHERE 
        p.index_id IS NOT NULL
    GROUP BY 
        t.SchemaName,
        t.TableName
    ORDER BY 
        t.SchemaName,
        t.TableName;
    ';

    EXEC sp_executesql @SQL;
END
GO

-- Step 5: Check if CDC is enabled on a table
-- To determine whether a source table has already been enabled for change data capture, examine the is_tracked_by_cdc column in the sys.tables catalog view.
USE SupplyChainOps
GO

SELECT is_tracked_by_cdc
FROM   sys.tables 
WHERE  is_tracked_by_cdc = 1


-- Step 6: Enabled the CDC
-- To Enable CDC on Table , CDC Should be enabled on Database level
USE SupplyChainOps
GO

DECLARE @TableSchema VARCHAR(100) = 'dbo'
DECLARE @TableName   VARCHAR(100) = 'ActiveDirectoryRepo'

DECLARE CDC_Cursor CURSOR FOR
  SELECT *
  FROM   (
		  /*SELECT 
			'T' AS TableName
		   ,'dbo' AS TableSchema
          UNION ALL
          SELECT 
			'T2' AS TableName
			,'dbo' AS TableSchema*/
           --IF want to Enable CDC on All Table, then use
			SELECT Name,SCHEMA_NAME(schema_id) AS TableSchema
			FROM   sys.objects
			WHERE  type = 'u'
			AND is_ms_shipped <> 1
         ) CDC

OPEN CDC_Cursor

FETCH NEXT FROM CDC_Cursor INTO @TableName,@TableSchema

WHILE @@FETCH_STATUS = 0
  BEGIN
      DECLARE @SQL NVARCHAR(1000)
      DECLARE @CDC_Status TINYINT

      SET @CDC_Status=(SELECT COUNT(*)
          FROM   cdc.change_tables
          WHERE  Source_object_id = OBJECT_ID(@TableSchema+'.'+@TableName))

      --IF CDC Already Enabled on Table , Print Message
      IF @CDC_Status = 1
        PRINT 'CDC is already enabled on ' +@TableSchema+'.'+@TableName+ ' Table'

      --IF CDC is not enabled on Table, Enable CDC and Print Message
      IF @CDC_Status <> 1
        BEGIN
            SET @SQL='EXEC sys.sp_cdc_enable_table
      @source_schema = '''+@TableSchema+''',
      @source_name   = ''' + @TableName
                     + ''',
      @role_name     = null;'
		
			PRINT  @SQL

           -- EXEC sp_executesql @SQL

            PRINT 'CDC  enabled on ' +@TableSchema+'.'+ @TableName+ ' Table successfully'
        END

      FETCH NEXT FROM CDC_Cursor INTO @TableName,@TableSchema
  END

CLOSE CDC_Cursor

DEALLOCATE CDC_Cursor


/*
EXEC sys.sp_cdc_enable_table
      @source_schema = 'dbo',
      @source_name   = 'Incortaload',
      @role_name     = null;
*/
