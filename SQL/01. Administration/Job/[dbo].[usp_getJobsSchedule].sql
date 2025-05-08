USE [DBA]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Add
	JobEnabled
		sysjobs.enabled job_enabled
		from msdb.dbo.sysjobs

	ScheduleEnabled 
		SELECT
		  J.[name] AS JobName, J.[enabled] AS JobIsEnabled, ISNULL(SP.[name], 'Unknown') AS JobOwner, ISNULL(JS.[enabled], 0) AS ScheduleIsEnabled
		  ,ISNULL(JS.[Frequency], '') AS Frequency, ISNULL(JS.[DayInterval], '') AS DayInterval
		  ,ISNULL(JS.[DailyFrequency], '') AS [DailyFrequency], ISNULL(JS.[Recurrence], '') AS [Recurrence]
		  ,ISNULL(JS.[StartTime], '') AS [StartTime], ISNULL(JS.[EndTime], '') AS [EndTime]
		FROM msdb.dbo.sysjobs AS J
		  LEFT JOIN sys.server_principals	 AS SP ON J.owner_sid = SP.[sid]
		  LEFT JOIN msdb.dbo.sysjobschedules AS JJS ON J.job_id = JJS.job_id
		  LEFT JOIN JobSchedules			 AS JS ON JJS.schedule_id = JS.schedule_id
		ORDER BY J.[name] ASC;
*/

