
--------------------------------------------------------------------------------------------------
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-file-space-usage-transact-sql?view=sql-server-ver15
--------------------------------------------------------------------------------------------------

-- Get Free Space in TempDB
USE tempdb;  
GO

SELECT 
       SUM(unallocated_extent_page_count)               AS [free pages]
    , (SUM(unallocated_extent_page_count) * 1.0 / 128 ) AS [free space in MB]
FROM sys.dm_db_file_space_usage;

-- Determining the Amount of Space Used by User Objects
USE tempdb;  
GO

SELECT 
       SUM(user_object_reserved_page_count)               AS [user object pages used]  
    , (SUM(user_object_reserved_page_count) * 1.0 / 128)  AS [user object space in MB]  
FROM sys.dm_db_file_space_usage;

-- Quick TempDB Summary
USE tempdb;  
GO

SELECT 
      SUM(user_object_reserved_page_count)     * 8.192 AS [UserObjectsKB]
    , SUM(internal_object_reserved_page_count) * 8.192 AS [InternalObjectsKB]
    , SUM(version_store_reserved_page_count)   * 8.192 AS [VersionStoreKB]
    , SUM(unallocated_extent_page_count)       * 8.192 AS [FreeSpaceKB]
FROM sys.dm_db_file_space_usage;

