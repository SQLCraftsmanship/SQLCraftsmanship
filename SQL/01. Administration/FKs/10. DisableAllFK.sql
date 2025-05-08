
USE AdventureWorks2012;  
GO  
ALTER TABLE Purchasing.PurchaseOrderHeader  
NOCHECK CONSTRAINT FK_PurchaseOrderHeader_Employee_EmployeeID;  
GO  

USE AdventureWorks2012;  
GO  
ALTER TABLE Purchasing.PurchaseOrderHeader  
CHECK CONSTRAINT FK_PurchaseOrderHeader_Employee_EmployeeID;  
GO  

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

DECLARE @sql NVARCHAR(MAX) = N'';

;WITH x AS 
(
  SELECT DISTINCT obj = 
      QUOTENAME(OBJECT_SCHEMA_NAME(parent_object_id)) + '.' 
    + QUOTENAME(OBJECT_NAME(parent_object_id)) 
  FROM sys.foreign_keys
)
SELECT @sql += N'ALTER TABLE ' + obj + ' NOCHECK CONSTRAINT ALL;
' FROM x;

EXEC sp_executesql @sql;


DECLARE @sql NVARCHAR(MAX) = N'';

;WITH x AS 
(
  SELECT DISTINCT obj = 
      QUOTENAME(OBJECT_SCHEMA_NAME(parent_object_id)) + '.' 
    + QUOTENAME(OBJECT_NAME(parent_object_id)) 
  FROM sys.foreign_keys
)
SELECT @sql += N'ALTER TABLE ' + obj + ' WITH CHECK CHECK CONSTRAINT ALL;
' FROM x;

EXEC sp_executesql @sql;


-- Disable all the constraint in database
EXEC sp_msforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all"

-- Enable all the constraint in database
EXEC sp_msforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all"

