
/**********************************************************************************************************************************************************************
Gathering SQL Server indexes statistics and usage information

Ref:
    https://www.sqlshack.com/gathering-sql-server-indexes-statistics-and-usage-information/
    https://www.sqlshack.com/how-to-identify-and-monitor-unused-indexes-in-sql-server/

    https://www.red-gate.com/hub/product-learning/sql-monitor/when-sql-server-performance-goes-bad-rogue-indexes
    https://www.red-gate.com/hub/product-learning/sql-monitor/when-sql-server-performance-goes-bad-the-fill-factor-and-excessive-fragmentation?product=sql-monitor

MAP
    Catalog View 
        SYS.TABLES          (CV - Filestream_data_space_id + Lob_data_space_id)
        SYS.INDEXES         (CV - Data_space_id + Index_id + Object_id)
        SYS.INDEX_COLUMNS   (CV - Object_id + Column_id + Index_id)
        SYS.COLUMNS         (CV - Column_id + default_object_id + object_id + object_number + rule_object_id + system_type_id + user_type_id + xml_collection_id)
        SYS.OBJECTS         (CV - Object_id + Parent_object_id + Principal_id + Schema_id)
        SYS.STATS_COLUMNS   (CV - Stats_Id + Object_Id + Column_Id)
        SYS.STATS           (CV - Catalog View)

    DMV
        SYS.DM_DB_MISSING_INDEX_GROUP_STATS (DMV - Group_Handle)
        SYS.DM_DB_MISSING_INDEX_GROUPS      (DMV - Index_Handle + Index_Group_Handle)
        SYS.DM_DB_MISSING_INDEX_DETAILS     (DMV - Index_Handle)
        SYS.DM_DB_INDEX_USAGE_STATS         (DMV - Object_Id + Database_Id + Index_Id)
        SYS.DM_DB_PARTITION_STATS           (DMV - Index_Id + Object_Id + Partition_Number)

    DMF
        SYS.DM_DB_MISSING_INDEX_COLUMNS     (DMF - @Handle)
        SYS.DM_DB_INDEX_PHYSICAL_STATS      (DMF - Index_ID + Object_Id + Partition_Number)
        SYS.DM_DB_INDEX_OPERATIONAL_STATS   (DMF - Index_ID + Object_ID + Partition_number)

    SP
        sp_helpindex 
**********************************************************************************************************************************************************************/

-- 1. Index structure information
sp_helpindex '[dbo].[Name]'
GO

-- 2. Index brief
-- We can add more information to this query like:
--    Tab.name  Table_Name 
--    ,IX.name  Index_Name
--    ,IX.type_desc Index_Type
--    ,Col.name  Index_Column_Name
--    ,IXC.is_included_column Is_Included_Column
--    ,IX.fill_factor 
--    ,IX.is_disabled
--    ,IX.is_primary_key
--    ,IX.is_unique

SELECT  
     Tab.name  Table_Name 
    ,IX.name  Index_Name
    ,IX.type_desc Index_Type
    ,Col.name  Index_Column_Name
    ,IXC.is_included_column Is_Included_Column

FROM  SYS.INDEXES IX 
JOIN  SYS.INDEX_COLUMNS IXC  
ON    IX.object_id   =   IXC.object_id 
AND   IX.index_id  =  IXC.index_id  
JOIN  SYS.COLUMNS Col   
ON    IX.object_id   =   Col.object_id  
AND   IXC.column_id  =   Col.column_id     
JOIN  SYS.TABLES Tab      
ON   IX.object_id = Tab.object_id
-- WHERE Tab.name = 'TableName'


-- 3. Index fragmentation information
SELECT  
    OBJECT_NAME(IDX.OBJECT_ID) AS Table_Name, 
    IDX.name AS Index_Name, 
    IDXPS.index_type_desc AS Index_Type, 
    IDXPS.avg_fragmentation_in_percent  Fragmentation_Percentage
FROM SYS.DM_DB_INDEX_PHYSICAL_STATS(DB_ID(), NULL, NULL, NULL, NULL) IDXPS 
JOIN SYS.INDEXES IDX  ON IDX.object_id = IDXPS.object_id 
AND  IDX.index_id = IDXPS.index_id 
WHERE OBJECT_NAME(IDX.OBJECT_ID) = 'Users' 
ORDER BY Fragmentation_Percentage DESC

