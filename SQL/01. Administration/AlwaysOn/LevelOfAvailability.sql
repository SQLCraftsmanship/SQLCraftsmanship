USE [StackOverflow2010]
GO

/****** Object:  StoredProcedure [dbo].[LevelsOfAvailability]    Script Date: 2/3/2022 10:18:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [dbo].[LevelsOfAvailability] (@parUptime DECIMAL(5, 3), @parUptimeInterval VARCHAR(5))

AS

BEGIN TRY

    -- Check parameter
    -- IF NOT (@parUptime = 99) OR (@parUptime = 99.9) OR (@parUptime = 99.99) OR (@parUptime = 99.999)
        

    -- Specify the uptime level to calculate
    DECLARE @Uptime DECIMAL(5, 3) = @parUptime -- 99.99

    -- Specify WEEK, MONTH or YEAR
    DECLARE @UptimeInterval VARCHAR(5) = @parUptimeInterval -- 'YEAR'

    -- Calculate seconds per interval
    DECLARE @SecondsPerInterval FLOAT =
        (
            SELECT
                CASE
                    WHEN @UptimeInterval = 'YEAR'  THEN 60 * 60 * 24 * 365.243
                    WHEN @UptimeInterval = 'MONTH' THEN 60 * 60 * 24 * 30.437
                    WHEN @UptimeInterval = 'WEEK'  THEN 60 * 60 * 24 * 7
                END
        )

    -- Calculate uptime
    DECLARE @UptimeSeconds DECIMAL(12, 4) = @SecondsPerInterval * (100 - @Uptime) / 100

    -- Format result
    SELECT 
          CONVERT(VARCHAR(12), FLOOR(@UptimeSeconds / 60 / 60 / 24)) AS [Day(s)]     -- + ' Day(s), '      
        , CONVERT(VARCHAR(12), FLOOR(@UptimeSeconds / 60 / 60 % 24)) AS [Hours(s)]   -- + ' Hours(s), '    
        , CONVERT(VARCHAR(12), FLOOR(@UptimeSeconds / 60 % 60 ))     AS [Minutes(s)] -- + ' Minutes(s), '  
        , CONVERT(VARCHAR(12), FLOOR(@UptimeSeconds % 60 ))          AS [Seconds(s)] -- + ' Seconds(s)'    
END TRY

BEGIN CATCH
    SELECT
        ERROR_NUMBER()      AS ErrorNumber,
        ERROR_STATE()       AS ErrorState,
        ERROR_SEVERITY()    AS ErrorSeverity,
        ERROR_PROCEDURE()   AS ErrorProcedure,
        ERROR_LINE()        AS ErrorLine,
        ERROR_MESSAGE()     AS ErrorMessage;
END CATCH;
