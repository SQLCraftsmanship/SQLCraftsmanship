
--------------------------------------------------------------------------------------------------------
-- 
--------------------------------------------------------------------------------------------------------

-- Look at pending I/O requests by file
-- The last two columns in the query return the cumulative number of read and writes for the file since 
-- SQL Server was started (or since the file was created, whichever was shorter). This information is 
-- helpful when trying to decide which RAID level to use for a particular drive letter. For example, 
-- files with more write activity will usually perform better on a RAID 10 LUN than they will on a 
-- RAID 5 LUN. 

SELECT 
      DB_NAME(mf.database_id) AS [Database]
    , mf.physical_name
    , r.io_pending
    , r.io_pending_ms_ticks
    , r.io_type
    , fs.num_of_reads
    , fs.num_of_writes

FROM sys.dm_io_pending_io_requests AS r

JOIN sys.dm_io_virtual_file_stats(NULL, NULL) AS fs
ON   r.io_handle = fs.file_handle

JOIN sys.master_files AS mf 
ON  fs.database_id = mf.database_id
AND fs.file_id = mf.file_id

ORDER BY r.io_pending, r.io_pending_ms_ticks DESC ;