CREATE OR ALTER PROCEDURE [dbo].[usp_getJobsSchedule]
    @JobName SYSNAME    = NULL
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE @weekDay TABLE 
    (
        mask      INT
        , maskValue VARCHAR(32) 
    );

    INSERT INTO @weekDay
        SELECT 1 , 'Sunday'		UNION ALL
        SELECT 2 , 'Monday'		UNION ALL
        SELECT 4 , 'Tuesday'	UNION ALL
        SELECT 8 , 'Wednesday'  UNION ALL
        SELECT 16, 'Thursday'	UNION ALL
        SELECT 32, 'Friday'		UNION ALL
        SELECT 64, 'Saturday';

	BEGIN TRY
        WITH myCTE
        AS (SELECT 
                sched.name AS 'ScheduleName'
                , sched.schedule_id
                , jobsched.job_id
                , CASE WHEN sched.freq_type = 1 THEN 'Once' 
                    WHEN sched.freq_type = 4 
                        AND sched.freq_interval = 1 THEN 'Daily'
                    WHEN sched.freq_type = 4     THEN 'Every ' + CAST(sched.freq_interval AS VARCHAR(5)) + ' days'
                    WHEN sched.freq_type = 8 THEN REPLACE( REPLACE( REPLACE(( SELECT maskValue FROM @weekDay AS x WHERE sched.freq_interval & x.mask <> 0 ORDER BY mask FOR XML RAW)
                                                                                , '"/><row maskValue="', ', '), '<row maskValue="', ''), '"/>', '')
                                                    + CASE WHEN sched.freq_recurrence_factor <> 0
                                                            AND sched.freq_recurrence_factor = 1 THEN '; weekly' 
                                                        WHEN sched.freq_recurrence_factor <> 0 THEN '; every '
                                                        + CAST(sched.freq_recurrence_factor AS VARCHAR(10)) + ' weeks' 
                                                    END
                    WHEN sched.freq_type = 16 THEN 'On day '
                            + CAST(sched.freq_interval			AS VARCHAR(10)) + ' of every '
                            + CAST(sched.freq_recurrence_factor AS VARCHAR(10)) + ' months'
                    WHEN sched.freq_type = 32 THEN 
                            CASE WHEN sched.freq_relative_interval = 1  THEN 'First'
                                WHEN sched.freq_relative_interval = 2  THEN 'Second'
                                WHEN sched.freq_relative_interval = 4  THEN 'Third'
                                WHEN sched.freq_relative_interval = 8  THEN 'Fourth'
                                WHEN sched.freq_relative_interval = 16 THEN 'Last'
                            END +
                            CASE WHEN sched.freq_interval = 1  THEN ' Sunday'
                                WHEN sched.freq_interval = 2  THEN ' Monday'
                                WHEN sched.freq_interval = 3  THEN ' Tuesday'
                                WHEN sched.freq_interval = 4  THEN ' Wednesday'
                                WHEN sched.freq_interval = 5  THEN ' Thursday'
                                WHEN sched.freq_interval = 6  THEN ' Friday'
                                WHEN sched.freq_interval = 7  THEN ' Saturday'
                                WHEN sched.freq_interval = 8  THEN ' Day'
                                WHEN sched.freq_interval = 9  THEN ' Weekday'
                                WHEN sched.freq_interval = 10 THEN ' Weekend'
                            END + 
                            CASE WHEN sched.freq_recurrence_factor <> 0 
                                And sched.freq_recurrence_factor = 1  THEN '; monthly'
                                WHEN sched.freq_recurrence_factor <> 0 THEN '; every '
                                    + CAST(sched.freq_recurrence_factor AS VARCHAR(10)) + ' months' 
                            END
                    WHEN sched.freq_type = 64  THEN 'StartUp'
                    WHEN sched.freq_type = 128 THEN 'Idle'
                End AS 'frequency'
                , ISNULL('Every ' 
                            + CAST(sched.freq_subday_interval AS VARCHAR(10)) 
                            + CASE  WHEN sched.freq_subday_type = 2 THEN ' seconds'
                                    WHEN sched.freq_subday_type = 4 THEN ' minutes'
                                    WHEN sched.freq_subday_type = 8 THEN ' hours'
                            END, 'Once') AS 'subFrequency'
                , REPLICATE('0', 6 - LEN(sched.active_start_time)) + CAST(sched.active_start_time AS VARCHAR(6)) AS 'startTime'
                , REPLICATE('0', 6 - LEN(sched.active_end_time))   + CAST(sched.active_end_time   AS VARCHAR(6)) AS 'endTime'
                , REPLICATE('0', 6 - LEN(jobsched.next_run_time))  + CAST(jobsched.next_run_time  AS VARCHAR(6)) AS 'nextRunTime'
                , CAST(jobsched.next_run_date AS CHAR(8)) AS 'nextRunDate'
            FROM msdb.dbo.sysschedules    AS sched
            JOIN msdb.dbo.sysjobschedules AS jobsched
            ON sched.schedule_id = jobsched.schedule_id
            /* WHERE sched.enabled = 1 */
            )

        SELECT DISTINCT 
            job.name			AS	'Job Name'
            , sched.scheduleName	'Schedule Name'
            , sched.frequency		'Frequency'
            , sched.subFrequency	'Sub Frequency'
            , SUBSTRING(sched.startTime, 1, 2) + ':' 
                + SUBSTRING(sched.startTime, 3, 2) + ' - ' 
                + SUBSTRING(sched.endTime, 1, 2) + ':' 
                + SUBSTRING(sched.endTime, 3, 2) AS 'Schedule Time' -- HH:MM
            , SUBSTRING(sched.nextRunDate, 1, 4) + '/' 
                + SUBSTRING(sched.nextRunDate, 5, 2) + '/' 
                + SUBSTRING(sched.nextRunDate, 7, 2) + ' ' 
                + SUBSTRING(sched.nextRunTime, 1, 2) + ':' 
                + SUBSTRING(sched.nextRunTime, 3, 2) As 'Next Run Date / Time'
        /*    , CASE jhist.run_status
            WHEN 0 THEN 'Failed'
            WHEN 1 THEN 'Successful'
            WHEN 2 THEN 'Retry'
            WHEN 3 THEN 'Canceled'
            ELSE 'Unknown Status'
            END AS 'Last Run Status'*/
        FROM msdb.dbo.sysjobs		AS job
        LEFT JOIN msdb.dbo.sysjobhistory AS jhist 
        ON   job.job_id    = jhist.job_id 
        -- AND  jhist.step_id = 0 /* This means that the step wasn't executed */
        LEFT JOIN myCTE As sched
        ON   job.job_id = sched.job_id
        WHERE job.enabled = 1 

    END TRY
    BEGIN CATCH
        SELECT ERROR_NUMBER() AS ErrorNumber,
               ERROR_SEVERITY() AS ErrorSeverity,
               ERROR_STATE() AS ErrorState,
               ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
