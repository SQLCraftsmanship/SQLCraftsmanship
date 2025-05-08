
---------------------------------------------------------------------------------------------------------
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-os-buffer-descriptors-transact-sql?view=sql-server-ver15
---------------------------------------------------------------------------------------------------------

-- Get total buffer usage by database
-- It allows you to determine how much memory each database is using in the buffer pool. It could help you 
-- to decide how to deploy databases in a consolidation or scale-out effort. 
SELECT 
      DB_NAME(database_id)  AS [Database Name]
    , COUNT(*) * 8 / 1024.0 AS [Cached Size (MB)]
FROM sys.dm_os_buffer_descriptors

WHERE database_id > 4       -- exclude system databases
AND   database_id <> 32767  -- exclude ResourceDB

GROUP BY DB_NAME(database_id)
ORDER BY [Cached Size (MB)] DESC ;


-- Breaks down buffers by object (table, index) in the buffer pool
-- The second query tells you which objects are using the most memory in your buffer pool and is filtered
-- by the current database.
SELECT 
      OBJECT_NAME(p.[object_id]) AS [ObjectName]
    , p.index_id
    , COUNT(*) / 128 AS [Buffer size(MB)]
    , COUNT(*) AS [Buffer_count]
FROM sys.allocation_units AS a

JOIN sys.dm_os_buffer_descriptors AS b 
ON   a.allocation_unit_id = b.allocation_unit_id

JOIN sys.partitions AS p
ON   a.container_id = p.hobt_id

WHERE b.database_id = DB_ID()
AND   p.[object_id] > 100 -- exclude system objects

GROUP BY p.[object_id], p.index_id

ORDER BY buffer_count DESC;

