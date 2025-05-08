
--------------------------------------------------------------------------------------------------------
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-cached-plans-transact-sql?view=sql-server-ver15
--------------------------------------------------------------------------------------------------------

-- Use Counts and # of plans for compiled plans
-- Mejorar esta query porque no me dice nada
SELECT
      objtype
    , usecounts -- Number of times the cache object has been looked up.
    , COUNT(*) AS [no_of_plans]
FROM sys.dm_exec_cached_plans
WHERE cacheobjtype = 'Compiled Plan'
GROUP BY objtype, usecounts
ORDER BY objtype, usecounts 

-- Returning query plans for all cached triggers
SELECT
      plan_handle
    , query_plan
    , objtype   
FROM sys.dm_exec_cached_plans   
CROSS APPLY sys.dm_exec_query_plan(plan_handle)   
WHERE objtype ='Trigger';  
GO  

  -- Book II Page 85
  -- Listing 3.6: Retrieving the plans for compiled objects
  SELECT
    refcounts ,
    usecounts ,
    size_in_bytes ,
    cacheobjtype ,
    objtype
  FROM sys.dm_exec_cached_plans
  WHERE objtype IN ( 'proc', 'prepared' ) ;

  -- Book II Page 92
  -- Listing 3.7: Total number of cached plans.
  SELECT COUNT(*)
  FROM sys.dm_exec_cached_plans ;


-- Returning the SET options with which the plan was compiled
-- No esta buena porque hay que sumarle la descripcion para la columna [set_options]
SELECT 
      plan_handle
    , pvt.set_options
    , pvt.sql_handle  
FROM (  
      SELECT 
          plan_handle
        , epa.attribute
        , epa.value   
      FROM sys.dm_exec_cached_plans   
      OUTER APPLY sys.dm_exec_plan_attributes(plan_handle) AS epa  
      WHERE cacheobjtype = 'Compiled Plan'  
      ) AS ecpa   
PIVOT (MAX(ecpa.value) FOR ecpa.attribute IN ("set_options", "sql_handle")) AS pvt;  
GO  

-- Returning the memory breakdown of all cached compiled plans
-- Devolver el desglose de la memoria de todos los planes compilados en caché
-- Compleja y muy puntual. Es util cuando buscamos el tamaño de un Plan en Memoria
SELECT 
      plan_handle
    , ecp.memory_object_address AS CompiledPlan_MemoryObject
    , omo.memory_object_address
    , type
    , page_size_in_bytes   
FROM sys.dm_exec_cached_plans AS ecp   
JOIN sys.dm_os_memory_objects AS omo   
ON   ecp.memory_object_address = omo.memory_object_address   
OR   ecp.memory_object_address = omo.parent_address  
WHERE cacheobjtype = 'Compiled Plan';  
GO  


-- Find single-use, ad-hoc queries that are bloating the plan cache
SELECT TOP (100)
      [text]
    , cp.size_in_bytes
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(plan_handle)

WHERE cp.cacheobjtype = 'Compiled Plan'
AND   cp.objtype   = 'Adhoc'
AND   cp.usecounts = 1
ORDER BY cp.size_in_bytes DESC ;

-- Book II Page 80
-- Returning the plan using sys.dm_exec_query_plan
-- First we create an Example then check que plan in cache
CREATE PROCEDURE ShowQueryText
AS 
BEGIN
  SELECT TOP 10
    object_id ,
    name
  FROM sys.objects ;
  --waitfor delay '00:00:00'81

  SELECT TOP 10
    object_id ,
    name
  FROM sys.objects ;
  
  SELECT TOP 10
    object_id ,
    name
  FROM sys.procedures ;
  GO
END;

-- Command to exec SP
EXEC dbo.ShowQueryText ;
GO

-- Return the plan for the SP
SELECT 
  deqp.dbid ,
  deqp.objectid ,
  deqp.encrypted ,
  deqp.query_plan
FROM sys.dm_exec_query_stats deqs
CROSS APPLY sys.dm_exec_query_plan(deqs.plan_handle) AS deqp
WHERE objectid = OBJECT_ID('ShowQueryText', 'p') ;

-- Book II Page 83 
-- Listing 3.3: Viewing the sql_handle and plan_handle
SELECT
  deqs.plan_handle ,
  deqs.sql_handle ,
  execText.text
