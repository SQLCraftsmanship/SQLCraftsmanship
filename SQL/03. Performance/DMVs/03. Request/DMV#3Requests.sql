---------------------------------------------------------------------------------------------------------
-- Look at currently executing requests, status and wait type

-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-requests-transact-sql?view=sql-server-ver15

/*
statement_start_offset (int)	
    Indicates, in bytes, beginning with 0, the starting position of the currently executing statement 
    for the currently executing batch or persisted object. Can be used together with the sql_handle, 
    the statement_end_offset, and the sys.dm_exec_sql_text dynamic management function to retrieve the 
    currently executing statement for the request. Is nullable.

statement_end_offset (int)	
    Indicates, in bytes, starting with 0, the ending position of the currently executing statement 
    for the currently executing batch or persisted object. Can be used together with the sql_handle, 
    the statement_start_offset, and the sys.dm_exec_sql_text dynamic management function to retrieve 
    the currently executing statement for the request. Is nullable.

sql_handle (varbinary(64))	
    Is a token that uniquely identifies the batch or stored procedure that the query is part of. 
    Is nullable.
*/

-----------------------------------------------------------------------------------------------------------
SELECT
      r.session_id
    , r.[status]
    , r.wait_type
    , r.scheduler_id
    , SUBSTRING(qt.[text], 
                r.statement_start_offset / 2,
                (CASE 
                    WHEN r.statement_end_offset = -1 THEN 
                        LEN(CONVERT(NVARCHAR(MAX), qt.[text])) * 2 ELSE r.statement_end_offset
                    END - r.statement_start_offset ) / 2) AS [statement_executing]
    , DB_NAME(qt.[dbid]) AS [DatabaseName]
    , OBJECT_NAME(qt.objectid) AS [ObjectName]
    , r.cpu_time
    , r.total_elapsed_time
    , r.reads
    , r.writes
    , r.logical_reads
    , r.plan_handle
FROM sys.dm_exec_requests AS r
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS qt
WHERE r.session_id > 50
ORDER BY r.scheduler_id, r.[status], r.session_id ;

    --------------------------------------------------------------------------------------------------------
    -- Book II. Page 63
    -- Parsing the SQL text using statement_start_offset and statement_end_offset
    --------------------------------------------------------------------------------------------------------
    SELECT 
          er.statement_start_offset
        , er.statement_end_offset
        , SUBSTRING(est.text, er.statement_start_offset / 2,
                    (CASE WHEN er.statement_end_offset = -1 
                        THEN DATALENGTH(est.text)
                        ELSE er.statement_end_offset
                    END - er.statement_start_offset ) / 2) AS statement_executing
        , est.text AS [full statement code]

    FROM sys.dm_exec_requests er
    JOIN sys.dm_exec_sessions es
    ON   es.session_id = er.session_id
    CROSS APPLY sys.dm_exec_sql_text(der.sql_handle) est
    WHERE es.is_user_process = 1
    AND   er.session_id <> @@spid
    ORDER BY er.session_id ;

    ------------------------------
    -- Ejemplo I
    ------------------------------
    -- One TAB
    WAITFOR DELAY '00:01'; -- One minute

    BEGIN TRANSACTION
        -- WAITFOR DELAY '00:01' ; 
        INSERT INTO AdventureWorks.Production.ProductCategory(Name, ModifiedDate)
        VALUES ('Reflectors', GETDATE())
    ROLLBACK TRANSACTION
    SELECT Name ,
    ModifiedDate
    FROM AdventureWorks.Production.ProductCategory
    WHERE Name = 'Reflectors' ;
    -- WAITFOR DELAY '00:01' ;

-----------------------------------------------------------------------------------------------------------
-- Book II. Page 65
-- Adapting this script we can examine the activity of each currently active request in each active session
-- in terms of CPU usage, number of pages allocated to the reques in memory, amount of time spent waiting,
-- current execution time, or number of physical reads

-- Nota
-- Este script esta muy bueno para convertirlo a SP Dinamico dependiendo de que es lo que se quiere ver.
-----------------------------------------------------------------------------------------------------------
SELECT
      er.session_id
    , DB_NAME(er.database_id) AS database_name
    , eqp.query_plan
    , SUBSTRING(est.text, er.statement_start_offset / 2,
                    (CASE WHEN er.statement_end_offset = -1
                          THEN DATALENGTH(est.text)
                          ELSE er.statement_end_offset
                     END - er.statement_start_offset ) / 2) AS [statement executing]
    , er.cpu_time
    -- , er.granted_query_memory
    -- , er.wait_time
    -- , er.total_elapsed_time
    -- , er.reads

FROM sys.dm_exec_requests er
JOIN sys.dm_exec_sessions es
ON   es.session_id = er.session_id
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle)    est
CROSS APPLY sys.dm_exec_query_plan(er.plan_handle) eqp

WHERE 
      es.is_user_process = 1
AND   er.session_id <> @@spid

ORDER BY er.cpu_time DESC ;
-- ORDER BY er.granted_query_memory DESC ;
-- ORDER BY er.wait_time DESC;
-- ORDER BY er.total_elapsed_time DESC;
-- ORDER BY er.reads DESC;


-----------------------------------------------------------------------------------------------------------
-- Book II. Page 67
-- Who is running what, right now?
-----------------------------------------------------------------------------------------------------------
SELECT 
      est.text AS [Command text]
    , es.login_time
    , es.[host_name]
    , es.[program_name]
    , er.session_id
    , ec.client_net_address
    , er.status
    , er.command
    , DB_NAME(er.database_id) AS DatabaseName

FROM sys.dm_exec_requests    er

JOIN sys.dm_exec_connections ec
ON   er.session_id = ec.session_id

JOIN sys.dm_exec_sessions    es
ON   es.session_id = er.session_id

CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS est

WHERE es.is_user_process = 1

-----------------------------------------------------------------------------------------------------------
-- Book II. Page 69
-- A better version of sp_who2 but less than WhoIsActive.
-----------------------------------------------------------------------------------------------------------
SELECT 
      es.session_id
    , es.status
    , es.login_name
    , es.[HOST_NAME]
    , er.blocking_session_id
    , DB_NAME(er.database_id) AS database_name
    , er.command
    , es.cpu_time
    , es.reads
    , es.writes
    , ec.last_write
    , es.[program_name]
    , er.wait_type
    , er.wait_time
    , er.last_wait_type
    , er.wait_resource
    , CASE es.transaction_isolation_level
        WHEN 0 THEN 'Unspecified'
        WHEN 1 THEN 'ReadUncommitted'
        WHEN 2 THEN 'ReadCommitted'
        WHEN 3 THEN 'Repeatable'
        WHEN 4 THEN 'Serializable'
        WHEN 5 THEN 'Snapshot'
      END AS transaction_isolation_level
    , OBJECT_NAME(est.objectid, er.database_id) AS OBJECT_NAME
    , SUBSTRING(est.text, er.statement_start_offset / 2,
                (CASE WHEN er.statement_end_offset = -1
                      THEN DATALENGTH(est.text)
                    ELSE er.statement_end_offset
                 END - er.statement_start_offset ) / 2) AS [executing statement]
    , eqp.query_plan
FROM sys.dm_exec_sessions es

LEFT JOIN sys.dm_exec_requests er
ON es.session_id = er.session_id

LEFT JOIN sys.dm_exec_connections ec
ON es.session_id = ec.session_id

CROSS APPLY sys.dm_exec_sql_text(der.sql_handle)    est
CROSS APPLY sys.dm_exec_query_plan(der.plan_handle) eqp

