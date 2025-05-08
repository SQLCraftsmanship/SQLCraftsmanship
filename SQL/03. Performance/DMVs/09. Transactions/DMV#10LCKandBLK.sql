
-----------------------------------------------------------------------------------------------------
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-tran-locks-transact-sql?view=sql-server-ver15
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-os-waiting-tasks-transact-sql?view=sql-server-ver15
-----------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------
-- Look at active Lock Manager resources for current database
-----------------------------------------------------------------------------------------------------
SELECT 
      request_session_id
    , DB_NAME(resource_database_id) AS [Database]
    , resource_type
    , resource_subtype
    , request_type
    , request_mode
    , resource_description
    , request_mode
    , request_owner_type

FROM sys.dm_tran_locks

WHERE
    request_session_id   > 50
AND resource_database_id = DB_ID()
AND request_session_id  <> @@SPID

ORDER BY request_session_id ;

-----------------------------------------------------------------------------------------------------
-- Look for blocking
-----------------------------------------------------------------------------------------------------
SELECT
      tl.resource_type
    , tl.resource_database_id
    , tl.resource_associated_entity_id
    , tl.request_mode
    , tl.request_session_id
    , wt.blocking_session_id
    , wt.wait_type
    , wt.wait_duration_ms

FROM sys.dm_tran_locks AS tl

JOIN sys.dm_os_waiting_tasks AS wt
ON   tl.lock_owner_address = wt.resource_address

ORDER BY wait_duration_ms DESC;
