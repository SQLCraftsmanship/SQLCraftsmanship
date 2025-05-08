DECLARE @sql_handle VARBINARY(64)
SET @sql_handle = 0x03000700C5920F63689710010DAF000001000000000000000000000000000000000000000000000000000000
SELECT eqs.query_hash, qsp.query_plan_hash, eqs.last_compile_batch_sql_handle,
qsp.query_id, qsp.plan_id, *
FROM sys.query_store_query eqs INNER JOIN sys.query_store_plan qsp
ON eqs.query_id = qsp.query_id
WHERE eqs.last_compile_batch_sql_handle = @sql_handle
go

DECLARE @sql_handle VARBINARY(64)
SET @sql_handle = 0x020000007D541821B6E3758ACA6863DB63C6357C56DF93270000000000000000000000000000000000000000
SELECT eqs.query_hash, qsp.query_plan_hash, eqs.last_compile_batch_sql_handle,
qsp.query_id, qsp.plan_id, *
FROM sys.query_store_query eqs INNER JOIN sys.query_store_plan qsp
ON eqs.query_id = qsp.query_id
WHERE eqs.last_compile_batch_sql_handle = @sql_handle



