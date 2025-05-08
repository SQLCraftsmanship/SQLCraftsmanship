
----------------------------------------------------------------------------------------------------------
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-fts-active-catalogs-transact-sql?view=sql-server-ver15
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-fts-index-population-transact-sql?view=sql-server-ver15
----------------------------------------------------------------------------------------------------------

-- -- Get population status for all FT catalogs in the current database
SELECT 
      c.name
    , c.[status]
    , c.status_description
    , OBJECT_NAME(p.table_id) AS [table_name]
    , p.population_type_description
    , p.is_clustered_index_scan
    , p.status_description
    , p.completion_type_description
    , p.queued_population_type_description
    , p.start_time
    , p.range_count

FROM sys.dm_fts_active_catalogs AS c
JOIN sys.dm_fts_index_population AS p
ON   c.database_id = p.database_id
AND  c.catalog_id  = p.catalog_id

WHERE c.database_id = DB_ID()
ORDER BY c.name;
