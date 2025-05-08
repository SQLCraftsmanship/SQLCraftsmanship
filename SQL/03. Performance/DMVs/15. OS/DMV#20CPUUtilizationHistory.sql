
------------------------------------------------------------------------------------------------------
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sql-server-operating-system-related-dynamic-management-views-transact-sql?view=sql-server-ver15
------------------------------------------------------------------------------------------------------

-- It script returns the CPU utilization history over the last 30 minutes both in terms of CPU usage 
-- by the SQL Server process and total CPU usage by all other processes on your database server.
-- In my experimentation, you can only retrieve 256 minutes worth of data from this query.

-- Get CPU Utilization History for last 30 minutes (in one minuteintervals)
-- This version works with SQL Server 2008 and SQL Server 2008 R2 only
DECLARE @ts_now BIGINT = (SELECT cpu_ticks / (cpu_ticks / ms_ticks) FROM sys.dm_os_sys_info) ;

SELECT TOP (30)
      SQLProcessUtilization AS [SQL Server Process CPU Utilization]
    , SystemIdle AS [System Idle Process]
    , 100 - SystemIdle - SQLProcessUtilization AS [Other Process CPU Utilization]
    , DATEADD(ms, -1 * ( @ts_now - [timestamp] ), GETDATE()) AS [EventTime]

FROM (
        SELECT 
            record.value('(./Record/@id)[1]', 'int') AS record_id
            , record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') AS [SystemIdle]
            , record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]','int') AS [SQLProcessUtilization]
            , [timestamp]
        FROM ( 
                SELECT 
                    [timestamp]
                    , CONVERT(XML, record) AS [record]
                FROM  sys.dm_os_ring_buffers
                WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
                AND   record LIKE N'%<SystemHealth>%'
             ) AS x
      ) AS y
 ORDER BY record_id DESC ;
