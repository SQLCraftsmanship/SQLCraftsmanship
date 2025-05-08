
-- 1. postgresqlCreate multiples copies of postgresql.conf file.
Por si acaso hacer una copia del archivo con otro nombre

    -- "/var/lib/pgsql/13/data/postgresql.conf"
    SHOW config_file

-- 2. Archivo de LOG
    -- "log/postgresql-Thu.log"
    SELECT * FROM pg_current_logfile();

    -- Chequeamos tambien el nombre del archivo de LOG
    -- "postgresql-%a.log"
    SHOW log_filename 

-- 3. Chequear que logging_collector este en on
SHOW logging_collector 

-- 4. Set log_hostname = 1
-- off
SHOW log_hostname
	SET log_hostname = 'on'

-- 5. Set log_timezone = 'America/Buenos_Aires'
-- "America/New_York"
SHOW log_timezone
	SET log_timezone = 'America/Buenos_Aires'

-- 6. Set log_statement = 'mod'
-- none
SHOW log_statement
	SET log_statement = 'mod'

-- 7. SHOW log_destination
-- "stderr"
SHOW log_destination
    SET log_destination = 'stderr,csvlog'

-- 8. log_min_duration_statement
-- -1
SHOW log_min_duration_statement
	SET log_min_duration_statement = 1

-- 9. log_line_prefix
-- "%m [%p] "
SHOW log_line_prefix;
	SET log_line_prefix = 'time=%t, app=%a, usr=%u, db=%d, host=%r, pid=%p, line=%l, client=%h'


--10. With shell
-- Lo mismo que antes pero con el shell
postgres -c log_hostname=yes -c log_destination='syslog'

-- 11. Restart postgreSQL Service
-- Unix
$ service postgresql restart

-- 12. Verificar que el archivo de Log se creo.
-- Buscarlo en el path del paso 2


