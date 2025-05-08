
-- SP_EXECUTESQL
SELECT 
	cache.size_in_bytes,
	cache.objtype,
	stat.execution_count,
	stext.text,
	splan.query_plan
	, cache.plan_handle 
FROM sys.dm_exec_query_stats as stat
CROSS APPLY sys.dm_exec_sql_text(stat.sql_handle) as stext
CROSS APPLY sys.dm_exec_query_plan(stat.plan_handle) as splan
JOIN sys.dm_exec_cached_plans as cache on cache.plan_handle = stat.plan_handle
WHERE TEXT LIKE '%@p__linq__0 BIGINT, @p__linq__1 NVARCHAR(20)%'



-- Remove the specific plan from the cache.
DBCC FREEPROCCACHE (0x06000700553F9835901C43367D00000001000000000000000000000000000000000000000000000000000000);
GO