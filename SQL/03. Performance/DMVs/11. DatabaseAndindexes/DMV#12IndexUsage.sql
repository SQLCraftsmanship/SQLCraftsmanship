
------------------------------------------------------------------------------------------------------
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-index-usage-stats-transact-sql?view=sql-server-ver15
------------------------------------------------------------------------------------------------------


-- Index Read/Write stats (all tables in current DB)
/* ---------------------------------------------------------------------------------------------------
This is a very useful query for better understanding your workload. You can use it to help determine how 
volatile a particular index is, and the ratio of reads to writes. This can help you refine and tune your 
indexing strategy. For example, if you had a table that was pretty static (very few writes on any of the 
indexes), you could feel more confident about adding more indexes that are listed in your missing index 
queries. If you have SQL Server 2008 Enterprise Edition, this query could help you decide whether it 
would be a good idea to enable data compression (either Page or Row). An index with very little write 
activity is likely to be a better candidate for data compression than an index that is more volatile.
----------------------------------------------------------------------------------------------------- */
SELECT 
      OBJECT_NAME(s.[object_id]) AS [ObjectName]
    , i.name      AS [IndexName] 
    , i.index_id 
    , user_seeks + user_scans + user_lookups AS [Reads]
    , user_updates  AS [Writes]
    , i.type_desc   AS [IndexType]
    , i.fill_factor AS [FillFactor]

FROM sys.dm_db_index_usage_stats AS s
JOIN sys.indexes AS i 
ON   s.[object_id] = i.[object_id]

WHERE OBJECTPROPERTY(s.[object_id], 'IsUserTable') = 1
AND   i.index_id = s.index_id
AND   s.database_id = DB_ID()

ORDER BY 
    OBJECT_NAME(s.[object_id]) ,
    writes DESC ,
    reads  DESC;

-- List unused indexes
/* ---------------------------------------------------------------------------------------------------
Column [Type]
AF = Aggregate function (CLR)
C = CHECK constraint
D = DEFAULT (constraint or stand-alone)
F = FOREIGN KEY constraint
FN = SQL scalar function
FS = Assembly (CLR) scalar-function
FT = Assembly (CLR) table-valued function
IF = SQL inline table-valued function
IT = Internal table
P = SQL Stored Procedure
PC = Assembly (CLR) stored-procedure
PG = Plan guide
PK = PRIMARY KEY constraint
R = Rule (old-style, stand-alone)
RF = Replication-filter-procedure
S = System base table
SN = Synonym
SO = Sequence object
U = Table (user-defined)
V = View
EC = Edge constraint

Applies to: SQL Server 2012 (11.x) and later.
SQ = Service queue
TA = Assembly (CLR) DML trigger
TF = SQL table-valued-function
TR = SQL DML trigger
TT = Table type
UQ = UNIQUE constraint
X = Extended stored procedure

Applies to: SQL Server 2014 (12.x) and later, Azure SQL Database, Azure Synapse Analytics, Parallel Data Warehouse.
ST = STATS_TREE

Applies to: SQL Server 2016 (13.x) and later, Azure SQL Database, Azure Synapse Analytics, Parallel Data Warehouse.
ET = External Table
----------------------------------------------------------------------------------------------------- */
SELECT
    OBJECT_NAME(i.[object_id]) AS [Table Name]
    , i.name

FROM sys.indexes AS i

JOIN sys.objects AS o 
ON i.[object_id] = o.[object_id]

WHERE 
    i.index_id NOT IN (
                        SELECT 
                            s.index_id
                        FROM  sys.dm_db_index_usage_stats AS s
                        WHERE 
                              s.[object_id] = i.[object_id]
                        AND   i.index_id    = s.index_id
                        AND   database_id   = DB_ID() )
AND   o.[type] = 'U'
ORDER BY OBJECT_NAME(i.[object_id]) ASC ;


-- Possible Bad NC Indexes (writes > reads)
/* ---------------------------------------------------------------------------------------------------
index_id
    0 = Heap
    1 or 5 = Clustered index (B tree, columnstore)
    > 1 and <> 5 = Nonclustered index

When I run this query, I look for any indexes that have large numbers of writes with zero reads. 
Any index that falls into that category is a pretty good candidate for deletion (after some further 
investigation). You want to make sure that your SQL Server instance has been running long enough that 
you have your complete, typical workload included. 
Next, I look at rows where there are large numbers of writes and a small number of reads. 
----------------------------------------------------------------------------------------------------- */

SELECT 
      OBJECT_NAME(s.[object_id]) AS [Table Name]
    , i.name AS [Index Name]
    , i.index_id
    , user_updates AS [Total Writes]
    , user_seeks + user_scans + user_lookups AS [Total Reads]
    , user_updates - ( user_seeks + user_scans + user_lookups) AS [Difference]

FROM sys.dm_db_index_usage_stats AS s WITH ( NOLOCK )
JOIN sys.indexes AS i WITH ( NOLOCK )
ON   s.[object_id] = i.[object_id]
AND  i.index_id = s.index_id

WHERE 
    OBJECTPROPERTY(s.[object_id], 'IsUserTable') = 1
AND s.database_id = DB_ID()
AND user_updates > (user_seeks + user_scans + user_lookups)
AND i.index_id > 1

ORDER BY 
    [Difference]    DESC,
    [Total Writes]  DESC,
    [Total Reads]   ASC;