-- 4. Index usage information

/*************************************************************************************************************
This result can be analyzed as follows:

All zero values mean that the table is not used, or the SQL Server service restarted recently. An index 
with zero or small number of seeks, scans or lookups and large number of updates is a useless index and 
should be removed, after verifying with the system owner, as the main purpose of adding the index is 
speeding up the read operations.

An index that is scanned heavily with zero or small number of seeks means that the index is badly used and 
should be replaced with more optimal one.

An index with large number of Lookups means that we need to optimize the index by adding the frequently 
looked up columns to the existing index non-key columns using the INCLUDE clause.

A table with a very large number of Scans indicates that SELECT * queries are heavily used, retrieving
more columns than what is required, or the index statistics should be updated.

A Clustered index with large number of Scans means that a new Non-clustered index should be created to 
cover a non-covered query.

Dates with NULL values mean that this action has not occurred yet. 

Large scans are OK in small tables.

Your index is not here, then no action is performed on that index yet.
*************************************************************************************************************/
SELECT 
      OBJECT_NAME(IX.OBJECT_ID) Table_Name
    , IX.name AS Index_Name
    , IX.type_desc Index_Type
    , SUM(PS.[used_page_count]) * 8 IndexSizeKB
    , IXUS.user_seeks AS NumOfSeeks
    , IXUS.user_scans AS NumOfScans
    , IXUS.user_lookups AS NumOfLookups
    , IXUS.user_updates AS NumOfUpdates
    , IXUS.last_user_seek AS LastSeek
    , IXUS.last_user_scan AS LastScan
    , IXUS.last_user_lookup AS LastLookup
    , IXUS.last_user_update AS LastUpdate
FROM SYS.INDEXES IX
JOIN SYS.TABLES TAB
ON	 TAB.object_id = IX.object_id
JOIN SYS.SCHEMAS SCH
ON	 SCH.schema_id = TAB.schema_id
JOIN SYS.DM_DB_INDEX_USAGE_STATS IXUS 
ON   IXUS.index_id = IX.index_id AND IXUS.OBJECT_ID = IX.OBJECT_ID
JOIN SYS.DM_DB_PARTITION_STATS PS 
ON   PS.object_id = IX.object_id
WHERE 
	OBJECTPROPERTY(IX.OBJECT_ID,'IsUserTable') = 1
AND OBJECT_NAME(IX.OBJECT_ID) = 'Claim'
AND SCH.Name = 'dbo'
GROUP BY OBJECT_NAME(IX.OBJECT_ID) ,IX.name ,IX.type_desc ,IXUS.user_seeks ,IXUS.user_scans ,IXUS.user_lookups,IXUS.user_updates 
	,IXUS.last_user_seek ,IXUS.last_user_scan ,IXUS.last_user_lookup,IXUS.last_user_update


-- 5. Index information about INSERT - UPDATE and DELETE
SELECT 
    OBJECT_NAME(IXOS.OBJECT_ID)  Table_Name 
    ,IX.name  Index_Name
    ,IX.type_desc Index_Type
    ,SUM(PS.[used_page_count]) * 8 IndexSizeKB
    ,IXOS.LEAF_INSERT_COUNT NumOfInserts
    ,IXOS.LEAF_UPDATE_COUNT NumOfupdates
    ,IXOS.LEAF_DELETE_COUNT NumOfDeletes
	   
FROM   SYS.DM_DB_INDEX_OPERATIONAL_STATS (NULL,NULL,NULL,NULL ) IXOS 
JOIN SYS.INDEXES AS IX ON IX.OBJECT_ID = IXOS.OBJECT_ID AND IX.INDEX_ID =    IXOS.INDEX_ID 
JOIN SYS.DM_DB_PARTITION_STATS PS on PS.object_id=IX.object_id
WHERE  OBJECTPROPERTY(IX.[OBJECT_ID],'IsUserTable') = 1
GROUP BY OBJECT_NAME(IXOS.OBJECT_ID), IX.name, IX.type_desc,IXOS.LEAF_INSERT_COUNT, IXOS.LEAF_UPDATE_COUNT,IXOS.LEAF_DELETE_COUNT


