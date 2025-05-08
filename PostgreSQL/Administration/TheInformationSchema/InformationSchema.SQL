
-- https://www.postgresql.org/docs/13/information-schema.html

SELECT *
FROM information_schema.tables
WHERE 
	table_type = 'BASE TABLE'
AND table_schema = 'public'

SELECT *
FROM information_schema.sequence

