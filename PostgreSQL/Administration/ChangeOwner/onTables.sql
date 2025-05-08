
SELECT ('ALTER TABLE ' || quote_ident(s.nspname) || '.' || quote_ident(s.relname) || ' OWNER TO $postgres')
  FROM (SELECT nspname, relname
          FROM pg_class c JOIN pg_namespace n ON (c.relnamespace = n.oid) 
         WHERE nspname NOT LIKE E'pg\\_%' AND 
               nspname <> 'information_schema' AND 
               relkind IN ('r','S','v') ORDER BY relkind = 'S') s;
