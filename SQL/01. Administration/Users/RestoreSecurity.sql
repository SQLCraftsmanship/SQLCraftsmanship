
/*********************************************************************************************************************************************
Date		: 2022/03/01
Create by	: DBAs AMS
Object		: [dbo].[RestoreSecurity]
Description	: We first performed stored procedure [dbo].[ReCreateSecurity]. This create a table name [TEMPDB].[dbo].[ResultTable]
              which have the comma to create all object to restore the security.
              
Ref.         : N/A

Exec Command: EXEC [dbo].[RestoreSecurity]
*********************************************************************************************************************************************/

IF EXISTS (SELECT NAME FROM SYS.PROCEDURES WHERE NAME = 'RestoreSecurity')
	DROP PROCEDURE [dbo].[RestoreSecurity]
GO

CREATE PROC [dbo].[RestoreSecurity]
AS
BEGIN
	
	SET NOCOUNT ON

    -- Declare var table
    DECLARE @tbl_Command TABLE
    (
         [Pk_id]    NUMERIC(18, 0) NOT NULL IDENTITY (1, 1)
       , [Id]       NUMERIC(18, 0)
       , [Command]  NVARCHAR(MAX)
    )

    -- Create two vars to loop 
    DECLARE @Rows NUMERIC, @i NUMERIC(18,0)

    SET @Rows = 0
    SET @i    = 1

    -- Insert data to var table 
    INSERT INTO @tbl_Command
    (
          [Id]
        , [Command]
    )
    SELECT 
          [Id]
        , [Command]
    FROM [TEMPDB].[dbo].[ResultTable]

    -- Assign the total number of rows 
    SET @Rows = (SELECT TOP 1 [Pk_id] FROM @tbl_Command ORDER BY [Pk_id] DESC)

    -- Iterate with while. 
    WHILE @i <= @Rows
    BEGIN
        DECLARE @Id NUMERIC(18, 0), @Command NVARCHAR(MAX)

        SELECT @Id = [Id], @Command = [Command]
        FROM   @tbl_Command
        WHERE  [Pk_id] = @i

        EXEC(@Command)

        SELECT @Command

        SET @i = @i + 1
    END

END;
