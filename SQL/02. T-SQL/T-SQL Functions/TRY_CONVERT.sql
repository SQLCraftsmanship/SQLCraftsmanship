
-- ------------------------------------------------------------------------------------------------------------------
-- https://docs.microsoft.com/en-us/sql/t-sql/functions/try-convert-transact-sql?view=sql-server-ver15
-- ------------------------------------------------------------------------------------------------------------------

SET DATEFORMAT dmy;  
SELECT TRY_CONVERT(datetime2, '12/31/2010') AS Result;  
GO  

SELECT   
    CASE WHEN TRY_CONVERT(float, 'test') IS NULL   
    THEN 'Cast failed'  
    ELSE 'Cast succeeded'  
END AS Result;  
GO  