FROM sys.dm_exec_query_stats deqs
CROSS APPLY sys.dm_exec_sql_text(deqs.plan_handle) AS execText
WHERE execText.text LIKE 'CREATE PROCEDURE ShowQueryText%'


-- Book II Page 85
-- Listing 3.5: Returning the plan using sys.dm_exec_text_query_plan
SELECT 
  deqp.dbid ,
  deqp.objectid ,
  CAST(detqp.query_plan AS XML) AS singleStatementPlan ,
  deqp.query_plan AS batch_query_plan ,

  --this won't actually work in all cases because nominal plans aren't
  -- cached, so you won't see a plan for waitfor if you uncomment it
  ROW_NUMBER() OVER ( ORDER BY Statement_Start_offset ) AS query_position ,
  CASE 
    WHEN deqs.statement_start_offset = 0 AND deqs.statement_end_offset = -1
      THEN '-- see objectText column--'
    ELSE '-- query --' 
        + CHAR(13) + CHAR(10)
        + SUBSTRING(execText.text, deqs.statement_start_offset / 2,
        ((CASE 
            WHEN deqs.statement_end_offset = -1
              THEN DATALENGTH(execText.text)
          ELSE deqs.statement_end_offset 
          END) - deqs.statement_start_offset ) / 2) END AS queryText
FROM sys.dm_exec_query_stats deqs
CROSS APPLY sys.dm_exec_text_query_plan(deqs.plan_handle, deqs.statement_start_offset,  deqs.statement_end_offset) AS detqp
CROSS APPLY sys.dm_exec_query_plan(deqs.plan_handle) AS deqp
CROSS APPLY sys.dm_exec_sql_text(deqs.plan_handle) AS execText
WHERE deqp.objectid = OBJECT_ID('ShowQueryText', 'p') ;


-- Book II Page 92
-- An overview of plan reuse
SELECT 
	MAX(CASE 
			WHEN usecounts BETWEEN 10   AND 100   THEN '10-100'
			WHEN usecounts BETWEEN 101  AND 1000  THEN '101-1000'
			WHEN usecounts BETWEEN 1001 AND 5000  THEN '1001-5000'
			WHEN usecounts BETWEEN 5001 AND 10000 THEN '5001-10000'
		 ELSE CAST(usecounts AS VARCHAR(100)) END) AS usecounts
	, COUNT(*) AS countInstance

FROM sys.dm_exec_cached_plans
GROUP BY 
	CASE 
		WHEN usecounts BETWEEN 10	AND 100		THEN 50
		WHEN usecounts BETWEEN 101	AND 1000	THEN 500
		WHEN usecounts BETWEEN 1001 AND 5000	THEN 2500
		WHEN usecounts BETWEEN 5001 AND 10000	THEN 7500
	ELSE usecounts
END
ORDER BY 
	CASE 
		WHEN usecounts BETWEEN 10	AND 100		THEN 50
		WHEN usecounts BETWEEN 101	AND 1000	THEN 500
		WHEN usecounts BETWEEN 1001 AND 5000	THEN 2500
		WHEN usecounts BETWEEN 5001 AND 10000	THEN 7500
	ELSE usecounts
END DESC ;

-- Book II Page 94
-- Examining frequently used plans
SELECT TOP 2 WITH TIES
	decp.usecounts ,
	decp.cacheobjtype ,
	decp.objtype ,
	deqp.query_plan ,
	dest.text
FROM sys.dm_exec_cached_plans decp
CROSS APPLY sys.dm_exec_query_plan(decp.plan_handle) AS deqp
CROSS APPLY sys.dm_exec_sql_text(decp.plan_handle) AS dest
ORDER BY usecounts DESC ;

-- Book II Page 95
-- Listing 3.10: Examining plan reuse for a single procedure.
SELECT 
	usecounts ,
	cacheobjtype ,
	objtype ,
	OBJECT_NAME(dest.objectid)
FROM sys.dm_exec_cached_plans decp
CROSS APPLY sys.dm_exec_sql_text(decp.plan_handle) AS dest

WHERE 
	dest.objectid = OBJECT_ID('<procedureName>')
AND dest.dbid = DB_ID()

ORDER BY usecounts DESC ;

