
-- That tell how many times it’s happened, and where the dump files live:
SELECT *
FROM sys.dm_server_memory_dumps AS dsmd
ORDER BY creation_time DESC;