-- 5. Finding unused indexes
SELECT
    objects.name AS Table_name,
    indexes.name AS Index_name,
    dm_db_index_usage_stats.user_seeks,
    dm_db_index_usage_stats.user_scans,
    dm_db_index_usage_stats.user_updates
FROM SYS.DM_DB_INDEX_USAGE_STATS
JOIN SYS.OBJECTS 
ON   DM_DB_INDEX_USAGE_STATS.OBJECT_ID = OBJECTS.OBJECT_ID
JOIN SYS.INDEXES 
ON   INDEXES.index_id = DM_DB_INDEX_USAGE_STATS.index_id 
AND  DM_DB_INDEX_USAGE_STATS.OBJECT_ID = INDEXES.OBJECT_ID
WHERE
    DM_DB_INDEX_USAGE_STATS.user_lookups = 0
AND DM_DB_INDEX_USAGE_STATS.user_seeks   = 0
AND DM_DB_INDEX_USAGE_STATS.user_scans   = 0
-- AND objects.name = 'TABLENAME'
ORDER BY  DM_DB_INDEX_USAGE_STATS.user_updates DESC

-- 6. Finding unused indexes excluding PK and UQ constraint
SELECT
    objects.name AS Table_name,
    indexes.name AS Index_name,
    dm_db_index_usage_stats.user_seeks,
    dm_db_index_usage_stats.user_scans,
    dm_db_index_usage_stats.user_updates
FROM sys.dm_db_index_usage_stats
JOIN sys.objects 
ON   dm_db_index_usage_stats.OBJECT_ID = objects.OBJECT_ID
JOIN sys.indexes 
ON   indexes.index_id = dm_db_index_usage_stats.index_id 
AND  dm_db_index_usage_stats.OBJECT_ID = indexes.OBJECT_ID
WHERE
    indexes.is_primary_key = 0 -- This condition excludes primary key constarint
AND indexes. is_unique = 0 -- This condition excludes unique key constarint
AND dm_db_index_usage_stats. user_lookups = 0
AND dm_db_index_usage_stats.user_seeks = 0
AND dm_db_index_usage_stats.user_scans = 0
ORDER BY   dm_db_index_usage_stats.user_updates DESC

-- 7. Finding unused indexes excluding PK, UQ constraint and IX which SQL Server hasn't done any work with
SELECT
    objects.name AS Table_name,
    indexes.name AS Index_name,
    dm_db_index_usage_stats.user_seeks,
    dm_db_index_usage_stats.user_scans,
    dm_db_index_usage_stats.user_updates
FROM sys.dm_db_index_usage_stats
JOIN sys.objects 
ON   dm_db_index_usage_stats.OBJECT_ID = objects.OBJECT_ID
JOIN sys.indexes 
ON   indexes.index_id = dm_db_index_usage_stats.index_id 
AND  dm_db_index_usage_stats.OBJECT_ID = indexes.OBJECT_ID
WHERE indexes.is_primary_key = 0 --This line excludes primary key constarint
AND   indexes. is_unique = 0 --This line excludes unique key constarint
AND   dm_db_index_usage_stats.user_updates <> 0 -- This line excludes indexes SQL Server hasn’t done any work with
AND   dm_db_index_usage_stats. user_lookups = 0
AND   dm_db_index_usage_stats.user_seeks = 0
AND   dm_db_index_usage_stats.user_scans = 0
ORDER BY dm_db_index_usage_stats.user_updates DESC


-- 8. Which unused indexes should not be removed?
SELECT 
    'DROP INDEX ' + OBJECT_NAME(DM_DB_INDEX_USAGE_STATS.object_id) + '.' + INDEXES.name AS Drop_Index
    , user_seeks
    , user_scans
    , user_lookups
    , user_updates

