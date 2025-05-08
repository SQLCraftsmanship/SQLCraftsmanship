
/****************************************************************************************************
Different ways to search for objects in SQL databases

Ref
https://www.sqlshack.com/different-ways-to-search-for-objects-in-sql-databases/
https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-all-objects-transact-sql?view=sql-server-ver15
****************************************************************************************************/


SELECT name AS [Name], 
       SCHEMA_NAME(schema_id) AS schema_name, 
       type_desc, 
       create_date, 
       modify_date
FROM sys.objects
WHERE type ='u'

SELECT name AS [Name], 
       SCHEMA_NAME(schema_id) AS schema_name, 
       type_desc, 
       create_date, 
       modify_date
FROM sys.objects
WHERE type ='p'

SELECT name AS [Name], 
       SCHEMA_NAME(schema_id) AS schema_name, 
       type_desc, 
       create_date, 
       modify_date
FROM sys.objects
WHERE modify_date > GETDATE() - 60
ORDER BY modify_date;  
GO


SELECT *
FROM information_schema.Tables
WHERE [Table_Name]='demotable'


SELECT *
FROM information_schema.CHECK_CONSTRAINTS

SELECT catalog_name AS DBName, 
    Schema_name, 
    schema_owner
FROM information_schema.SCHEMATA;


SELECT * FROM sys.all_objects
