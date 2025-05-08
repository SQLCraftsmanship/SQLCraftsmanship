
Last time I used this command to check the status of index creation
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
WHERE session_id in (select spid from sys.sysprocesses sp where sp.cmd like '%INDEX%')
GROUP BY session_id, node_id, physical_operator_name, sp.cmd, sp.hostname, db.name, sp.last_batch
ORDER BY session_id, node_id desc;

-----------------------------------------------------------------------------------------------------

;WITH agg AS
(
     SELECT SUM(qp.[row_count]) AS [RowsProcessed],
            SUM(qp.[estimate_row_count]) AS [TotalRows],
            MAX(qp.last_active_time) - MIN(qp.first_active_time) AS [ElapsedMS],
            MAX(IIF(qp.[close_time] = 0 AND qp.[first_row_time] > 0,
                    [physical_operator_name],
                    N'<Transition>')) AS [CurrentStep]
     FROM sys.dm_exec_query_profiles qp
     WHERE qp.[physical_operator_name] IN (N'Table Scan', N'Clustered Index Scan',
                                           N'Index Scan',  N'Sort')
     AND   qp.[session_id] IN (SELECT session_id from sys.dm_exec_requests where command IN ( 'CREATE INDEX','ALTER INDEX','ALTER TABLE') )
), comp AS
(
     SELECT *,
            ([TotalRows] - [RowsProcessed]) AS [RowsLeft],
            ([ElapsedMS] / 1000.0) AS [ElapsedSeconds]
     FROM   agg
)
SELECT [CurrentStep],
       [TotalRows],
       [RowsProcessed],
       [RowsLeft],
       CONVERT(DECIMAL(5, 2),
               (([RowsProcessed] * 1.0) / [TotalRows]) * 100) AS [PercentComplete],
       [ElapsedSeconds],
       (([ElapsedSeconds] / [RowsProcessed]) * [RowsLeft]) AS [EstimatedSecondsLeft],
       DATEADD(SECOND,
               (([ElapsedSeconds] / [RowsProcessed]) * [RowsLeft]),
               GETDATE()) AS [EstimatedCompletionTime]
FROM   comp;

