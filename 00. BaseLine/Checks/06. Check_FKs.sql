
-- SP para chequear cuales son las tablas referenciadas por FK
EXEC sp_fkeys 'TableName'

-- You can also specify the schema:
EXEC sp_fkeys @pktable_name = 'TableName', @pktable_owner = 'dbo'