FROM SYS.DM_DB_INDEX_USAGE_STATS
JOIN SYS.OBJECTS 
ON   DM_DB_INDEX_USAGE_STATS.OBJECT_ID = OBJECTS.OBJECT_ID
JOIN SYS.INDEXES 
ON   INDEXES.index_id = DM_DB_INDEX_USAGE_STATS.index_id 
AND  DM_DB_INDEX_USAGE_STATS.OBJECT_ID = INDEXES.OBJECT_ID

WHERE 
      INDEXES.is_primary_key                = 0 -- This line excludes primary key constarint
AND   INDEXES.is_unique                     = 0 -- This line excludes unique key constarint
AND   DM_DB_INDEX_USAGE_STATS.user_updates <> 0 -- This line excludes indexes SQL Server hasn’t done any work with
AND   DM_DB_INDEX_USAGE_STATS.user_lookups  = 0
AND   DM_DB_INDEX_USAGE_STATS.user_seeks    = 0
AND   DM_DB_INDEX_USAGE_STATS.user_scans    = 0

ORDER BY DM_DB_INDEX_USAGE_STATS.user_updates DESC



-- 9. Drilling into missing index details
-- Index strategies aren’t always obvious. Before you go ahead and create any new index, you need to be certain of its net benefit for the workload as a whole, and also sure that you could 
-- not satisfy the “missing index” request with a simple modification to an existing index. If you fail to do this, you’ll inevitably, over time, end up with many indexes that are almost 
-- the same, but with subtly different index key column definitions and column orders, or included column definitions and orders.

-- We can see the current warnings of missing indexes, and the indexes that are suggested, with this query:
-- WARNING: This is only an estimate, and the Query Processor is making this recommendation  based solely upon analysis of specific queries. It has not considered the resulting index size, 
-- or its workload-wide Impact, including its impact on INSERT, UPDATE, DELETE performance. These factors should be taken into account before creating these indexes.

SELECT  
    DB_NAME(mid.database_id) 
    + '.' 
    + OBJECT_SCHEMA_NAME(mid.object_id, mid.database_id) 
    + '.'
    + OBJECT_NAME(mid.object_id, mid.database_id) AS [TheTable]
    
    , migs.user_seeks         AS [Index Uses (est)]        -- Number of seeks caused by user queries that the recommended IX in the group could have been used for.
    , migs.avg_user_impact    AS [Benefit % (est,Percent)] -- Average percentage benefit that user queries could experience if this missing IX group was implemented. 
                                                           -- The value means that the query cost would on average drop by this percentage if this missing IX group was implemented.
    , CONVERT(NUMERIC(5,2),migs.avg_total_user_cost) [Avg Query Cost (est)] -- Average cost of the user queries that could be reduced by the IX in the group.
    , migs.unique_compiles                                                  -- Number of compilations and recompilations that would benefit from this missing IX group. 
                                                                            -- Compilations and recompilations of many different queries can contribute to this column value.
    , CONVERT(CHAR(20),migs.last_user_seek,113) AS [last user seek]
    , 'CREATE INDEX [IX_' + OBJECT_NAME(mid.object_id, mid.database_id) 
      + '_'
      + REPLACE(REPLACE(REPLACE(ISNULL(mid.equality_columns, ''), ', ', '_'), '[', ''), ']', '')
      + CASE 
            WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN '_'
        ELSE '' END 
      + REPLACE(REPLACE(REPLACE(ISNULL(mid.inequality_columns, ''), ', ', '_'), '[', ''), ']', '') + ']'
      + ' ON ' + mid.statement + ' (' + ISNULL(mid.equality_columns, '')
      + CASE
           WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ','
        ELSE ''
        END 
      + ISNULL(mid.inequality_columns, '') 
      + ')'
      + ISNULL(' INCLUDE (' + mid.included_columns
      + ') WITH (MAXDOP =?, FILLFACTOR=?, ONLINE=?, SORT_IN_TEMPDB=?);',
      '') AS [TSQL to create index]

FROM SYS.DM_DB_MISSING_INDEX_GROUP_STATS    AS migs
JOIN SYS.DM_DB_MISSING_INDEX_GROUPS         AS mig
ON   migs.group_handle = mig.index_group_handle
JOIN SYS.DM_DB_MISSING_INDEX_DETAILS        AS mid
ON   mig.index_handle = mid.index_handle

