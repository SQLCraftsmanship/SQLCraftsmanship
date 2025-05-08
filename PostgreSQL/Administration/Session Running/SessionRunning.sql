
SELECT
	datname
	, usename
	, pid
	, state
	, wait_event
	, current_timestamp - xact_start as xact_runtime
	, query
FROM pg_stat_activity
-- WHERE UPPER(query) LIKE '%vacuum%'
ORDER BY xact_start;
