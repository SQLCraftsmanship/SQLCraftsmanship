
-----------------------------------------------------------------------------------------------------
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-os-wait-stats-transact-sql?view=sql-server-ver15
-----------------------------------------------------------------------------------------------------

-- Total waits are wait_time_ms (high signal waits indicates CPU pressure)
-- This query is useful to help confirm CPU pressure. Since Signal waits are time waiting for a CPU to 
-- service a thread, if you record total signal waits above roughly 10-15% then this is a pretty good 
-- indicator of CPU pressure. These wait stats are cumulative since SQL Server was last restarted so you 
-- need to know what your baseline value for signal waits is, and watch the trend over time.

SELECT 
      CAST(100.0 * SUM(signal_wait_time_ms) / SUM(wait_time_ms) AS NUMERIC(20,2)) AS [%signal (cpu) waits]
    , CAST(100.0 * SUM(wait_time_ms - signal_wait_time_ms) / SUM(wait_time_ms) AS NUMERIC(20, 2)) AS [%resource waits]
FROM sys.dm_os_wait_stats;


-- Our second example script, using the sys.dm_os_wait_stats DMV will help determine on which resources 
-- SQL Server is spending the most time waiting Isolate top waits for server instance since last restart
-- or statistics clear
WITH Waits
AS ( 
        SELECT
              wait_type
            , wait_time_ms / 1000. AS wait_time_s 
            , 100. * wait_time_ms / SUM(wait_time_ms) OVER ( ) AS pct
            , ROW_NUMBER() OVER ( ORDER BY wait_time_ms DESC ) AS rn
        FROM  sys.dm_os_wait_stats
        WHERE wait_type NOT IN ('CLR_SEMAPHORE'     , 'LAZYWRITER_SLEEP',
                                'RESOURCE_QUEUE'    , 'SLEEP_TASK',
                                'SLEEP_SYSTEMTASK'  , 'SQLTRACE_BUFFER_FLUSH', 
                                'WAITFOR'           , 'LOGMGR_QUEUE', 
                                'CHECKPOINT_QUEUE'  , 'REQUEST_FOR_DEADLOCK_SEARCH',
                                'XE_TIMER_EVENT'    , 'BROKER_TO_FLUSH',
                                'BROKER_TASK_STOP'  , 'CLR_MANUAL_EVENT',
                                'CLR_AUTO_EVENT'    , 'DISPATCHER_QUEUE_SEMAPHORE',
                                'FT_IFTS_SCHEDULER_IDLE_WAIT','XE_DISPATCHER_WAIT',
                                'XE_DISPATCHER_JOIN' )
    )
 
SELECT 
      W1.wait_type
    , CAST(W1.wait_time_s AS DECIMAL(12, 2)) AS wait_time_s
    , CAST(W1.pct AS DECIMAL(12, 2)) AS pct
    , CAST(SUM(W2.pct) AS DECIMAL(12, 2)) AS running_pct
FROM Waits AS W1
JOIN Waits AS W2 ON W2.rn <= W1.rn
GROUP BY W1.rn, W1.wait_type, W1.wait_time_s, W1.pct
HAVING SUM(W2.pct) - W1.pct < 95 ; -- percentage threshold
