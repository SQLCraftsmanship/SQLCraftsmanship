
-----------------------------------------------------------------------------------------------------------
-- Book II. Example Page 58
-----------------------------------------------------------------------------------------------------------
SELECT
      est.Text
    , est.dbid
    , est.objectid
FROM sys.dm_exec_requests AS er
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) AS est
WHERE session_id = @@spid

    ------------------------------
    -- Ejemplo I
    ------------------------------
    -- One TAB
    DECLARE @time CHAR(8);
    SET @time = '00:10:00';
    WAITFOR DELAY @time;

    -- Second TAB
    WAITFOR DELAY '00:10:00';

    -- Third TAB
    SELECT
          est.Text
    FROM sys.dm_exec_requests AS er
    CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) AS est
    WHERE session_id <> @@spid;

    ------------------------------
    -- Ejemplo II
    ------------------------------
    -- One TAB
    CREATE PROCEDURE dbo.test
    AS 
        SELECT *
        FROM sys.objects
        WAITFOR DELAY '00:10:00'
    
    -- Second TAB
    SELECT
          est.dbid
        , est.objectid
        , est.encrypted
        , est.text
    FROM sys.dm_exec_requests AS er
    CROSS APPLY sys.dm_exec_sql_text(der.sql_handle) AS est
    WHERE objectid = object_id('test', 'p');
