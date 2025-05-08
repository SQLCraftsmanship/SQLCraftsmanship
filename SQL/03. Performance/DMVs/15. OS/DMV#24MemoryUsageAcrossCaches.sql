
--------------------------------------------------------------------------------------------------------
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-os-memory-cache-counters-transact-sql?view=sql-server-ver15
--------------------------------------------------------------------------------------------------------

-- Look at the number of items in different parts of the cache
SELECT
      Name
    , [type]
    , entries_count
--    , single_pages_kb           -- SQL 2008
--    , single_pages_in_use_kb    -- SQL 2008
--    , multi_pages_kb            -- SQL 2008
--    , multi_pages_in_use_kb     -- SQL 2008

FROM sys.dm_os_memory_cache_counters
WHERE 
    [type] = 'CACHESTORE_SQLCP'
OR  [type] = 'CACHESTORE_OBJCP'
ORDER BY multi_pages_kb DESC ;
