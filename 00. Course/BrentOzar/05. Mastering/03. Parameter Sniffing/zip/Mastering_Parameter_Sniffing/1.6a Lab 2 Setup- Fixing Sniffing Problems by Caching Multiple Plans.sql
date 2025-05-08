/*
Mastering Parameter Sniffing
Lab Setup: Fixing Parameter Sniffing Problems with Branching

v1.1 - 2021-01-26

https://www.BrentOzar.com/go/mastersniffing


This demo requires:
* SQL Server 2017 or newer
* 2018-06 Stack Overflow database: https://www.BrentOzar.com/go/querystack

*/
USE StackOverflow;
GO
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 140; /* 2017, not 2019 yet */
GO
EXEC sys.sp_configure N'cost threshold for parallelism', N'50' /* Keep small queries serial */
GO
EXEC sys.sp_configure N'max degree of parallelism', N'4' /* Let queries go parallel */
GO
RECONFIGURE
GO
CREATE OR ALTER PROC dbo.RecentPostsByLocation @Location NVARCHAR(100) AS
	SELECT TOP 200 p.Title, p.Id, p.CreationDate
	  FROM dbo.Posts p
	  INNER JOIN dbo.Users u ON p.OwnerUserId = u.Id
	  WHERE u.Location = @Location
	  ORDER BY p.CreationDate DESC
GO