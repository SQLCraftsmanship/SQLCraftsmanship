
---------------------------------------------------------------------------------------------------------
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-query-memory-grants-transact-sql?view=sql-server-ver15
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------
-- Shows the memory required by both running (non-null grant_time) and waiting queries (null grant_time)
---------------------------------------------------------------------------------------------------------
SELECT
      DB_NAME(st.dbid) AS [DatabaseName]
    , mg.requested_memory_kb
    , mg.ideal_memory_kb
    , mg.request_time
    , mg.grant_time
    , mg.query_cost
    , mg.dop
    , st.[text]

FROM sys.dm_exec_query_memory_grants AS mg
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st

WHERE mg.request_time < COALESCE(grant_time, '99991231')
ORDER BY mg.requested_memory_kb DESC ;

