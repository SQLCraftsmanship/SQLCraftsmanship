CREATE TABLE postgres_log
(
  log_time timestamp(3) with time zone,
  user_name text,
  database_name text,
  process_id integer,
  connection_from text,
  session_id text,
  session_line_num bigint,
  command_tag text,
  session_start_time timestamp with time zone,
  virtual_transaction_id text,
  transaction_id bigint,
  error_severity text,
  sql_state_code text,
  message text,
  detail text,
  hint text,
  internal_query text,
  internal_query_pos integer,
  context text,
  query text,
  query_pos integer,
  location text,
  application_name text,
  backend_type text,
  leader_pid integer,
  query_id bigint,
  PRIMARY KEY (session_id, session_line_num)
);

COPY postgres_log FROM '/full/path/to/logfile.csv' WITH csv;

SELECT * FROM postgres_log

cd /var/lib/pgsql/13/data/log/

-- CREATE EXTENSION file_fdw;

-- CREATE SERVER pglog FOREIGN DATA WRAPPER file_fdw;

-- CREATE FOREIGN TABLE pglog (
--   log_time timestamp(3) with time zone,
--   user_name text,
--   database_name text,
--   process_id integer,
--   connection_from text,
--   session_id text,
--   session_line_num bigint,
--   command_tag text,
--   session_start_time timestamp with time zone,
--   virtual_transaction_id text,
--   transaction_id bigint,
--   error_severity text,
--   sql_state_code text,
--   message text,
--   detail text,
--   hint text,
--   internal_query text,
--   internal_query_pos integer,
--   context text,
--   query text,
--   query_pos integer,
--   location text,
--   application_name text
-- ) SERVER pglog
-- OPTIONS ( filename 'pg_log/postgresql.csv', format 'csv' );

