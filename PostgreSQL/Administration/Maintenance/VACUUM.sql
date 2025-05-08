
-- Comando VACUUM
-- Este comando se utiliza para realizar limpieza en cada tabla o en la base de datos, así evitamos que el 
-- sistema se sobrecargue de filas muertas o que las tablas ocupen demasiado espacio físico en el disco 
-- duro. Esto podría hacer que el sistema se vea mermado en su rendimiento con el paso del tiempo

-- ------------------------------------------------------------------------------------------------------
-- https://www.postgresql.org/docs/13/sql-vacuum.html
-- ------------------------------------------------------------------------------------------------------

-- CHECK CONFIGURATION
--	RESULT
--	"autovacuum"	"on"
select name, setting from pg_settings where name = 'autovacuum' ;

-- Query that identifies tables that need the VACUUM operation
-- The following example identifies the top 50 tables that need the VACUUM operation performed on them:
SELECT 
	  c.oid::regclass
	, age(c.relfrozenxid)
	, pg_size_pretty(pg_total_relation_size(c.oid))
FROM pg_class c
JOIN pg_namespace n on c.relnamespace = n.oid
WHERE relkind IN ('r', 't', 'm')
AND n.nspname NOT IN ('pg_toast')
ORDER BY 2 DESC LIMIT 50;

-- Exec
VACUUM(FULL, ANALYZE, VERBOSE) [tablename]
VACUUM(FULL, ANALYZE, VERBOSE) [schemaName]

-- Comando ANALYZE
-- Con este comando se analizan cada una de las tablas o la base de datos para informar al planificador de 
-- consultas del estado de las mismas, de esta forma obtenemos mejor rendimiento cuando se ejecutan las 
-- consultas en la PostgreSQL.