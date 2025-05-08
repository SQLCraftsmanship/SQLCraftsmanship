
---------------------------------------------------------------------------------------------------------
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-missing-index-group-stats-transact-sql?view=sql-server-ver15
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-missing-index-groups-transact-sql?view=sql-server-ver15
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-missing-index-details-transact-sql?view=sql-server-ver15
---------------------------------------------------------------------------------------------------------

-- Missing Indexes in current database by Index Advantage
SELECT 
      user_seeks * avg_total_user_cost * ( avg_user_impact * 0.01 ) AS [index_advantage]
    , migs.last_user_seek
    , mid.[statement] AS [Database.Schema.Table]
    , mid.equality_columns
    , mid.inequality_columns
    , mid.included_columns
    , migs.unique_compiles
    , migs.user_seeks
    , migs.avg_total_user_cost
    , migs.avg_user_impact

FROM sys.dm_db_missing_index_group_stats AS migs WITH (NOLOCK)

JOIN sys.dm_db_missing_index_groups      AS mig  WITH (NOLOCK)
ON   migs.group_handle = mig.index_group_handle

JOIN sys.dm_db_missing_index_details     AS mid  WITH (NOLOCK)
ON   mig.index_handle = mid.index_handle

WHERE mid.database_id = DB_ID()
ORDER BY index_advantage DESC ;
