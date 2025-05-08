
-- REF
https://severalnines.com/database-blog/guide-partitioning-data-postgresql
https://www.enterprisedb.com/postgres-tutorials/how-use-table-partitioning-scale-postgresql
https://postgrespro.com/docs/postgrespro/11/ddl-partitioning



-- 1. How to check if table is partition or to find existing partitions � there is a new column �relispartition� in pg_class table:
select * from pg_class where relispartition is true

/********************************************************************************************
-- 2.
WITH RECURSIVE tables AS (
  SELECT-- Table per tablespace
SELECT 
	current_database(), 
    n.nspname as schema_name, 
    c.relname as object_name,
    case c.relkind 
     when 'r' then 'table'
     when 'i' then 'index'
     when 't' then 'TOAST table'
     when 'm' then 'materialized view'
     when 'f' then 'foreign table'
     when 'p' then 'partitioned table'
    else c.relkind::text
    end as object_type,
    t.spcname as tablespace_name
FROM pg_class c 
JOIN pg_namespace n on n.oid = c.relnamespace
JOIN pg_tablespace t ON c.reltablespace = t.oid

-- 2
SELECT pg_relation_filepath('schdgips."VISTA_DM_CONCEPTOS"');

-- 3
SELECT *
FROM pg_tables 
WHERE Tablename LIKE '%VISTA_DM_CONCEPTOS%'

-- 4

    c.oid AS parent,
    c.oid AS relid,
    1     AS level
  FROM pg_catalog.pg_class c
  LEFT JOIN pg_catalog.pg_inherits AS i ON c.oid = i.inhrelid
    -- p = partitioned table, r = normal table
  WHERE c.relkind IN ('p', 'r')
    -- not having a parent table -> we only get the partition heads
    AND i.inhrelid IS NULL
  UNION ALL
  SELECT
    p.parent         AS parent,
    c.oid            AS relid,
    p.level + 1      AS level
  FROM tables AS p
  LEFT JOIN pg_catalog.pg_inherits AS i ON p.relid = i.inhparent
  LEFT JOIN pg_catalog.pg_class AS c ON c.oid = i.inhrelid AND c.relispartition
  WHERE c.oid IS NOT NULL
)
SELECT
  parent ::REGCLASS                                  AS table_name,
  array_agg(relid :: REGCLASS)                       AS all_partitions,
  pg_size_pretty(sum(pg_total_relation_size(relid))) AS pretty_total_size,
  sum(pg_total_relation_size(relid))                 AS total_size
FROM tables
GROUP BY parent
ORDER BY sum(pg_total_relation_size(relid)) DESC
********************************************************************************************/

-- 3. Total of rows
SELECT schemaname,relname,n_live_tup
FROM pg_stat_user_tables
where relname like 'VISTA_DM_CONCEPTOS%'
ORDER BY relname DESC ;

-- 4. Amount of Partition per data and per index
SELECT
    nmsp_parent.nspname     AS parent_schema,
    parent.relname          AS parent,
    COUNT(*)
FROM pg_inherits
    JOIN pg_class parent        ON pg_inherits.inhparent = parent.oid
    JOIN pg_class child     ON pg_inherits.inhrelid   = child.oid
    JOIN pg_namespace nmsp_parent   ON nmsp_parent.oid  = parent.relnamespace
    JOIN pg_namespace nmsp_child    ON nmsp_child.oid   = child.relnamespace
GROUP BY
    parent_schema,
    parent;

-- 5. Size per partition
SELECT
  relname AS table_name,
  pg_size_pretty(pg_total_relation_size(relid)) AS total,
  pg_size_pretty(pg_relation_size(relid)) AS internal,
  pg_size_pretty(pg_table_size(relid) - pg_relation_size(relid)) AS external,
  pg_size_pretty(pg_indexes_size(relid)) AS indexes
  --pg_size_pretty(sum(pg_indexes_size(psu.relid))) AS indexes
FROM pg_catalog.pg_statio_user_tables 
ORDER BY pg_total_relation_size(relid) DESC;



