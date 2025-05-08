
--------------------------------------------------------------------------------------------------------
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/database-mirroring-sys-dm-db-mirroring-auto-page-repair?view=sql-server-ver15
--------------------------------------------------------------------------------------------------------

-- Check auto page repair history (New in SQL 2008)
-- This script tells you whether you have had any automatic page repair attempts with SQL Server database 
-- mirroring, along with the results of the attempt. I like to periodically run this query on my SQL Server
-- instances that have any mirrored databases to see if there have been any automatic page repair attempts 
-- since the instance was last restarted. Such attempts serve as an early warning sign of corruption 
-- issues that should be investigated further with DBCC CHECKDB.
SELECT 
      DB_NAME(database_id) AS [database_name]
    , database_id
    , file_id
    , page_id
    , error_type
    , page_status
    , modification_time
FROM sys.dm_db_mirroring_auto_page_repair;

