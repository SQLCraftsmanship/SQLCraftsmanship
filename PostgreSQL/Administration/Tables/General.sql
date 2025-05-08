-- Table per tablespace
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
