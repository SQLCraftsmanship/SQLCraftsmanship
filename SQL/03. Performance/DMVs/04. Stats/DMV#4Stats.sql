
-------------------------------------------------------------------------------------------------------
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-query-stats-transact-sql?view=sql-server-ver15
-------------------------------------------------------------------------------------------------------

-- TOP 5 Queries ranked by CPU time
SELECT TOP (5)
      total_worker_time  -- microseconds 
    , execution_count    -- Number of times that the plan has been executed since it was last compiled.
    , total_worker_time / execution_count AS [Avg CPU Time]
    , CASE
        WHEN deqs.statement_start_offset = 0 AND deqs.statement_end_offset = -1
            THEN '-- see objectText column--'
            ELSE '-- query --' + CHAR(13) + CHAR(10) + SUBSTRING( execText.text, 
                                                                  deqs.statement_start_offset / 2,
                                                                  (( CASE 
                                                                        WHEN deqs.statement_end_offset = -1
                                                                            THEN DATALENGTH(execText.text)
                                                                            ELSE deqs.statement_end_offset
                                                                     END ) - deqs.statement_start_offset ) / 2)
      END AS queryText

FROM sys.dm_exec_query_stats AS deqs

CROSS APPLY sys.dm_exec_sql_text(deqs.plan_handle) AS execText

ORDER BY deqs.total_worker_time DESC ;


-- TOP 5 Queries ranked by I/O amount
SELECT TOP (5)
      total_logical_reads
    , total_logical_writes
	, execution_count
    , (total_logical_reads +  total_logical_writes) / execution_count AS [IO Time]
    , CASE
        WHEN deqs.statement_start_offset = 0 AND deqs.statement_end_offset = -1
            THEN '-- see objectText column--'
            ELSE '-- query --' + CHAR(13) + CHAR(10) + SUBSTRING( execText.text, 
                                                                  deqs.statement_start_offset / 2,
                                                                  (( CASE 
                                                                        WHEN deqs.statement_end_offset = -1
                                                                            THEN DATALENGTH(execText.text)
                                                                            ELSE deqs.statement_end_offset
                                                                     END ) - deqs.statement_start_offset ) / 2)
      END AS queryText

FROM sys.dm_exec_query_stats AS deqs

CROSS APPLY sys.dm_exec_sql_text(deqs.plan_handle) AS execText

ORDER BY [IO Time] DESC ;


