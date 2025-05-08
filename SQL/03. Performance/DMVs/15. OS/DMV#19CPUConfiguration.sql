
------------------------------------------------------------------------------------------------------
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-os-sys-info-transact-sql?view=sql-server-ver15
------------------------------------------------------------------------------------------------------

-- The hyperthread_ratio column treats both multi-core and hyperthreading the same (which they are as 
-- far as the logical processor count goes), so it cannot tell the difference between a quad-core 
-- processor and a dual-core processor with hyperthreading enabled. In each case, these queries would 
-- report a hyperthread_ratio of 4.

-- Hardware information from SQL Server
-- (Cannot distinguish between HT and multi-core)
SELECT 
      cpu_count         AS [Logical CPU Count]
    , hyperthread_ratio AS [Hyperthread Ratio]
    , cpu_count / hyperthread_ratio         AS [Physical CPU Count]
    , physical_memory_in_bytes / 1048576    AS [Physical Memory (MB)] --Esta no esa en 2019
    , sqlserver_start_time
FROM sys.dm_os_sys_info;

-- Hardware information from SQL Server 2005
-- (Cannot distinguish between HT and multi-core)
SELECT
      cpu_count         AS [Logical CPU Count]
    , hyperthread_ratio AS [Hyperthread Ratio]
    , cpu_count / hyperthread_ratio         AS [Physical CPU Count]
    , physical_memory_in_bytes / 1048576    AS [Physical Memory (MB)]
FROM sys.dm_os_sys_info ;
