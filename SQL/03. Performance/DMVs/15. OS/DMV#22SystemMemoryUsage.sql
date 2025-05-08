
--------------------------------------------------------------------------------------------------------
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-os-sys-memory-transact-sql?view=sql-server-ver15
---------------------------------------------------------------------------------------------------------

-- Good basic information about memory amounts and state.
SELECT 
      total_physical_memory_kb
    , available_physical_memory_kb
    , total_page_file_kb
    , available_page_file_kb
    , system_memory_state_desc
FROM sys.dm_os_sys_memory;
