
-- ---------------------------------------------------------------------------------------------------------------------------------------------------
-- Get SQL users that are connected and how many sessions they have
-- ---------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
	  Login_Name
	, COUNT([Session_id]) AS [session_count]

FROM  sys.dm_exec_sessions
WHERE is_user_process = 1 -- *
GROUP BY [Login_Name]
ORDER BY COUNT([Session_id]) DESC;

-- *
-- Note that much published code use WHERE session_id > 50 filter out system processes. However, certain SYSTEM
-- features, such as Database Mirroring or Service Broker can and will, use a session_id of grater than 50 UNIQUEIDENTIFIER
-- some circumstances. Hence the use here of is_user_process = 1.
-- Multiple open sessions may be an indicator og either poor sedign or improper usage habits by the end-user.


-- ---------------------------------------------------------------------------------------------------------------------------------------------------
-- Get session-level settings for the current session
-- ---------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
	  es.text_size
	, es.language
	, es.date_format
	, es.date_first
	, es.quoted_identifier
	, es.arithabort
	, es.ansi_null_dflt_on
	, es.ansi_defaults
	, es.ansi_warnings
	, es.ansi_padding
	, es.ansi_nulls
	, es.concat_null_yields_null
	, es.transaction_isolation_level
	, es.lock_timeout
	, es.deadlock_priority
FROM sys.dm_exec_sessions es
WHERE es.session_id = @@SPID

-- ---------------------------------------------------------------------------------------------------------------------------------------------------
-- Identify sessions with context switching
-- ---------------------------------------------------------------------------------------------------------------------------------------------------

-- Note
-- Context switching is the act of executiong T-SQL code under the guise of another user connection, in order to utilize their credentials and 
-- level of rights.
SELECT
	  session_id
	, login_name
	, original_login_name
FROM sys.dm_exec_sessions
WHERE is_user_process = 1
AND   login_name <> original_login_name


-- ---------------------------------------------------------------------------------------------------------------------------------------------------
-- Identify inactive sessions
-- ---------------------------------------------------------------------------------------------------------------------------------------------------

-- Note
-- All sessions that are open and have associated transations, but have had no active requests running in the las n days.
-- If cumulative activity is high, as indicated by the values of cpu_time, total_elapsed_time, total_scheduled_time, and so on, 
-- but the session has been inactive for a while, then it may be an application that keeps a more-or-less permanent session open and 
-- therefore there is little to be done about it.

DECLARE @days_old SMALLINT
SELECT  @days_old = 5 

SELECT 
	  es.session_id
	, es.login_time
	, es.last_request_start_time
	, es.last_request_end_time
	, es.[status]
	, es.[program_name]
	, es.cpu_time
	, es.total_elapsed_time
	, es.memory_usage
	, es.total_scheduled_time
	, es.total_elapsed_time
	, es.reads
	, es.writes
	, es.logical_reads
	, es.row_count
	, es.is_user_process
FROM sys.dm_exec_sessions es

JOIN sys.dm_tran_session_transactions dtst
ON   es.session_id = dtst.session_id

WHERE 
	es.is_user_process = 1
AND DATEDIFF(dd, es.last_request_end_time, GETDATE()) > @days_old
AND es.status != 'Running'

ORDER BY des.last_request_end_time


-- ---------------------------------------------------------------------------------------------------------------------------------------------------
-- Identify idle sessions with orphaned transacrtions
-- ---------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
	  es.session_id
	, es.login_time
	, es.last_request_start_time
	, es.last_request_end_time
	, es.host_name
	, es.login_name

FROM sys.dm_exec_sessions es

JOIN sys.dm_tran_session_transactions tst
ON   es.session_id = tst.session_id

LEFT JOIN sys.dm_exec_requests er
ON   tst.session_id = er.session_id

WHERE er.session_id IS NULL

ORDER BY es.session_id

