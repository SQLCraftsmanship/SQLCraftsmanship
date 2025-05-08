

select @@servername
-- Step 1 Check CDC Status
USE master
GO
SELECT name, is_cdc_enabled 
FROM sys.databases 
WHERE name IN ('USFRET', 'USFPIMS', 'ClientData', 'UPLH')
GO

-- Step 2 Enabled CDC on DBs
USE USFRET
GO
EXEC sys.sp_cdc_enable_db
GO

USE USFPIMS
GO
EXEC sys.sp_cdc_enable_db
GO

USE ClientData
GO
EXEC sys.sp_cdc_enable_db
GO

USE UPLH
GO
EXEC sys.sp_cdc_enable_db
GO


-- Step 3 Enable for a table
-- To determine whether a source table has already been enabled for change data capture, 
-- examine the is_tracked_by_cdc column in the sys.tables catalog view.
USE USFRET
GO

SELECT is_tracked_by_cdc
FROM   sys.tables 
WHERE  is_tracked_by_cdc = 1


/*------------------------------------------------
Enable CDC on Set of Tables
( To Enable CDC on Table , CDC Should be enabled on Database level)
--------------------------------------------------*/
USE UPLH
GO

DECLARE @TableName   VARCHAR(100)
DECLARE @TableSchema VARCHAR(100)

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

            EXEC sp_executesql @SQL

            PRINT 'CDC  enabled on ' +@TableSchema+'.'+ @TableName+ ' Table successfully'
        END

      FETCH NEXT FROM CDC_Cursor INTO @TableName,@TableSchema
  END

CLOSE CDC_Cursor

DEALLOCATE CDC_Cursor
