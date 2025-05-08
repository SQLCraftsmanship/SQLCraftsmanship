show temp_tablespaces;

-- All the databases have a default tablespace called “pg_default” which is a kind of pseudo tablespace as it does not 
-- really exist. Asking the catalog about the location of that tablespace will show an empty location:
select 
	  oid
	, spcname AS "Name"
	, pg_catalog.pg_get_userbyid(spcowner) AS "Owner"
	, pg_catalog.pg_tablespace_location(oid) AS "Location"
from pg_catalog.pg_tablespace
where pg_catalog.pg_tablespace.spcname = 'pg_default'
order by 1;

-- The first reason for creating one or more dedicated temporary tablespaces: By doing this you can avoid that temporary 
-- tables going crazy impact your whole cluster as long as the temporary tablespace is on it’s own file system.
CREATE TABLESPACE ts_dgips_temp LOCATION '/data_postgres/tablespace/DGIPS_TEMP';

-- Once we have the new tablespace we can tell PostgreSQL to use it as the default for temporary objects:
ALTER SYSTEM SET temp_tablespaces = 'ts_dgips_temp';
SELECT pg_reload_conf();
SHOW temp_tablespaces;

-- The amount of temporary files generated can also be limited by temp_file_limit:
-- Specifies the maximum amount of disk space that a process can use for temporary files, such as sort and hash 
-- temporary files, or the storage file for a held cursor. A transaction attempting to exceed this limit will be 
-- canceled. If this value is specified without units, it is taken as kilobytes. -1 (the default) means no limit. 
-- Only superusers can change this setting.

-- This setting constrains the total space used at any instant by all temporary files used by a given PostgreSQL process.
-- It should be noted that disk space used for explicit temporary tables, as opposed to temporary files used 
-- behind-the-scenes in query execution, does not count against this limit.
SELECT 
	  datid
	, datname
	, temp_files AS "Temporary files"
    , temp_bytes AS "Size of temporary files"
	, stats_reset
FROM   pg_stat_database db;
