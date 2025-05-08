

Memory check

SELECT total_physical_memory_kb/1024 [Total Physical Memory in MB],
available_physical_memory_kb/1024 [Physical Memory Available in MB],
system_memory_state_desc
FROM sys.dm_os_sys_memory;

SELECT physical_memory_in_use_kb/1024 [Physical Memory Used in MB],
process_physical_memory_low [Physical Memory Low],
process_virtual_memory_low [Virtual Memory Low]
FROM sys.dm_os_process_memory;

SELECT committed_kb/1024 [SQL Server Committed Memory in MB],
committed_target_kb/1024 [SQL Server Target Committed Memory in MB]
FROM sys.dm_os_sys_info;


/* Understand the Resource Pool Configuration

cache_memory_kb		The current total cache memory usage in kilobytes. Not nullable.
compile_memory_kb	The current total stolen memory usage in kilobytes (KB). 
					Most this usage would be for compile and optimization, but it can also include other memory users.
max_memory_kb		The maximum amount of memory, in kilobytes, that the resource pool can have. This is based on the 
					current settings and server state.
used_memory_kb		The amount of memory used, for the resource pool.
target_memory_kb	The target amount of memory, in kilobytes, the resource pool is trying to attain.
out_of_memory_count	The number of failed memory allocations in the pool since the Resource Governor statistics were reset. Not nullable.
max_memory_percent	The current configuration for the percentage of total server memory that can be used by requests in this resource pool. Not nullable.

*/
SELECT Name, cache_memory_kb, max_memory_kb, used_memory_kb, target_memory_kb, out_of_memory_count, max_memory_percent, max_cpu_percent 
	, 'used_memory_kb' AS ColumnName, 'The amount of memory used, for the resource pool.' AS Detailcolumn
FROM sys.dm_resource_governor_resource_pools
GO;


/* Check Workload Group Settings

max_request_grant_memory_kb			Maximum memory grant size, in kilobytes, of a single request since the statistics were reset.
request_max_memory_grant_percent	Current setting for the maximum memory grant, as a percentage, for a single request.
request_memory_grant_timeout_sec	Current setting for memory grant time-out, in seconds, for a single request.
max_dop								Configured maximum degree of parallelism for the workload group. The default value, 0, uses global 
									settings.
effective_max_dop					Effective maximum degree of parallelism for the workload group.
request_max_memory_grant_percent_numeric Current setting for the maximum memory grant, as a percentage, for a single request. 
										 Similar to request_max_memory_grant_percent, which returns an integer, 
										 request_max_memory_grant_percent_numeric returns a float. 
										 Starting with SQL Server 2019 (15.x), the parameter REQUEST_MAX_MEMORY_GRANT_PERCENT accepts 
										 values with a possible range of 0-100 and stores them as the float data type.
										 Prior to SQL Server 2019 (15.x), REQUEST_MAX_MEMORY_GRANT_PERCENT is an integer with possible 
										 range of 1-100. For more information, see CREATE WORKLOAD GROUP.

Is not nullable.
*/
SELECT Name, max_request_grant_memory_kb, request_max_memory_grant_percent, request_memory_grant_timeout_sec, 
	  max_dop, effective_max_dop, request_max_memory_grant_percent_numeric
FROM sys.dm_resource_governor_workload_groups;
GO



EXEC dbo.sp_BlitzCache @SortOrder = 'memory grant'

--- EXEC dbo.sp_BlitzCache @SortOrder = 'average memory grant'


sp_LogHunter

EXEC sp_HealthParser 
    @warnings_only = 1, 
    @skip_locks = 1;
	
sp_PressureDetector
