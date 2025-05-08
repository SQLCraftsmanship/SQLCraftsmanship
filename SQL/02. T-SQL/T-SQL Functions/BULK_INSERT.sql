
-------------------------------------------------------------------------------------------------------------
-- INSERT a millon of records
-------------------------------------------------------------------------------------------------------------

SET NOCOUNT ON

IF EXISTS(SELECT [Name] FROM SYS.TABLES WHERE [Name] = 'tbl_InsertMillonRecords')
	DROP TABLE [dbo].[tbl_InsertMillonRecords]
GO

CREATE TABLE [dbo].[tbl_InsertMillonRecords]
(
	  id  INT
	, a   NVARCHAR(255)
	, b	  NVARCHAR(255)
)


-- Method 1
-- Start INSERT 
DECLARE @varCount INT
SET @varCount = 0

WHILE @varCount < 1000000
BEGIN
    SET @varCount = @varCount + 1

    INSERT INTO [dbo].[tbl_InsertMillonRecords]
    VALUES(@varCount, 'a_' + CAST(@varCount AS VARCHAR), 'b_' + CAST(@varCount / 2 AS VARCHAR))
END

-- Method 2
-- Start INSERT 
WITH temp AS
(
    SELECT  
        ROW_NUMBER() OVER(ORDER BY a.object_id) AS tcount 
    FROM sys.all_columns a, sys.all_columns b
    WHERE a.object_id = b.object_id  
) 
insert into t1
    select tcount, 'a_' + cast (tcount as varchar), 'b_' + cast (tcount/2 as varchar) 
    from temp 
go























