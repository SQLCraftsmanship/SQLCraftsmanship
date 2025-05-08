
-- maintenace_work_men
SHOW maintenance_work_mem;

ALTER SYSTEM SET maintenance_work_mem = "24GB";

SELECT pg_reload_conf();

SHOW maintenance_work_mem;

-------------------------------------------------------------------------------------------------------------
-- https://www.postgresql.org/docs/9.1/runtime-config-logging.html
-- https://www.enterprisedb.com/blog/why-postgresql-logging-important-database-problems
-- https://www.2ndquadrant.com/en/blog/how-to-get-the-best-out-of-postgresql-logs/
-------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------
	
	
	-- 4 SHOW log_line_prefix; 
	-- %m	Time stamp with milliseconds %p	Process ID
	-- %a - Application Name - Allows quick reference and filtering
	-- %u - User Name - Allows filter by user name
	-- %d - Database Name - Allows filter by database name
	-- %r - Remote Host IP/Name (w/ port) - Helps identify suspicious activity from a host
	-- %p - Process ID - Helps identify specific problematic sessions
	-- %l - Session/Process Log Line - Helps identify what a session has done
	-- %v/%x - Transaction IDs - Helps identify what queries a transaction ran
	-- %t - The time of the event (without milliseconds)
    -- %h - Remote client name or IP address

    -- log_line_prefix = 'time=%t, pid=%p %q db=%d, usr=%u, client=%h , app=%a, line=%l'
-------------------------------------------------------------------------------------------------------------

-- postgresql.conf file or on the server command line.
SHOW config_file
	select * from pg_current_logfile();
	select pg_reload_conf();
	-- log_destination = 'stderr,csvlog,syslog' 

-- 18.8.1. Where To Log
SHOW log_destination;
	SET log_destination = 'csvlog';
	
SHOW logging_collector; 
SHOW log_directory;
SHOW log_filename;
SHOW log_file_mode; -- 0600, meaning only the server owner can read or write the log files.
SHOW log_rotation_age;
SHOW log_rotation_size; -- Set to zero to disable size-based creation of new log files. 
SHOW log_truncate_on_rotation;
SHOW syslog_facility;
SHOW syslog_ident;
-- SHOW silent_mode; -- ERROR no encuentra este parametro

--18.8.2. When To Log
SHOW client_min_messages; -- Valid values are DEBUG5, DEBUG4, DEBUG3, DEBUG2, DEBUG1, LOG, NOTICE, WARNING, ERROR, FATAL, and PANIC. 
SHOW log_min_messages; -- Quizas se pueda poder en error
SHOW log_min_error_statement;
SHOW log_min_duration_statement; 
	-- Minus-one (the default) disables logging statement durations.  
	-- helpful in identifying slow queries
	-- Esto estaria bueno habilitarlo
	-- VER
	
-- 18.8.3. What To Log
SHOW application_name;
SHOW debug_print_parse;
SHOW debug_print_rewritten;
SHOW debug_print_plan;
SHOW debug_pretty_print;
SHOW log_checkpoints;
SHOW log_connections;
SHOW log_disconnections;
	-- good for auditing purposes
	-- VER

SHOW log_duration;
SHOW log_error_verbosity;
SHOW log_hostname;
SHOW log_line_prefix; 
	-- %m	Time stamp with milliseconds %p	Process ID
	--	%a - Application Name - Allows quick reference and filtering
	--	%u - User Name - Allows filter by user name
	--	%d - Database Name - Allows filter by database name
	--	%r - Remote Host IP/Name (w/ port) - Helps identify suspicious activity from a host
	--	%p - Process ID - Helps identify specific problematic sessions
	--	%l - Session/Process Log Line - Helps identify what a session has done
	--	%v/%x - Transaction IDs - Helps identify what queries a transaction ran

					  
SHOW log_lock_waits;
	-- https://www.postgresql.org/docs/9.1/runtime-config-locks.html#GUC-DEADLOCK-TIMEOUT
	SHOW deadlock_timeout 
	
SHOW log_statement; 
	-- Aca quiero hacer log de INSERT - DROP - DELETE entonces lo pondria en MOD
	-- good for auditing purposes
	-- VER
	
SHOW log_temp_files;
	-- VER
	
SHOW log_timezone;