-- Book II Page 96
-- Find single-use, ad hoc queries that are bloating the plan cache
SELECT TOP ( 100 )
	[text] ,
	cp.size_in_bytes
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(plan_handle)
WHERE cp.cacheobjtype = 'Compiled Plan'
AND cp.objtype = 'Adhoc'
AND cp.usecounts = 1
ORDER BY cp.size_in_bytes DESC ;


-- Book II Page 96
-- Listing 3.12: Non-parameterized ad hoc SQL
-- Query 1
SELECT FirstName ,
 LastName
FROM dbo.Employee
WHERE EmpID = 5
-- Query 2
SELECT FirstName ,
 LastName
FROM dbo.Employee
WHERE EmpID = 187


-- Book II Page 99
-- Listing 3.13: Examining plan attributes.
SELECT 
  CAST(depa.attribute AS VARCHAR(30)) AS attribute ,
  CAST(depa.value AS VARCHAR(30)) AS value ,
  depa.is_cache_key
FROM (	SELECT TOP 1	*
    FROM sys.dm_exec_cached_plans
    ORDER BY usecounts DESC
  ) decp
OUTER APPLY sys.dm_exec_plan_attributes(decp.plan_handle) depa
WHERE is_cache_key = 1
ORDER BY usecounts DESC ;


-- Book II Page 104
-- Listing 3.14: Finding the CPU-intensive queries.
SELECT TOP 3
	total_worker_time ,
	execution_count ,
	total_worker_time / execution_count AS [Avg CPU Time] ,
	CASE 
		WHEN deqs.statement_start_offset = 0 AND deqs.statement_end_offset = -1
			THEN '-- see objectText column--'
			ELSE '-- query --' 
				+ CHAR(13) + CHAR(10)
			    + SUBSTRING(execText.text, deqs.statement_start_offset / 2,
							((CASE 
								WHEN deqs.statement_end_offset = -1
							      THEN DATALENGTH(execText.text)
							  ELSE deqs.statement_end_offset
						      END ) - deqs.statement_start_offset ) / 2) END AS queryText
FROM sys.dm_exec_query_stats deqs
CROSS APPLY sys.dm_exec_sql_text(deqs.plan_handle) AS execText
ORDER BY deqs.total_worker_time DESC ;


-- Book II Page 107
-- Listing 3.15: Grouping by sql_handle to see query stats at the batch level.
SELECT TOP 100
	SUM(total_logical_reads) AS total_logical_reads ,
	COUNT(*) AS num_queries , --number of individual queries in batch
	--not all usages need be equivalent, in the case of looping
	--or branching code
	MAX(execution_count) AS execution_count ,
	MAX(execText.text) AS queryText
FROM sys.dm_exec_query_stats deqs
CROSS APPLY sys.dm_exec_sql_text(deqs.sql_handle) AS execText
GROUP BY deqs.sql_handle
HAVING AVG(total_logical_reads / execution_count) <> SUM(total_logical_reads) / SUM(execution_count)
ORDER BY 1 DESC


-- Book II Page 108
-- Listing 3.16: Investigating logical reads performed by cached stored procedures
-- Top Cached SPs By Total Logical Reads (SQL 2008 only).
-- Logical reads relate to memory pressure
SELECT TOP ( 25 )
	p.name AS [SP Name] ,
	deps.total_logical_reads AS [TotalLogicalReads] ,
	deps.total_logical_reads / deps.execution_count AS [AvgLogicalReads] ,
	deps.execution_count ,
	ISNULL(deps.execution_count / DATEDIFF(Second, deps.cached_time,
	GETDATE()), 0) AS [Calls/Second] ,
	deps.total_elapsed_time ,
	deps.total_elapsed_time / deps.execution_count AS [avg_elapsed_time] ,
	deps.cached_time
FROM sys.procedures AS p
JOIN sys.dm_exec_procedure_stats
AS deps ON p.[object_id] = deps.[object_id]
WHERE deps.database_id = DB_ID()
ORDER BY deps.total_logical_reads DESC ;


-- Book II Page 111
-- Listing 3.17: Examine optimizer counters
SELECT 
	counter ,
	occurrence ,
	value
FROM sys.dm_exec_query_optimizer_info
WHERE counter IN ( 'optimizations', 'elapsed time', 'final cost' ) ;

