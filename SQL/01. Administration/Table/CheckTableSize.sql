

/*
Execution mode
	EXEC dbo.usp_GetTableSizes
	EXEC dbo.usp_GetTableSizes @TableList = 'Invoice,InvoiceScan,Orders';
*/

USE ExpressLaneDataStore;
GO

IF OBJECT_ID('dbo.usp_GetTableSizes', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_GetTableSizes;
GO

CREATE PROCEDURE dbo.usp_GetTableSizes
    @TableList NVARCHAR(MAX) = NULL  -- Optional: comma-separated table names, or NULL for all tables
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TableFilter TABLE (TableName SYSNAME);

    -- If a list is provided, split it into a table
    IF @TableList IS NOT NULL
    BEGIN
        INSERT INTO @TableFilter (TableName)
        SELECT LTRIM(RTRIM(value))
        FROM STRING_SPLIT(@TableList, ',')
    END
    ELSE
    BEGIN
        -- Otherwise, use all user tables in the database
        INSERT INTO @TableFilter (TableName)
        SELECT name
        FROM sys.tables;
    END

    -- Main CTE for sizing
    WITH TableSizes AS (
        SELECT 
            s.name + '.' + t.name AS TableName,
            CAST(SUM(a.total_pages) * 8.0 / 1024 AS DECIMAL(18,2)) AS Sizing_MB,
            CAST(SUM(a.total_pages) * 8.0 / 1024 / 1024 AS DECIMAL(18,4)) AS Sizing_GB,
            SUM(ps.row_count) AS Rows
        FROM @TableFilter f
        JOIN sys.tables t ON t.name = f.TableName
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        LEFT JOIN sys.dm_db_partition_stats ps ON t.object_id = ps.object_id AND ps.index_id IN (0,1)
        LEFT JOIN sys.allocation_units a ON ps.partition_id = a.container_id
        GROUP BY s.name, t.name
    )

    -- Output with total row
    SELECT * FROM TableSizes
    UNION ALL
    SELECT 
        'TOTAL',
        SUM(Sizing_MB),
        SUM(Sizing_GB),
        SUM(Rows)
    FROM TableSizes
    ORDER BY 
        CASE WHEN TableName = 'TOTAL' THEN 1 ELSE 0 END,
        Sizing_MB DESC;
END
GO
