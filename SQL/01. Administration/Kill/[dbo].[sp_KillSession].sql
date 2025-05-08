
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_KillSession]
    @id INT
AS
BEGIN

    SET NOCOUNT ON;

    -- Check if the session ID exists
    IF EXISTS (SELECT 1 FROM sys.dm_exec_sessions WHERE session_id = @id)
    BEGIN
	
		-- Log the kill request
        INSERT INTO dbo.SessionKillLog (UserName, SessionID, KillDate)
        VALUES (SUSER_NAME(), @id, GETDATE());
        
		-- Kill the session
        BEGIN TRY
            DECLARE @sql NVARCHAR(100);
			SET @sql = 'KILL ' + CAST(@id AS NVARCHAR(10));
			EXEC sp_executesql @sql;
            PRINT 'Session ' + CAST(@id AS VARCHAR(10)) + ' has been killed successfully.';
        END TRY
    
		BEGIN CATCH
            DECLARE @ErrorMessage NVARCHAR(4000);
            DECLARE @ErrorSeverity INT;
            DECLARE @ErrorState INT;

            SELECT 
                @ErrorMessage = ERROR_MESSAGE(),
                @ErrorSeverity = ERROR_SEVERITY(),
                @ErrorState = ERROR_STATE();

            RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
        END CATCH
    END
    ELSE
    BEGIN
        -- Return an error message if the session does not exist
        RAISERROR ('Session ID %d does not exist.', 16, 1, @id);
    END
END
GO

