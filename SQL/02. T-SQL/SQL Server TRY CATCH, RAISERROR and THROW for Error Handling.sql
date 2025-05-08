
BEGIN TRY
	RAISERROR ('An error occurred in the TRY block.', 16, 1);
END TRY
BEGIN CATCH
	DECLARE @ErrorMessage NVARCHAR(2048),
            @ErrorSeverity INT,
            @ErrorState INT;
 
    SELECT @ErrorMessage = ERROR_MESSAGE(),
           @ErrorSeverity = ERROR_SEVERITY(),
           @ErrorState = ERROR_STATE();
 
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;


BEGIN TRY
    SELECT 1 / 0;
END TRY
BEGIN CATCH
    PRINT('The error is raised once again');
    THROW;
END CATCH


--Note
--You can't convinate RAISERROR with TRY CATCH....
