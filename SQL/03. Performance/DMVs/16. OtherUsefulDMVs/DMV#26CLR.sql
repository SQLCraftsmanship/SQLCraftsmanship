
-------------------------------------------------------------------------------------------------------
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-os-workers-transact-sql?view=sql-server-ver15
-------------------------------------------------------------------------------------------------------

-- Find long running SQL/CLR tasks
-- This will help you uncover any long-running, potentially-troublesome CLR tasks
SELECT 
      os.task_address
    , os.[state]
    , os.last_wait_type
    , clr.[state]
    , clr.forced_yield_count

FROM sys.dm_os_workers AS os
JOIN sys.dm_clr_tasks  AS clr
ON   os.task_address = clr.sos_task_address

WHERE clr.[type] = 'E_TYPE_USER';

-- You want to be on the lookout for any rows that have a forced_yield_count above zero, or for rows that 
-- have a last_wait_type of SQLCLR_QUANTUM_PUNISHMENT. This portentously-named wait type indicates that 
-- the task previously exceeded its allowed quantum, and so caused the SQL OS scheduler to intervene and 
-- reschedule it at the end of the queue. The forced_yield_count indicates the number of times that this 
-- has happened.
