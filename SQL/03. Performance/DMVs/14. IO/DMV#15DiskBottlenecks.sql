
----------------------------------------------------------------------------------------------------
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-io-virtual-file-stats-transact-sql?view=sql-server-ver15
----------------------------------------------------------------------------------------------------

-- Calculates average stalls per read, per write, and per total input/output for each database file.
-- Script 18 allows you to see the number of reads and writes on each data and log file, for every 
-- database running on the instance. It is sorted by average I/O stall time, in milliseconds.
-- This query shows which files are waiting the most time for disk I/O and can help you to decide where 
-- to locate individual files based on the disk resources you have available. You can also use it to help 
-- persuade someone like a SAN engineer that SQL Server is seeing disk bottlenecks for certain files.

SELECT 
      DB_NAME(database_id) AS [Database Name]
    , file_id
    , io_stall_read_ms
    , num_of_reads
    , CAST(io_stall_read_ms / ( 1.0 + num_of_reads ) AS NUMERIC(10, 1)) AS [avg_read_stall_ms]
    , io_stall_write_ms
    , num_of_writes
    , CAST(io_stall_write_ms / ( 1.0 + num_of_writes ) AS NUMERIC(10, 1)) AS [avg_write_stall_ms]
    , io_stall_read_ms + io_stall_write_ms  AS [io_stalls]
    , num_of_reads + num_of_writes          AS [total_io]
    , CAST(( io_stall_read_ms + io_stall_write_ms ) / ( 1.0 + num_of_reads + num_of_writes) AS NUMERIC(10,1)) AS [avg_io_stall_ms]

FROM sys.dm_io_virtual_file_stats(NULL, NULL)
ORDER BY avg_io_stall_ms DESC;

