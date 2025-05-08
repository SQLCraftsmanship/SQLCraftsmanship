
------------------------------------------------------------------------------------------------------
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-os-schedulers-transact-sql?view=sql-server-ver15
------------------------------------------------------------------------------------------------------

-- Get Avg task count and Avg runnable task count
-- High, sustained values for the current_tasks_count column usually indicate a blocking issue, and you 
-- can investigate this further using DMV#8. I have also seen it be a secondary indicator of I/O pressure, 
-- since high, sustained values for Avg Task Count can sometimes also be caused by I/O pressure. 
-- High, sustained values for the runnable_tasks_count column are usually a very good indicator of CPU 
-- pressure. By "high, sustained values", I mean anything above about 10-20 for most systems.

SELECT 
    AVG(current_tasks_count)  AS [Avg Task Count] ,
    AVG(runnable_tasks_count) AS [Avg Runnable Task Count]

FROM sys.dm_os_schedulers

WHERE 
    scheduler_id < 255
AND [status] = 'VISIBLE ONLINE';

-- Another query I use quite often, against the DMV, is one that will tell me whether nonuniform 
-- memory access (NUMA) is enabled on a given SQL Server instance.

-- Is NUMA enabled
SELECT 
    CASE COUNT(DISTINCT parent_node_id)
        WHEN 1 THEN 'NUMA disabled' ELSE 'NUMA enabled'
    END
FROM sys.dm_os_schedulers
WHERE parent_node_id <> 32;
