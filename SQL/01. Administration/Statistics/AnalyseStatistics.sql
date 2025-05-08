/************************************************************************************************************

Ref:

************************************************************************************************************/

-- 1. 
SELECT
    stats.NAME
    , stats.filter_definition
    , last_updated
    , ROWS
    , rows_sampled
    , steps
    , unfilteres_rows
    , modification_counter
FROM SYS.STATS AS stats
CROSS APPLY SYS.DM_DB_STATS_PROPIERTIES(stats.OBJECT_ID, stats.STATS_ID) AS SPACE

WHERE stats.OBJECT_ID = OBJECT_ID('Name')
ORDER BY last_updated


-- To update all statistics in a table
-- The following example updates the statistics for all indexes on the SalesOrderDetail table.
UPDATE STATISTICS Sales.SalesOrderDetail;   
GO  

-- To update all statistics in a database
-- The following example updates the statistics for all tables in the database.   
EXEC sp_updatestats; 

-- Update the statistics for an index
UPDATE STATISTICS Sales.SalesOrderDetail AK_SalesOrderDetail_rowguid;  
GO 

-- Update statistics by using 50 percent sampling
UPDATE STATISTICS Production.Product(Products)   
    WITH SAMPLE 50 PERCENT;  

-- Update statistics by using FULLSCAN and NORECOMPUTE
-- NORECOMPUTE
-- Disable the automatic statistics update option, AUTO_UPDATE_STATISTICS, for the specified statistics. If this option is specified, the query optimizer completes this statistics update and disables future updates.
-- To re-enable the AUTO_UPDATE_STATISTICS option behavior, run UPDATE STATISTICS again without the NORECOMPUTE option or run sp_autostats.

UPDATE STATISTICS Production.Product(Products)  
    WITH FULLSCAN, NORECOMPUTE;  
GO  

-- Update statistics by using a full scan
UPDATE STATISTICS Customer (CustomerStats1) WITH FULLSCAN;  


USE ExpressLane;
GO
 
IF Object_id('tempdb..#StatsInfo') IS NOT NULL
  DROP TABLE #statsinfo;
GO
 
IF Object_id('tempdb..#ColumnList') IS NOT NULL
  DROP TABLE #columnlist;
GO
 
DECLARE @object_id INT =NULL; 
 
--By default you get statistics status for whole database
--Uncomment below line if you are only looking at one table
--SET @object_id = OBJECT_ID(N'Sales.Invoices');
SELECT
  ss.[name] AS SchemaName,
  obj.[name] AS TableName,
  stat.[stats_id],
  stat.[name] AS StatisticsName,
  CASE
    WHEN stat.[auto_created] = 0
    AND stat.[user_created] = 0 THEN 'Index Statistic'
    WHEN stat.[auto_created] = 0
    AND stat.[user_created] = 1 THEN 'User Created'
    WHEN stat.[auto_created] = 1
    AND stat.[user_created] = 0  THEN 'Auto Created'
    WHEN stat.[auto_created] = 1
    AND stat.[user_created] = 1 THEN 'Updated stats available in Secondary'
  END AS StatisticType,
  CASE
    WHEN stat.[is_temporary] = 0 THEN 'Stats in DB'
    WHEN stat.[is_temporary] = 1 THEN 'Stats in Tempdb'
  END AS IsTemporary,
  CASE
    WHEN stat.[has_filter] = 1 THEN 'Filtered Index'
    WHEN stat.[has_filter] = 0 THEN 'No Filter'
  END AS IsFiltered,
  c.[name] AS ColumnName,
  stat.[filter_definition],
  sp.[last_updated],
  sp.[rows],
  sp.[rows_sampled],
  sp.[steps] AS HistorgramSteps,
  sp.[unfiltered_rows],
  sp.[modification_counter] AS RowsModified
INTO #statsinfo
FROM  
  sys.[objects] AS obj
  INNER JOIN sys.[schemas] ss
    ON obj.[schema_id] = ss.[schema_id]
  INNER JOIN sys.[stats] stat
    ON stat.[object_id] = obj.[object_id]
  JOIN sys.[stats_columns] sc
    ON sc.[object_id] = stat.[object_id]
    AND sc.[stats_id] = stat.[stats_id]
  JOIN sys.columns c
    ON c.[object_id] = sc.[object_id]
    AND c.[column_id] = sc.[column_id]
  CROSS apply sys.Dm_db_stats_properties(stat.object_id, stat.stats_id) AS sp
WHERE 
  ( obj.[is_ms_shipped] = 0
  AND obj.[object_id] = @object_id )
  OR ( obj.[is_ms_shipped] = 0 )
ORDER BY
  ss.[name],
  obj.[name],
  stat.[name]; 
 
SELECT
  t.[schemaname],
  t.[tablename],
  t.[stats_id],
  Stuff((SELECT ',' + s.[columnname]
FROM
  #statsinfo s
WHERE 
  s.[schemaname] = t.[schemaname]
  AND s.[tablename] = t.[tablename]
  AND s.stats_id = t.stats_id
FOR xml path('')), 1, 1, '') AS ColumnList
INTO   #columnlist
FROM   #statsinfo AS t
GROUP BY
  t.[schemaname],
  t.[tablename],
  t.[stats_id]; 
 
SELECT DISTINCT
  SI.[schemaname],
  SI.[tablename],
  SI.[stats_id],
  SI.[statisticsname],
  SI.[statistictype],
  SI.[istemporary],
  CL.[columnlist] AS ColumnName,
  SI.[isfiltered],
  SI.[filter_definition],
  SI.[last_updated],
  SI.[rows],
  SI.[rows_sampled],
  SI.[historgramsteps],
  SI.[unfiltered_rows],
  SI.[rowsmodified]
FROM  
  #statsinfo SI
  INNER JOIN #columnlist CL
  ON SI.[schemaname] = CL.[schemaname]
  AND SI.[tablename] = CL.[tablename]
  AND SI.[stats_id] = CL.[stats_id]
where SI.[tablename] IN ('Item', 'ItemMaster', 'Event', 'StoreEvent')
ORDER BY
  SI.[schemaname],
  SI.[tablename],
  SI.[statisticsname];
GO


-- Details About Statistics
-- Original Author: Pinal Dave 
SELECT DISTINCT

	--OBJECT_NAME(s.[object_id]) AS TableName,
	--c.name AS ColumnName,
	s.name AS StatName
	--s.auto_created,
	--s.user_created,
	--s.no_recompute,
	--s.[object_id],
	--s.stats_id,
	--sc.stats_column_id,
	--sc.column_id,
	--STATS_DATE(s.[object_id], s.stats_id) AS LastUpdated

FROM sys.stats s 

JOIN sys.stats_columns sc 
ON sc.[object_id] = s.[object_id] AND sc.stats_id = s.stats_id

JOIN sys.columns c 
ON c.[object_id] = sc.[object_id] AND c.column_id = sc.column_id

JOIN sys.partitions par ON par.[object_id] = s.[object_id]

JOIN sys.objects obj ON par.[object_id] = obj.[object_id]

WHERE 
	OBJECTPROPERTY(s.OBJECT_ID,'IsUserTable') = 1
-- AND (s.auto_created = 1 OR s.user_created = 1);

GROUP BY s.name

