
-- CPU USE QUERY
DECLARE @ms_ticks_now BIGINT
SELECT @ms_ticks_now = ms_ticks
FROM sys.dm_os_sys_info;
SELECT TOP 60 record_id
    ,dateadd(ms, - 1 * (@ms_ticks_now - [timestamp]), GetDate()) AS EventTime
    ,[SQLProcess (%)]
    ,SystemIdle
    ,100 - SystemIdle - [SQLProcess (%)] AS [OtherProcess (%)]
FROM (
    SELECT record.value('(./Record/@id)[1]', 'int') AS record_id
        ,record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') AS SystemIdle
        ,record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') AS [SQLProcess (%)]
        ,TIMESTAMP
    FROM (
        SELECT TIMESTAMP
            ,convert(XML, record) AS record
        FROM sys.dm_os_ring_buffers
        WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
            AND record LIKE '%<SystemHealth>%'
        ) AS x
    ) AS y
ORDER BY record_id DESC


-- Script to check CPU Online
SELECT
	r.session_id
	, st.text as Batch_Text
	, SUBSTRING (st.text, statement_start_offset / 2 + 1, (
					(
						CASE
							WHEN r.statement_end_offset = -1
								THEN (LEN(CONVERT(NVARCHAR(MAX), st.text)) * 2)
							ELSE
								r.statement_end_offset
						END
					) - r.statement_start_offset
				) / 2 + 1) AS Statement_Text
	, qp.query_plan AS 'XML Plan'
	, r.cpu_time
	, r.total_elapsed_time
	, r.logical_reads
	, r.writes
	, r.dop

FROM SYS.DM_EXEC_REQUESTS R
CROSS APPLY SYS.DM_EXEC_SQL_TEXT (r.sql_handle) AS ST
CROSS APPLY SYS.DM_EXEC_QUERY_PLAN (r.plan_handle) AS QP
ORDER BY CPU_TIME

-- Script to checl CPU use in the past time
SELECT
	TOP 50
	qs.execution_count AS [Execution Count]
	, (qs.total_logical_reads) / 1000.0 AS [Total Logical Reads in ms]
	, (qs.total_logical_reads / qs.execution_count) / 1000.0 AS [Avg Logical REads in ms]
	, (qs.total_worker_time) / 1000.0 AS [Total Worker Time in ms]
	, (qs.total_worker_time / qs.execution_count) / 1000.0 AS [Avg Worker time in ms]
	, (qs.total_elapsed_time) / 1000.0 AS [Total Elapsed Time in ms]
	, (qs.total_elapsed_time / qs.execution_count) / 1000.0 AS [Avg Elapsed Time in ms]
	, qs.creation_time AS [Creation Time]
	, t.text AS [Complete Query Text]
	, qp.query_plan AS [Query Plan]

FROM SYS.DM_EXEC_QUERY_STATS AS qs WITH(NOLOCK)
CROSS APPLY SYS.DM_EXEC_SQL_TEXT(plan_handle) AS t
CROSS APPLY SYS.DM_EXEC_QUERY_PLAN(plan_handle) AS qp
-- WHERE t.dbid = DB_ID()
ORDER BY (qs.total_logical_reads / qs.execution_count) DESC


-- Script to check CPU Online
SELECT
	r.session_id
	, st.text as Batch_Text
	, SUBSTRING (st.text, statement_start_offset / 2 + 1, (
					(
						CASE
							WHEN r.statement_end_offset = -1
								THEN (LEN(CONVERT(NVARCHAR(MAX), st.text)) * 2)
							ELSE
								r.statement_end_offset
						END
					) - r.statement_start_offset
				) / 2 + 1) AS Statement_Text
	, qp.query_plan AS 'XML Plan'
	, r.cpu_time
	, r.total_elapsed_time
	, r.logical_reads
	, r.writes
	, r.dop

FROM SYS.DM_EXEC_REQUESTS R
CROSS APPLY SYS.DM_EXEC_SQL_TEXT (r.sql_handle) AS ST
CROSS APPLY SYS.DM_EXEC_QUERY_PLAN (r.plan_handle) AS QP
ORDER BY CPU_TIME

-- Script to checl CPU use in the past time
SELECT
	TOP 50
	qs.execution_count AS [Execution Count]
	, (qs.total_logical_reads) / 1000.0 AS [Total Logical Reads in ms]
	, (qs.total_logical_reads / qs.execution_count) / 1000.0 AS [Avg Logical REads in ms]
	, (qs.total_worker_time) / 1000.0 AS [Total Worker Time in ms]
	, (qs.total_worker_time / qs.execution_count) / 1000.0 AS [Avg Worker time in ms]
	, (qs.total_elapsed_time) / 1000.0 AS [Total Elapsed Time in ms]
	, (qs.total_elapsed_time / qs.execution_count) / 1000.0 AS [Avg Elapsed Time in ms]
	, qs.creation_time AS [Creation Time]
	, t.text AS [Complete Query Text]
	, qp.query_plan AS [Query Plan]

FROM SYS.DM_EXEC_QUERY_STATS AS qs WITH(NOLOCK)
CROSS APPLY SYS.DM_EXEC_SQL_TEXT(plan_handle) AS t
CROSS APPLY SYS.DM_EXEC_QUERY_PLAN(plan_handle) AS qp
-- WHERE t.dbid = DB_ID()
ORDER BY (qs.total_logical_reads / qs.execution_count) DESC