USE [DBA]
GO
/*
SELECT DISTINCT 
    local_tcp_port 
FROM sys.dm_exec_connections 
WHERE local_tcp_port IS NOT NULL 
go

[dbo].[usp_GetSQLAgentInfo] @Action = 'AgentConfig'
GO
[dbo].[usp_GetSQLAgentInfo] @Action = 'TotalJobCount'
*/

/****** Object:  StoredProcedure [dbo].[usp_GetSQLAgentInfo]    Script Date: 2/5/2025 12:16:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[usp_GetSQLAgentInfo]
	@Help	 TINYINT    = 0,
    @Action  VARCHAR(50)= NULL,
    @JobName SYSNAME    = NULL
AS
BEGIN

    SET NOCOUNT ON;
	
	DECLARE @Mirroring		BIT = 0, 
			@LogShipping	BIT = 0, 
			@Replication	BIT = 0, 
			@Clustering		BIT = 0, 
			@AlwaysOn		BIT = 0;
			
	-- Show Help
	IF @Help = 1 
	BEGIN
	PRINT '
	/*
	This script checks works with the SQL Server Agent executing the task that you request.
	You can check:
		1. 

	Parameter explanations:

	@Helpt = 1. Return info from the SP

	*/';
	RETURN;
	END;    /* @Help = 1 */	
    
	-- Execute @Help if all parameters are NULL
	IF (@Help = 0 and @Action is null and @JobName is null)
	BEGIN
	PRINT '
	/*
	This script checks works with the SQL Server Agent executing the task that you request.
	You can check:
		1. 

	Parameter explanations:

	@Helpt = 1. Return info from the SP

	*/';
	RETURN;	
	END;
	
	BEGIN TRY

		-- Inline DaysOfWeekDecoder logic using a Table Variable or CTE
        DECLARE @DaysOfWeek TABLE ([Freq_Interval] INT, [DayName] VARCHAR(20));

		-- Inert data to temp @DaysOfWeek table
        INSERT INTO @DaysOfWeek (Freq_Interval, DayName)
        VALUES 
            (1, 'Sunday'), (2, 'Monday'), (4, 'Tuesday'), 
            (8, 'Wednesday'), (16, 'Thursday'), (32, 'Friday'), (64, 'Saturday');

        -- Agent Enabled Status
        IF @Action = 'AgentStatus'
        BEGIN
			SELECT /*dss.[status],*/ DMSS.[ServiceName], DMSS.[status_desc] AS AgentStatus ,*
			FROM   SYS.DM_SERVER_SERVICES DMSS
			WHERE  DMSS.[ServiceName] LIKE N'SQL Server Agent (%';
        END

        -- SQL Agent Configuration
        ELSE IF @Action = 'AgentConfig'
        BEGIN
			/* RESULT 1 */
            SELECT DMSS.[Startup_Type_Desc], DMSS.[last_startup_time], DMSS.[service_account], DMSS.[filename], DMSS.[is_clustered], DMSS.[cluster_nodename]
			FROM   SYS.DM_SERVER_SERVICES DMSS
			WHERE  DMSS.[ServiceName] LIKE N'SQL Server Agent (%';

			/* RESULT 2 */
			SELECT name, value, value_in_use, description FROM sys.configurations
            WHERE name IN ('Agent XPs', 'Database Mail XPs', 'Show Advanced Options');
        
			/* RESULT 3 */
			-- Check for Mirroring
			IF EXISTS (SELECT 1 FROM sys.database_mirroring WHERE mirroring_guid IS NOT NULL)
				SET @Mirroring = 1;

			-- Check for Log Shipping (Primary or Secondary databases)
			IF EXISTS (SELECT 1 FROM msdb.dbo.log_shipping_primary_databases)
				OR EXISTS (SELECT 1 FROM msdb.dbo.log_shipping_secondary_databases)
				SET @LogShipping = 1;

			-- Check for Replication
			IF EXISTS (SELECT 1 FROM master.sys.databases where is_published = 1 OR is_subscribed = 1 OR is_distributor = 1)
				SET @Replication = 1;
		
			-- Check for Failover Clustering
			IF EXISTS (SELECT 1 FROM sys.dm_os_cluster_nodes)
				SET @Clustering = 1;

			-- Check for Always On Availability Groups
			IF EXISTS (SELECT 1 FROM sys.dm_hadr_availability_group_states)
				OR EXISTS (SELECT 1 FROM sys.availability_groups)
				SET @AlwaysOn = 1;

			-- Return final result (1 if any feature is enabled, 0 otherwise)
			SELECT CASE WHEN @Mirroring		= 1 THEN 'YES' ELSE 'NO' END AS [Mirroring],
				   CASE WHEN @LogShipping	= 1 THEN 'YES' ELSE 'NO' END AS [LogShipping],
				   CASE WHEN @Replication	= 1 THEN 'YES' ELSE 'NO' END AS [Replication],
				   CASE WHEN @Clustering	= 1 THEN 'YES' ELSE 'NO' END AS [Clustering],
				   CASE WHEN @AlwaysOn		= 1 THEN 'YES' ELSE 'NO' END AS [AlwaysOn];
		END
		
        -- Count of Jobs
        ELSE IF @Action = 'TotalJobCount'
        BEGIN
			SELECT 
				COUNT(*) AS TotalJobs,
				COUNT(CASE WHEN enabled = 1 THEN 1 END) AS TotalJobsEnabled,
				COUNT(CASE WHEN enabled = 0 THEN 1 END) AS TotalJobsDisabled
			FROM msdb.dbo.sysjobs;
        END
		
        -- List All Job Names
        ELSE IF @Action = 'JobList'
        BEGIN
            SELECT name AS JobName FROM msdb.dbo.sysjobs;
        END
        
        -- Status of a Single Job
        ELSE IF @Action = 'JobStatus' AND @JobName IS NOT NULL
        BEGIN
            SELECT [name] AS JobName,
                   CASE WHEN enabled = 1 THEN 'Enabled' ELSE 'Disabled' END AS JobStatus
            FROM msdb.dbo.sysjobs
            WHERE name = @JobName;
        END
        
        -- Steps of a Single Job
        ELSE IF @Action = 'JobStep' AND @JobName IS NOT NULL
        BEGIN
			SELECT sj.name JobName, sj.enabled, sj.start_step_id, sjs.step_id, sjs.step_name, sjs.subsystem, sjs.command
				, CASE on_success_action
					WHEN 1 THEN 'Quit with success'
					WHEN 2 THEN 'Quit with failure'
					WHEN 3 THEN 'Go to next step'
					WHEN 4 THEN 'Go to step ' + CAST(on_success_step_id AS VARCHAR(3))
				  END On_Success
				, CASE on_fail_action
					WHEN 1 THEN 'Quit with success'
					WHEN 2 THEN 'Quit with failure'
					WHEN 3 THEN 'Go to next step'
					WHEN 4 THEN 'Go to step ' + CAST(on_fail_step_id AS VARCHAR(3))
				  END On_Failure
			FROM msdb.dbo.sysjobs sj
			JOIN msdb.dbo.sysjobsteps sjs ON sj.job_id = sjs.job_id
			WHERE sj.name = @JobName
			ORDER BY sj.name, sjs.step_id
		END

        -- Steps of all Jobs
        ELSE IF @Action = 'JobStep'
        BEGIN
			SELECT sj.name JobName, sj.enabled, sj.start_step_id, sjs.step_id, sjs.step_name, sjs.subsystem, sjs.command
				, CASE on_success_action
					WHEN 1 THEN 'Quit with success'
					WHEN 2 THEN 'Quit with failure'
					WHEN 3 THEN 'Go to next step'
					WHEN 4 THEN 'Go to step ' + CAST(on_success_step_id AS VARCHAR(3))
				  END On_Success
				, CASE on_fail_action
					WHEN 1 THEN 'Quit with success'
					WHEN 2 THEN 'Quit with failure'
					WHEN 3 THEN 'Go to next step'
					WHEN 4 THEN 'Go to step ' + CAST(on_fail_step_id AS VARCHAR(3))
				  END On_Failure
			FROM msdb.dbo.sysjobs sj
			JOIN msdb.dbo.sysjobsteps sjs ON sj.job_id = sjs.job_id
			ORDER BY sj.name, sjs.step_id
		END


        -- Status of All Jobs
        ELSE IF @Action = 'AllJobStatus'
        BEGIN
            SELECT name AS JobName,
                   CASE WHEN enabled = 1 THEN 'Enabled' ELSE 'Disabled' END AS JobStatus
            FROM msdb.dbo.sysjobs;
        END
        
        -- Job Schedule (Single Job)
        ELSE IF @Action = 'JobSchedule' AND @JobName IS NOT NULL
        BEGIN
			SELECT 
			  j.name AS JobName /*, s.schedule_id*/, s.name AS ScheduleName, s.enabled AS Status
			, CASE s.freq_type
				WHEN 1   THEN 'One time only'
				WHEN 4   THEN 'Daily'
				WHEN 8   THEN 'Weekly'
				WHEN 16  THEN 'Monthly'
				WHEN 32  THEN 'Monthly'
				WHEN 64  THEN 'Runs when the SQL Server Agent service starts'
				WHEN 128 THEN 'Runs when the computer is idle'
			  END AS FrequencyType
			, CASE WHEN s.freq_type = 32 AND s.freq_relative_interval <> 0 THEN 
				CASE s.freq_relative_interval 
				  WHEN 1  THEN 'First'
				  WHEN 2  THEN 'Second'
				  WHEN 4  THEN 'Third'
				  WHEN 8  THEN 'Fourth'
				  WHEN 16 THEN 'Last'
				END
				ELSE 'UNUSED' 
			  END Interval
			, CASE s.freq_type
				WHEN 1   THEN 'UNUSED'
				WHEN 4   THEN 'Every ' + CAST(s.freq_interval AS VARCHAR(3)) + ' Day(s)'
				-- WHEN 8   THEN dbo.DaysOfWeekDecoder(freq_interval)
				WHEN 8   THEN (SELECT DayName FROM @DaysOfWeek WHERE [Freq_Interval] = s.freq_interval)
				WHEN 16  THEN 'On day ' + CAST(s.freq_interval AS VARCHAR(3)) + ' of the month.'
				WHEN 32  THEN CASE s.freq_interval
								WHEN 1  THEN 'Sunday'
								WHEN 2  THEN 'Monday'
								WHEN 3  THEN 'Tuesday'
								WHEN 4  THEN 'Wednesday'
								WHEN 5  THEN 'Thursday'
								WHEN 6  THEN 'Friday'
								WHEN 7  THEN 'Saturday'
								WHEN 8  THEN 'Day'
								WHEN 9  THEN 'Weekday'
								WHEN 10 THEN 'Weekend day'
							  END
				WHEN 64  THEN 'UNUSED'
				WHEN 128 THEN 'UNUSED'
			  END Frequency
			, CASE WHEN s.freq_subday_interval <> 0 THEN 
				CASE s.freq_subday_type
				  WHEN 1 THEN 'At ' + CAST(s.freq_subday_interval AS VARCHAR(3))
				  WHEN 2 THEN 'Repeat every ' + CAST(s.freq_subday_interval  AS VARCHAR(3)) + ' Seconds'
				  WHEN 4 THEN 'Repeat every ' + CAST(s.freq_subday_interval  AS VARCHAR(3)) + ' Minutes'
				  WHEN 8 THEN 'Repeat every ' + CAST(s.freq_subday_interval  AS VARCHAR(3)) + ' Hours'
				END 
				ELSE 'UNUSED'
			  END FrequencyDetail
			, CASE 
				WHEN s.freq_type = 8 THEN 'Repeat every ' + CAST(s.freq_recurrence_factor AS VARCHAR(3)) + ' week(s).'
				WHEN s.freq_type IN (16,32)      THEN 'Repeat every ' + CAST(s.freq_recurrence_factor AS VARCHAR(3)) + ' month(s).'
				ELSE 'UNUSED'
			  END Interval2
			, STUFF(STUFF(RIGHT('00000' + CAST(s.active_start_time AS VARCHAR(6)),6),3,0,':'),6,0,':')StartTime
			, STUFF(STUFF(RIGHT('00000' + CAST(s.active_end_time AS VARCHAR(6)),6),3,0,':'),6,0,':') EndTime
			FROM msdb.dbo.sysschedules s
			JOIN msdb.dbo.sysjobschedules js 
			ON s.schedule_id = js.schedule_id
			JOIN msdb.dbo.sysjobs j 
			ON js.job_id = j.job_id
			WHERE j.name = @JobName
        END
        
        -- Job Schedule (All Jobs)
        ELSE IF @Action = 'AllJobSchedules'
        BEGIN
			SELECT 
			  j.name AS JobName /*, s.schedule_id*/, s.name AS ScheduleName, s.enabled AS Status
			, CASE s.freq_type
				WHEN 1   THEN 'One time only'
				WHEN 4   THEN 'Daily'
				WHEN 8   THEN 'Weekly'
				WHEN 16  THEN 'Monthly'
				WHEN 32  THEN 'Monthly'
				WHEN 64  THEN 'Runs when the SQL Server Agent service starts'
				WHEN 128 THEN 'Runs when the computer is idle'
			  END AS FrequencyType
			, CASE WHEN s.freq_type = 32 AND s.freq_relative_interval <> 0 THEN 
				CASE s.freq_relative_interval 
				  WHEN 1  THEN 'First'
				  WHEN 2  THEN 'Second'
				  WHEN 4  THEN 'Third'
				  WHEN 8  THEN 'Fourth'
				  WHEN 16 THEN 'Last'
				END
				ELSE 'UNUSED' 
			  END Interval
			, CASE s.freq_type
				WHEN 1   THEN 'UNUSED'
				WHEN 4   THEN 'Every ' + CAST(s.freq_interval AS VARCHAR(3)) + ' Day(s)'
				-- WHEN 8   THEN dbo.DaysOfWeekDecoder(freq_interval)
				WHEN 8   THEN (SELECT DayName FROM @DaysOfWeek WHERE [Freq_Interval] = s.freq_interval)
				WHEN 16  THEN 'On day ' + CAST(s.freq_interval AS VARCHAR(3)) + ' of the month.'
				WHEN 32  THEN CASE s.freq_interval
								WHEN 1  THEN 'Sunday'
								WHEN 2  THEN 'Monday'
								WHEN 3  THEN 'Tuesday'
								WHEN 4  THEN 'Wednesday'
								WHEN 5  THEN 'Thursday'
								WHEN 6  THEN 'Friday'
								WHEN 7  THEN 'Saturday'
								WHEN 8  THEN 'Day'
								WHEN 9  THEN 'Weekday'
								WHEN 10 THEN 'Weekend day'
							  END
				WHEN 64  THEN 'UNUSED'
				WHEN 128 THEN 'UNUSED'
			  END Frequency
			, CASE WHEN s.freq_subday_interval <> 0 THEN 
				CASE s.freq_subday_type
				  WHEN 1 THEN 'At ' + CAST(s.freq_subday_interval AS VARCHAR(3))
				  WHEN 2 THEN 'Repeat every ' + CAST(s.freq_subday_interval  AS VARCHAR(3)) + ' Seconds'
				  WHEN 4 THEN 'Repeat every ' + CAST(s.freq_subday_interval  AS VARCHAR(3)) + ' Minutes'
				  WHEN 8 THEN 'Repeat every ' + CAST(s.freq_subday_interval  AS VARCHAR(3)) + ' Hours'
				END 
				ELSE 'UNUSED'
			  END FrequencyDetail
			, CASE 
				WHEN s.freq_type = 8 THEN 'Repeat every ' + CAST(s.freq_recurrence_factor AS VARCHAR(3)) + ' week(s).'
				WHEN s.freq_type IN (16,32)      THEN 'Repeat every ' + CAST(s.freq_recurrence_factor AS VARCHAR(3)) + ' month(s).'
				ELSE 'UNUSED'
			  END Interval2
			, STUFF(STUFF(RIGHT('00000' + CAST(s.active_start_time AS VARCHAR(6)),6),3,0,':'),6,0,':')StartTime
			, STUFF(STUFF(RIGHT('00000' + CAST(s.active_end_time AS VARCHAR(6)),6),3,0,':'),6,0,':') EndTime
			FROM msdb.dbo.sysschedules s
			JOIN msdb.dbo.sysjobschedules js 
			ON s.schedule_id = js.schedule_id
			JOIN msdb.dbo.sysjobs j 
			ON js.job_id = j.job_id
        END
        
        -- Job History (Single Job)
        ELSE IF @Action = 'JobHistory' AND @JobName IS NOT NULL
        BEGIN
            SELECT j.name AS JobName, h.run_date, h.run_time, h.run_status, h.message
            FROM msdb.dbo.sysjobs j
            JOIN msdb.dbo.sysjobhistory h ON j.job_id = h.job_id
            WHERE j.name = @JobName
            ORDER BY h.run_date DESC, h.run_time DESC;
        END
        
        -- Job History (All Jobs)
        ELSE IF @Action = 'AllJobHistories'
        BEGIN
            SELECT j.name AS JobName, h.run_date, h.run_time, h.run_status, h.message
            FROM msdb.dbo.sysjobs j
            JOIN msdb.dbo.sysjobhistory h ON j.job_id = h.job_id
            ORDER BY j.name, h.run_date DESC, h.run_time DESC;
        END

        ELSE
        BEGIN
            RAISERROR('Invalid @Action parameter provided.', 16, 1);
        END

    END TRY
    BEGIN CATCH
        SELECT ERROR_NUMBER() AS ErrorNumber,
               ERROR_SEVERITY() AS ErrorSeverity,
               ERROR_STATE() AS ErrorState,
               ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
