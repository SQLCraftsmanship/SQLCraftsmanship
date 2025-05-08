
/*****************************************************************************************************************************************
https://docs.microsoft.com/en-us/sql/relational-databases/performance-monitor/monitor-memory-usage?view=sql-server-ver15
*****************************************************************************************************************************************/

-- Determining current memory allocation
-- The following queries return information about currently allocated memory.
SELECT
	(total_physical_memory_kb/1024) AS Total_OS_Memory_MB,
	(available_physical_memory_kb/1024)  AS Available_OS_Memory_MB
FROM SYS.DM_OS_SYS_MEMORY;

SELECT  
	(physical_memory_in_use_kb/1024) AS Memory_used_by_Sqlserver_MB,  
	(locked_page_allocations_kb/1024) AS Locked_pages_used_by_Sqlserver_MB,  
	(total_virtual_address_space_kb/1024) AS Total_VAS_in_MB,
	process_physical_memory_low,  
	process_virtual_memory_low  
FROM SYS.DM_OS_PROCESS_MEMORY;

-- Determining current SQL Server memory utilization
-- The following query returns information about current SQL Server memory utilization.
SELECT
	sqlserver_start_time,
	(committed_kb/1024) AS Total_Server_Memory_MB,
	(committed_target_kb/1024)  AS Target_Server_Memory_MB
FROM SYS.DM_OS_SYS_INFO;

-- Determining page life expectancy
-- The following query uses sys.dm_os_performance_counters to observe the SQL Server instance's current page life expectancy value at the overall buffer manager level, and at each NUMA node level.
SELECT
CASE instance_name WHEN '' THEN 'Overall' ELSE instance_name END AS NUMA_Node, cntr_value AS PLE_s
FROM sys.dm_os_performance_counters    
WHERE counter_name = 'Page life expectancy';

