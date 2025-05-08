
------------------------------------------------------------------------------------------------
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-tran-session-transactions-transact-sql?view=sql-server-ver15
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-tran-database-transactions-transact-sql?view=sql-server-ver15
------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------
-- Script 10, for example, provides a query that shows, per session, which databases are in use 
-- by a transaction open by that session, whether the transaction has upgraded to read-write in 
-- any of the databases (by default most transactions are read-only), when the transaction 
-- upgraded to read-write for that database, how many log records written, and how many bytes 
-- were used on behalf of those log records.
------------------------------------------------------------------------------------------------
SELECT
      st.session_id 
    , DB_NAME(dt.database_id) AS database_name
    , CASE 
        WHEN dt.database_transaction_begin_time IS NULL THEN 'readonly' ELSE 'read-write'
      END AS transaction_state
    , dt.database_transaction_begin_time AS read_write_start_time
    , dt.database_transaction_log_record_count
    , dt.database_transaction_log_bytes_used

FROM sys.dm_tran_session_transactions  AS st
JOIN sys.dm_tran_database_transactions AS dt
ON   st.transaction_id = dt.transaction_id
ORDER BY st.session_id, database_name

