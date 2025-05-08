
-- I love this query. I think it shows the entire execution plan in real time:

SELECT session_id,
sp.cmd,
sp.hostname,
db.name,
sp.last_batch,
node_id,
physical_operator_name,
SUM(row_count) row_count,
SUM(estimate_row_count) AS estimate_row_count,
CAST(SUM(row_count)*100 AS float)/SUM(estimate_row_count) as EST_COMPLETE_PERCENT
FROM sys.dm_exec_query_profiles eqp
join sys.sysprocesses sp on sp.spid=eqp.session_id
join sys.databases db on db.database_id=sp.dbid
WHERE session_id = 166--in (select spid from sys.sysprocesses sp where sp.cmd like '%INDEX%')
GROUP BY session_id, node_id, physical_operator_name, sp.cmd, sp.hostname, db.name, sp.last_batch
ORDER BY session_id, node_id desc;

-------------------------------------------------------------------------

SELECT
	  Execquery.last_execution_time
	, ExecSQL.text as [Script]
	, *
FROM
	SYS.DM_EXEC_QUERY_STATS AS Execquery
CROSS APPLY SYS.DM_EXEC_SQL_TEXT(Execquery.sql_handle) AS ExecSQL
WHERE
	Execquery.last_worker_time > 6 * 1000 * 1000
ORDER BY Execquery.last_worker_time DESC


SELECT * FROM SYS.QUERY_STORE_RUNTIME_STATS
