
---------------------------------------------------------------------------------------------------------------------------------------------------
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-procedure-stats-transact-sql?view=sql-server-ver15
---------------------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------------------------------
-- Top Cached SPs By Total Logical Reads. Logical reads relate to memory pressure
---------------------------------------------------------------------------------------------------------------------------------------------------
SELECT TOP (25)
      p.name AS [SP Name]
    , qs.total_logical_reads AS [TotalLogicalReads]
    , qs.total_logical_reads / qs.execution_count AS [AvgLogicalReads]
    , qs.execution_count
    , ISNULL(qs.execution_count / DATEDIFF(Second, qs.cached_time, GETDATE()),0) AS [Calls/Second]
    , qs.total_elapsed_time   -- The total elapsed time, in microseconds, for completed executions of this stored procedure.(elapsed = transcurrido)
    , qs.total_elapsed_time / qs.execution_count AS [avg_elapsed_time]
    , qs.cached_time   --Time at which the stored procedure was added to the cache.
FROM sys.procedures AS p
JOIN sys.dm_exec_procedure_stats AS qs
ON    p.[object_id] = qs.[object_id]
WHERE qs.database_id = DB_ID()
ORDER BY qs.total_logical_reads DESC;


---------------------------------------------------------------------------------------------------------------------------------------------------
-- Top Cached SPs By Total Physical Reads. Physical reads relate to disk I/O pressure.
-- If you see lots of stored procedures with high total physical reads or high average physical
-- reads, it could actually mean that you are under severe memory pressure, causing SQL
-- Server to go to the disk I/O subsystem for data. It could also mean that you have lots of
-- missing indexes or that you have "bad" queries (with no WHERE clauses for example) that
-- are causing lots of clustered index or table scans on large tables.
---------------------------------------------------------------------------------------------------------------------------------------------------
SELECT TOP (25)
      p.name AS [SP Name]
    , qs.total_physical_reads AS [TotalPhysicalReads]
    , qs.total_physical_reads / qs.execution_count AS [AvgPhysicalReads]
    , qs.execution_count
    , ISNULL(qs.execution_count / DATEDIFF(Second, qs.cached_time, GETDATE()), 0) AS [Calls/Second]
    , qs.total_elapsed_time
    , qs.total_elapsed_time / qs.execution_count AS [avg_elapsed_time]
    , qs.cached_time
FROM sys.procedures AS p
JOIN sys.dm_exec_procedure_stats AS qs
ON   p.[object_id] = qs.[object_id]
WHERE qs.database_id = DB_ID()
ORDER BY qs.total_physical_reads DESC;
