/* ======================================================================================================
. Requirements Summary
	Source & Target	: Can be same or different servers.
	Output			: T-SQL scripts only, to recreate jobs elsewhere.
	Job Components	: Include steps, schedules, alerts, notifications, owner (preserve login name).
	Job History		: Not need it.
	Parameter		: @Mode with values 'ALL', 'ENABLED', 'DISABLED'.
						@Mode			NVARCHAR(10)  = 'ALL', -- 'ALL', 'ENABLED', or 'DISABLED'
						@ExportToFile	BIT			  = 0    , -- If 1, will attempt to export via BCP
															   -- If @ExportToFile = 1, each job's script will be written to a .sql file 
															   -- named: Job_<JobName>.sql.
						@FilePath		NVARCHAR(255) = NULL   -- Base folder path to export scripts, e.g., 'C:\JobScripts\'
						@SingleFileOutput BIT — optional to control whether one combined .sql file is created for all jobs.
											    When @ExportToFile = 1 and @SingleFileOutput = 1, all job scripts are saved into one .sql 
												file (All_Jobs.sql by default).

	Execution		: Can run from either server.

						EXEC dbo.sp_MigrateJobs @Mode = 'DISABLED'
						EXEC dbo.sp_MigrateJobs @Mode = 'ENABLED'
						EXEC dbo.sp_MigrateJobs @Mode = 'ALL'
						
						-- With @ExportToFile = 1
						-- e.g. 1
						EXEC sp_configure 'show advanced options', 1; RECONFIGURE;
						EXEC sp_configure 'xp_cmdshell', 1; RECONFIGURE;
						
						EXEC dbo.sp_MigrateJobs 
							@Mode = 'DISABLED', 
							@ExportToFile = 1, 
							@FilePath = '\\PWSWSQLHJPL001.client.ext\F$\Scripts\', 
							@SingleFileOutput = 1;

						-- e.g. 2
						EXEC sp_configure 'show advanced options', 1; RECONFIGURE;
						EXEC sp_configure 'xp_cmdshell', 1; RECONFIGURE;

						EXEC dbo.sp_MigrateJobs 
							@Mode = 'ALL', 
							@ExportToFile = 1, 
							@FilePath = 'C:\JobScripts\', 
							@SingleFileOutput = 1;

						-- e.g. 3
						EXEC sp_configure 'show advanced options', 1; RECONFIGURE;
						EXEC sp_configure 'xp_cmdshell', 1; RECONFIGURE;

						EXEC dbo.sp_MigrateJobs 
							@Mode = 'ENABLED', 
							@ExportToFile = 1, 
							@FilePath = 'D:\SQLJobs\', 
							@SingleFileOutput = 0;

	Output Modes	: Script in a result set and write the script to a .sql file via bcp.
					  If any job names have symbols like :, \, or /, they’ll be replaced with underscores for filenames.
	SQL Versions	: 2019 & 2022 (both supported, no deprecated features to worry about).

. Stored Procedure funcitonality
	The SP will		: Accept a @Mode parameter: 'ALL', 'ENABLED', 'DISABLED'.
					  Query msdb.dbo.sysjobs with filtering based on enabled status.
	Script			: sp_add_job, sp_add_jobstep, sp_add_schedule, sp_attach_schedule, sp_add_jobserver
	Output			:  
	Result set		: One row per job, with full script as a string.
					  Optionally call xp_cmdshell + bcp to write each script to file (if enabled).

. Security Note
	To write to file using bcp, the following must be true: xp_cmdshell must be enabled.
	SQL Server Agent or SQL user must have permissions on the file system path.
	The server should be allowed to use bcp on the OS.

====================================================================================================== */

