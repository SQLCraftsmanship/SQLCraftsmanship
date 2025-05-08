-----------------------------------------------------------------------------------------------------------------------------------------------
-- Get a count of SQL connections by IP addess
-----------------------------------------------------------------------------------------------------------------------------------------------
SELECT
      ec.client_net_address
    , es.[program_name]
    , es.[host_name]
    , es.login_name
    , COUNT(ec.session_id) AS [connection count]

FROM sys.dm_exec_sessions    AS es

JOIN sys.dm_exec_connections AS ec
ON   es.session_id = ec.session_id

GROUP BY 
      ec.client_net_address
    , es.[program_name]
    , es.[host_name]
    , es.login_name -- Esta se puede llegar a comentar. Analizar que pasa si la comento!!!

ORDER BY 
    ec.client_net_address
    , es.[program_name] ;

-----------------------------------------------------------------------------------------------------------------------------------------------
-- Who is connecte by SSMS
-- Libro II
-----------------------------------------------------------------------------------------------------------------------------------------------
SELECT
      ec.client_net_address
    , es.[host_name]
	, est.text

FROM sys.dm_exec_sessions    AS es

JOIN sys.dm_exec_connections AS ec
ON   es.session_id = ec.session_id

CROSS APPLY sys.dm_exec_sql_text(ec.most_recent_sql_handle) est

WHERE es.program_name LIKE 'Microsoft SQL Server Management Studio%'

ORDER BY 
    ec.client_net_address
  , es.[program_name];



-----------------------------------------------------------------------------------------------------------------------------------------------
-- Get Amount of SQL connections
-- To know how many users are connect to the instance
-----------------------------------------------------------------------------------------------------------------------------------------------
SELECT COUNT(*) FROM sys.dm_exec_connections

-----------------------------------------------------------------------------------------------------------------------------------------------
-- Get duration time of a connection
-- To detect long connection/s
-----------------------------------------------------------------------------------------------------------------------------------------------
SELECT
	  session_id
	, connection_id
	, connect_time
	, DATEDIFF(DAY   , GETDATE(), connect_time) AS 'Duration in Day'
	, DATEDIFF(HOUR  , GETDATE(), connect_time) AS 'Duration in Hour'
	, DATEDIFF(MINUTE, GETDATE(), connect_time) AS 'Duration in Minutes'
	, DATEDIFF(MINUTE, GETDATE(), last_read)	  AS 'AmountOfMinutesFromLastRead'
	, DATEDIFF(MINUTE, GETDATE(), last_write)	  AS 'AmountOfMinutesFromLastWrite'

FROM sys.dm_exec_connections


