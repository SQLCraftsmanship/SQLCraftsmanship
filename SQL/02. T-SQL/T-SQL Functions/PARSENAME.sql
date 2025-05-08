
-------------------------------------------------------------------------------------------------------------
-- Returns the specified part of an object name. The parts of an object that can be retrieved are the 
-- object name, schema name, database name, and server name.
-- https://docs.microsoft.com/en-us/sql/t-sql/functions/parsename-transact-sql?view=sql-server-ver15

-- Is the object part to return. object_piece is of type int, and can have these values:
-- 1 = Object name
-- 2 = Schema name
-- 3 = Database name
-- 4 = Server name
-------------------------------------------------------------------------------------------------------------

USE AdventureWorks2019
GO

SELECT PARSENAME('AdventureWorksPDW2012.dbo.DimCustomer', 1) AS 'Object Name';  
SELECT PARSENAME('AdventureWorksPDW2012.dbo.DimCustomer', 2) AS 'Schema Name';  
SELECT PARSENAME('AdventureWorksPDW2012.dbo.DimCustomer', 3) AS 'Database Name';  
SELECT PARSENAME('AdventureWorksPDW2012.dbo.DimCustomer', 4) AS 'Server Name';  
GO