ORDER BY [Index Uses (est)] DESC


-- 10. Duplicate indexes
-- If you have more than one statistic for the same column or set of columns, it means that they are used 
-- in more than one index. You’ll find these just by comparing the list of columns that 
-- each statistic is associated with. This technique eliminates the XML columns conveniently.
SELECT 
    OBJECT_SCHEMA_NAME(Object_ID) + '.' + OBJECT_NAME(Object_ID) AS TableName
    , COUNT(*)      AS Similar
    , ColumnList    AS TheColumn
    , MAX(Name) + ', ' + MIN(Name) AS Duplicates

FROM 
   ( SELECT 
        Object_ID
        , Name
        , STUFF (-- Get a list of columns
                    (SELECT 
                            ', ' 
                            + COL_NAME(sc.Object_Id, sc.Column_Id)
                     FROM  SYS.STATS_COLUMNS sc
                     WHERE sc.Object_ID = s.Object_ID
                     AND   sc.stats_ID  = s.stats_ID
                     ORDER BY stats_column_ID ASC
                     FOR XML PATH(''), TYPE).value('.', 'varchar(max)'), 1, 2, ''
                ) AS ColumnList
   FROM SYS.STATS s) f

WHERE OBJECTPROPERTYEX(f.object_id, N'IsUserTable') <> 0
GROUP BY Object_ID,ColumnList 
HAVING COUNT(*) > 1



/*********************************************************************************************************************************************************************************************
ANEXO
*********************************************************************************************************************************************************************************************/

-- List table indexes in SQL Server database
-- Columns Details:
-- table_view   - name of table or view index is defined for
-- object_type  - type of object that index is defined for: Table / View
-- index_id     - id of index (unique in table)
-- type         - Primary key / Unique / Not unique / index_name - index name
-- columns      - list of index columns separated with ","
-- index_type   - index type: Clustered IX / Nonclustered unique IX / XML IX / Spatial IX / Clustered columnstore IX / Nonclustered columnstore IX / Nonclustered hash IX
-- Rows         - One row represents represents index
--              - Scope of rows: all indexes (unique and non unique) in databases
--              - Ordered by schema, table name, index id
SELECT 
      SCHEMA_NAME(T.SCHEMA_ID) + '.' + t.[name] AS Tableview
    , CASE 
        WHEN t.[type] = 'U' THEN 'Table'
        when t.[type] = 'V' THEN 'View'
      END AS [object_type]
    , i.index_id
    , CASE 
        WHEN i.is_primary_key = 1 THEN 'Primary key'
        WHEN i.is_unique      = 1 THEN 'Unique'
      ELSE 'Not unique' 
      END AS [type]
    , i.[name] AS index_name
    , SUBSTRING(column_names, 1, LEN(column_names)-1) AS [columns]
    , CASE 
        WHEN i.[type] = 1 THEN 'Clustered index'
        WHEN i.[type] = 2 THEN 'Nonclustered unique index'
        WHEN i.[type] = 3 THEN 'XML index'
        WHEN i.[type] = 4 THEN 'Spatial index'
        WHEN i.[type] = 5 THEN 'Clustered columnstore index'
        WHEN i.[type] = 6 THEN 'Nonclustered columnstore index'
        WHEN i.[type] = 7 THEN 'Nonclustered hash index'
      END AS index_type
FROM SYS.OBJECTS T
JOIN SYS.INDEXES I
ON   T.Object_id = I.Object_id

CROSS APPLY (SELECT 
                col.[name] + ', '
             FROM SYS.INDEX_COLUMNS IC
             JOIN SYS.COLUMNS col
             ON   ic.object_id = col.object_id
             AND  ic.column_id = col.column_id
             WHERE ic.object_id = t.object_id
             AND   ic.index_id = i.index_id
             ORDER BY col.column_id
             FOR XML PATH ('') ) D (column_names)
WHERE 
    t.is_ms_shipped <> 1
AND index_id > 0
ORDER BY SCHEMA_NAME(T.Schema_id) + '.' + T.[Name], I.Index_id
