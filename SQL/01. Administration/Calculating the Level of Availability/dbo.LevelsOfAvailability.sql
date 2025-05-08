
/**************************************************************************************************************************************************************************
Calculating the Level of Availability

Table Levels of Availability
    
    Level of Abailability   |    Downtime per Week              |   Downtime per Month              |   Downtime per Year
    ----------------------------------------------------------------------------------------------------------------------------------------------
        99%                 |   1 Hour, 40 Minutes, 48 Seconds  |   7 Hour, 18 Minutes, 17 Seconds  |   3 Days, 15 Hours, 39 Minutes, 28 Seconds  
        99.9%               |   0 Hour, 10 Minutes,  4 Seconds  |   0 Hour, 43 Minutes, 49 Seconds  |   0 Days,  8 Hours, 45 Minutes, 56 Seconds  
        99.99%              |   0 Hour,  1 Minutes,  0 Seconds  |   0 Hour,  4 Minutes, 23 Seconds  |   0 Days,  0 Hours, 52 Minutes, 35 Seconds  
        99.999%             |   0 Hour,  0 Minutes,  6 Seconds  |   0 Hour,  0 Minutes, 26 Seconds  |   0 Days,  0 Hours,  5 Minutes, 15 Seconds  

Exec Command: 
                EXEC [dbo].[LevelsOfAvailability] 99.999, 'week'
**************************************************************************************************************************************************************************/

IF EXISTS (SELECT 1 FROM SYS.PROCEDURES WHERE Name = 'LevelsOfAvailability')
    DROP PROC [dbo].[LevelsOfAvailability]
GO

CREATE PROC [dbo].[LevelsOfAvailability] (@parUptime DECIMAL(5, 3), @parUptimeInterval VARCHAR(5))

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
GO
