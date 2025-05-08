-- Determine if a table is partitioned
SELECT 
	  SCHEMA_NAME(t.schema_id) AS SchemaName, *   
	, t.Name
	, t.create_date
	, i.name
	, i.type_desc
	, ps.name
	, ps.type

FROM sys.tables AS t   
JOIN sys.indexes AS i   
    ON t.[object_id] = i.[object_id]   
JOIN sys.partition_schemes ps   
    ON i.data_space_id = ps.data_space_id   
WHERE t.name = 'PartitionTable';   
GO  

-- Determine the partition column for a partitioned table
SELECT   
    t.[object_id] AS ObjectID
    , SCHEMA_NAME(t.schema_id) AS SchemaName
    , t.name AS TableName   
    , ic.column_id AS PartitioningColumnID   
    , c.name AS PartitioningColumnName
    , i.name as IndexName
FROM sys.tables AS t   
JOIN sys.indexes AS i   
    ON t.[object_id] = i.[object_id]   
    AND i.[type] <= 1 -- clustered index or a heap   
JOIN sys.partition_schemes AS ps   
    ON ps.data_space_id = i.data_space_id   
JOIN sys.index_columns AS ic   
    ON ic.[object_id] = i.[object_id]   
    AND ic.index_id = i.index_id   
    AND ic.partition_ordinal >= 1 -- because 0 = non-partitioning column   
JOIN sys.columns AS c   
    ON t.[object_id] = c.[object_id]   
    AND ic.column_id = c.column_id   
WHERE t.name = 'PartitionTable';   
GO  

/* Query to show how many partition each table has */
SELECT 
    t.name AS TableName,
    s.name AS SchemaName,
    i.name AS IndexName,
    COUNT(DISTINCT p.partition_number) AS PartitionCount
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE i.data_space_id IN (
    SELECT data_space_id
    FROM sys.partition_schemes
)
GROUP BY t.name, s.name, i.name;


/* Query to show the number of records in each partition: */
SELECT 
    t.name AS TableName,
    s.name AS SchemaName,
    i.name AS IndexName,
    p.partition_number AS PartitionNumber,
    p.rows AS [RowCount]
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE i.data_space_id IN (
    SELECT data_space_id
    FROM sys.partition_schemes
)
ORDER BY t.name, p.partition_number;

-- Query to get information about partitioned tables and record counts in each partition
WITH PartitionInfo AS (
    SELECT
        t.name AS TableName,
        s.name AS SchemaName,
        ps.name AS PartitionSchemeName,
        p.partition_id,
        p.partition_number,
        SUM(p.rows) AS RecordCount
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    JOIN sys.partitions p ON t.object_id = p.object_id
    JOIN sys.indexes i ON t.object_id = i.object_id AND p.index_id = i.index_id
    JOIN sys.data_spaces ds ON i.data_space_id = ds.data_space_id
    JOIN sys.partition_schemes ps ON ds.data_space_id = ps.data_space_id
    WHERE i.type IN (1, 2) -- Clustered and non-clustered indexes
    GROUP BY t.name, s.name, ps.name, p.partition_id, p.partition_number
)
SELECT
    TableName,
    SchemaName,
    PartitionSchemeName AS PartitionName,
    partition_number AS PartitionNumber,
    RecordCount
FROM
    PartitionInfo
WHERE 
	TableName = 'ReceivedBox'
GROUP BY TableName, SchemaName, PartitionSchemeName, partition_number, RecordCount
ORDER BY
    SchemaName,
    TableName,
    PartitionNumber;

