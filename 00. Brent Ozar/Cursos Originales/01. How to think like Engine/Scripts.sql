
/***********************************************************************************************************************************************************************************************
Notes

-- DBCC DBREINDEX ([Users], [IX_LastAccessDate_Id]); -- ENABLED
-- ALTER INDEX [IX_LastAccessDate_Id] ON [dbo].[Users] DISABLE

***********************************************************************************************************************************************************************************************/
-- 1.
SET STATISTICS IO ON

SELECT  Id
FROM dbo.Users;
Go

-- 2.
SET STATISTICS IO ON

SELECT  Id
FROM dbo.Users
WHERE LastAccessDate > '2014/07/01';
GO

-- 3.
SET STATISTICS IO ON

SELECT  Id
FROM dbo.Users
WHERE LastAccessDate > '2014/07/01'
ORDER BY LastAccessDate;
GO

-- 4.
SET STATISTICS IO ON

SELECT  *
FROM dbo.Users
WHERE LastAccessDate > '2014/07/01'
ORDER BY LastAccessDate;
GO


-- 5.
CREATE NONCLUSTERED INDEX [IX_LastAccessDate_Id] ON [dbo].[Users]
(
	[LastAccessDate] ,
    [ID]
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO


-- 6.
-- Ejecutar Query 3 de nuevo

-- 7.
-- Esta query la ejecuto junto con la 3. para ver cual es la diferencia con el plan de ejecucion y se puede ver que tambien usa el IX Seek NIX y luego hace el Sort por ID para depues escucpir 
-- el resultado.
SELECT  Id
FROM dbo.Users
WHERE LastAccessDate > '2014/07/01'
ORDER BY Id;
GO


-- 8.
SELECT Id
FROM dbo.Users
WHERE LastAccessDate > '1800/01/01'
ORDER BY LastAccessDate;
GO


-- 9.
SELECT Id, DisplayName, Age
FROM dbo.Users
WHERE LastAccessDate > '2014/07/01'
ORDER BY LastAccessDate;
GO

SELECT Id, DisplayName, Age
FROM dbo.Users
WHERE LastAccessDate > '3014/07/01'
ORDER BY LastAccessDate;
GO


-- 10.
SELECT Id, DisplayName, Age
FROM dbo.Users
WHERE LastAccessDate > '2014/07/01'
ORDER BY LastAccessDate;
GO

SELECT Id, DisplayName, Age
FROM dbo.Users WITH (INDEX = [IX_LastAccessDate_Id])
WHERE LastAccessDate > '2014/07/01'
ORDER BY LastAccessDate;
GO

-- 11.
DBCC SHOW_STATISTICS ('dbo.Users', 'IX_LastAccessDate_Id');

-- 12.
SET STATISTICS TIME, IO ON

SELECT Id, DisplayName, Age
FROM dbo.Users
WHERE LastAccessDate >= '2014/07/01'
AND   LastAccessDate <  '2014/08/01'
ORDER BY LastAccessDate;

SELECT Id, DisplayName, Age
FROM dbo.Users
WHERE YEAR(LastAccessDate) = '2014'
AND   MONTH(LastAccessDate) = '07'
ORDER BY LastAccessDate;


-- 13.
SELECT Id, DisplayName, Age
FROM dbo.Users
WHERE YEAR(LastAccessDate) = '2014'
AND   MONTH(LastAccessDate) = '07'
ORDER BY LastAccessDate;

SELECT Id, DisplayName, Age
FROM dbo.Users WITH (INDEX = IX_LastAccessDate_Id)
WHERE YEAR(LastAccessDate) = '2014'
AND   MONTH(LastAccessDate) = '07'
ORDER BY LastAccessDate;


-- 14.
SELECT Id, DisplayName, Age
FROM dbo.Users
WHERE LastAccessDate >= '2014/07/01'
AND   LastAccessDate <  '2014/08/01'
ORDER BY LastAccessDate;

SELECT Id, DisplayName, Age
FROM dbo.Users
WHERE YEAR(LastAccessDate) = '2014'
AND   MONTH(LastAccessDate) = '07'
ORDER BY LastAccessDate;

CREATE INDEX IX_LastAccessDate_ID_DisplayName_Age ON dbo.Users (LastAccessDate, Id, DisplayName, Age)