IF OBJECT_ID('dbo.sp_MigrateJobs', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_MigrateJobs;
GO

CREATE PROCEDURE dbo.sp_MigrateJobs
    @Mode NVARCHAR(10) = 'ALL',              -- 'ALL', 'ENABLED', 'DISABLED'
    @ExportToFile BIT = 0,                   -- 1 = export scripts to file(s)
    @FilePath NVARCHAR(255) = NULL,          -- Required if ExportToFile = 1
    @SingleFileOutput BIT = 0                -- 1 = single file for all jobs
AS
BEGIN
    SET NOCOUNT ON;

    IF @Mode NOT IN ('ALL', 'ENABLED', 'DISABLED')
    BEGIN
        RAISERROR('Invalid @Mode. Use ALL, ENABLED, or DISABLED.', 16, 1);
        RETURN;
    END

    IF @ExportToFile = 1 AND @FilePath IS NULL
    BEGIN
        RAISERROR('File path must be provided when ExportToFile = 1.', 16, 1);
        RETURN;
    END

    -- Use a global temporary table instead of a local one
    CREATE TABLE ##JobScripts (
        JobName NVARCHAR(128),
        Script NVARCHAR(MAX)
    );

    DECLARE JobCursor CURSOR FOR
    SELECT j.job_id, j.name, SUSER_SNAME(j.owner_sid) AS OwnerName
    FROM msdb.dbo.sysjobs j
    WHERE (@Mode = 'ALL')
       OR (@Mode = 'ENABLED' AND j.enabled = 1)
       OR (@Mode = 'DISABLED' AND j.enabled = 0);

    DECLARE @JobId UNIQUEIDENTIFIER, @JobName NVARCHAR(128), @OwnerName NVARCHAR(128);

    OPEN JobCursor;
    FETCH NEXT FROM JobCursor INTO @JobId, @JobName, @OwnerName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @Script NVARCHAR(MAX) = '';
        DECLARE @JobNameEscaped NVARCHAR(128) = REPLACE(REPLACE(REPLACE(@JobName, '''', ''''''), '[', '[[]'), ']', '[]]');

        SET @Script += '-- ==============================================' + CHAR(13);
        SET @Script += '-- JOB: ' + @JobName + CHAR(13);
        SET @Script += '-- ==============================================' + CHAR(13);
        SET @Script += 'BEGIN TRANSACTION;' + CHAR(13) + CHAR(13);

        SET @Script += 'IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N''' + @JobNameEscaped + ''')' + CHAR(13) +
                       '    EXEC msdb.dbo.sp_delete_job @job_name = N''' + @JobNameEscaped + ''';' + CHAR(13) + CHAR(13);

        SET @Script += 'EXEC msdb.dbo.sp_add_job ' + CHAR(13) +
                       '    @job_name = N''' + @JobNameEscaped + ''',' + CHAR(13) +
                       '    @enabled = 1,' + CHAR(13) +
                       '    @owner_login_name = N''' + @OwnerName + ''';' + CHAR(13) + CHAR(13);

        -- Job steps
        SELECT @Script += 
            'EXEC msdb.dbo.sp_add_jobstep ' + CHAR(13) +
            '    @job_name = N''' + @JobNameEscaped + ''',' + CHAR(13) +
            '    @step_name = N''' + REPLACE(step_name, '''', '''''') + ''',' + CHAR(13) +
            '    @subsystem = N''' + subsystem + ''',' + CHAR(13) +
            '    @command = N''' + REPLACE(command, '''', '''''') + ''',' + CHAR(13) +
            '    @on_success_action = ' + CAST(on_success_action AS NVARCHAR) + ',' + CHAR(13) +
            '    @on_fail_action = ' + CAST(on_fail_action AS NVARCHAR) + ',' + CHAR(13) +
            '    @retry_attempts = ' + CAST(retry_attempts AS NVARCHAR) + ',' + CHAR(13) +
            '    @retry_interval = ' + CAST(retry_interval AS NVARCHAR) + ';' + CHAR(13) + CHAR(13)
        FROM msdb.dbo.sysjobsteps
        WHERE job_id = @JobId
        ORDER BY step_id;

        -- Schedules
        SELECT @Script += 
            'EXEC msdb.dbo.sp_add_schedule ' + CHAR(13) +
            '    @schedule_name = N''' + REPLACE(s.name, '''', '''''') + ''',' + CHAR(13) +
            '    @enabled = ' + CAST(s.enabled AS NVARCHAR) + ',' + CHAR(13) +
            '    @freq_type = ' + CAST(s.freq_type AS NVARCHAR) + ',' + CHAR(13) +
            '    @freq_interval = ' + CAST(s.freq_interval AS NVARCHAR) + ',' + CHAR(13) +
            '    @freq_subday_type = ' + CAST(s.freq_subday_type AS NVARCHAR) + ',' + CHAR(13) +
            '    @freq_subday_interval = ' + CAST(s.freq_subday_interval AS NVARCHAR) + ',' + CHAR(13) +
            '    @active_start_date = ' + CAST(s.active_start_date AS NVARCHAR) + ',' + CHAR(13) +
            '    @active_start_time = ' + CAST(s.active_start_time AS NVARCHAR) + ';' + CHAR(13) +

            'EXEC msdb.dbo.sp_attach_schedule ' + CHAR(13) +
            '    @job_name = N''' + @JobNameEscaped + ''',' + CHAR(13) +
            '    @schedule_name = N''' + REPLACE(s.name, '''', '''''') + ''';' + CHAR(13) + CHAR(13)
        FROM msdb.dbo.sysjobschedules js
        JOIN msdb.dbo.sysschedules s ON js.schedule_id = s.schedule_id
        WHERE js.job_id = @JobId;

        -- Notifications
        DECLARE @NotifyOperator NVARCHAR(128), @NotifyLevel INT;
        SELECT TOP 1 @NotifyOperator = o.name, @NotifyLevel = j.notify_level_email
        FROM msdb.dbo.sysjobs j
        JOIN msdb.dbo.sysoperators o ON j.notify_email_operator_id = o.id
        WHERE j.job_id = @JobId AND j.notify_level_email > 0;

        IF @NotifyOperator IS NOT NULL
        BEGIN
            SET @Script += 
                'EXEC msdb.dbo.sp_update_job ' + CHAR(13) +
                '    @job_name = N''' + @JobNameEscaped + ''',' + CHAR(13) +
                '    @notify_level_email = ' + CAST(@NotifyLevel AS NVARCHAR) + ',' + CHAR(13) +
                '    @notify_email_operator_name = N''' + @NotifyOperator + ''';' + CHAR(13) + CHAR(13);
        END

        SET @Script += 
            'EXEC msdb.dbo.sp_add_jobserver ' + CHAR(13) +
            '    @job_name = N''' + @JobNameEscaped + ''';' + CHAR(13) + CHAR(13);

        SET @Script += 'COMMIT;' + CHAR(13) + CHAR(13);

        INSERT INTO ##JobScripts (JobName, Script) VALUES (@JobName, @Script);

        FETCH NEXT FROM JobCursor INTO @JobId, @JobName, @OwnerName;
    END

    CLOSE JobCursor;
    DEALLOCATE JobCursor;

    -- Optional export
    IF @ExportToFile = 1
    BEGIN
        DECLARE @ExportCmd NVARCHAR(4000);

        IF @SingleFileOutput = 1
        BEGIN
            DECLARE @OutputFile NVARCHAR(4000) = @FilePath + 'All_Jobs.sql';
            SET @ExportCmd = 'bcp "SELECT Script FROM ##JobScripts ORDER BY JobName" queryout "' + @OutputFile + '" -c -T -S ' + @@SERVERNAME;
            PRINT @ExportCmd; -- Debugging the command
            EXEC xp_cmdshell @ExportCmd;
        END
        ELSE
        BEGIN
            -- Export each job individually
            DECLARE @ExportJobName NVARCHAR(128), @ExportSafeFile NVARCHAR(128);
            DECLARE ExportCursor CURSOR FOR SELECT JobName FROM ##JobScripts;
            OPEN ExportCursor;
            FETCH NEXT FROM ExportCursor INTO @ExportJobName;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @ExportSafeFile = REPLACE(REPLACE(REPLACE(@ExportJobName, ' ', '_'), ':', '_'), '\', '_');
                SET @ExportCmd = 'bcp "SELECT Script FROM ##JobScripts WHERE JobName = ''' + @ExportJobName + '''" queryout "' +
                                 @FilePath + 'Job_' + @ExportSafeFile + '.sql" -c -T -S ' + @@SERVERNAME;
                PRINT @ExportCmd; -- Debugging the command
                EXEC xp_cmdshell @ExportCmd;
                FETCH NEXT FROM ExportCursor INTO @ExportJobName;
            END
            CLOSE ExportCursor;
            DEALLOCATE ExportCursor;
        END
    END

	-- Show result if not exporting
    IF @ExportToFile = 0
    BEGIN
        SELECT JobName, Script FROM ##JobScripts ORDER BY JobName;
    END

    -- Clean up global temp table
    DROP TABLE IF EXISTS ##JobScripts;
END;
