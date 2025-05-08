
--------------------------------------------------------------------------------------------------------
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-partition-stats-transact-sql?view=sql-server-ver15
---------------------------------------------------------------------------------------------------------

-- Returning all counts for all partitions of all indexes and heaps in a database
-- 
SELECT * FROM sys.dm_db_partition_stats;  
GO  

-- Returning all counts for all partitions of a table and its indexes
SELECT * FROM sys.dm_db_partition_stats   
WHERE object_id = OBJECT_ID('HumanResources.Employee');  
GO  

-- Table and row count information
SELECT 
      OBJECT_NAME(ps.[object_id]) AS [TableName]
    , i.name AS [IndexName]
    , SUM(ps.row_count)    AS [RowCount]                 -- The approximate number of rows in the partition.
    , SUM(used_page_count) AS total_number_of_used_pages -- Total number of pages used for the partition. Computed as in_row_used_page_count + lob_used_page_count + row_overflow_used_page_count.

FROM sys.dm_db_partition_stats AS ps

JOIN sys.indexes AS i 
ON   i.[object_id] = ps.[object_id]
AND  i.index_id = ps.index_id

WHERE 
      i.type_desc IN ('CLUSTERED', 'HEAP' )
AND   i.[object_id] > 100
AND   OBJECT_SCHEMA_NAME(ps.[object_id]) <> 'sys'

GROUP BY 
    ps.[object_id]
    , i.name

ORDER BY SUM(ps.row_count) DESC;


