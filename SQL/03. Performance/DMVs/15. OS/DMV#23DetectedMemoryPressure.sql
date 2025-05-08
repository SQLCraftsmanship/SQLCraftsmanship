
--------------------------------------------------------------------------------------------------------
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-os-process-memory-transact-sql?view=sql-server-ver15
--------------------------------------------------------------------------------------------------------

-- SQL Server Process Address space info (shows whether locked pages is enabled, among other things)
SELECT
      physical_memory_in_use_kb
    , locked_page_allocations_kb
    , page_fault_count
    , memory_utilization_percentage
    , available_commit_limit_kb
    , process_physical_memory_low
    , process_virtual_memory_low

FROM sys.dm_os_process_memory;
