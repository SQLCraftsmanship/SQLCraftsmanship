<#
written by 
 James.Ferebee@microsoft.com
 PijoCoder @github.com

.SYNOPSIS
  Test Powershell script to create task in Windows Task Scheduler to invoke SQL LogScout.
.LINK 
  https://github.com/microsoft/sql_logscout
.EXAMPLE
  .\ScheduleSQLLogScoutAsTask.ps1 -LogScoutPath "C:\temp\log scout\Test 2" -Scenario "GeneralPerf" -SQLInstance "Server1\sqlinst1" 
  -OutputPath "C:\temp\log scout\test 2" -CmdTaskName "First SQLLogScout Capture" -DeleteFolderOrNew "DeleteDefaultFolder" 
  -StartTime "2022-08-24 08:26:00" -DurationInMins 10 -Once 
#> 

param
(
    #Implement params to have the script accept parameters which is then provided to Windows Task Scheduler logscout command
    #LogScout path directory
    [Parameter(Position=0)]
    [string] $LogScoutPath, 

    #GeneralPerf, etc.
    [Parameter(Position=1, Mandatory=$true)]
    [string] $Scenario,

    #Connection string into SQL.
    [Parameter(Position=2, Mandatory=$true)]
    [string] $SQLInstance,

    #Whether to use custom path or not
    [Parameter(Position=3, Mandatory=$false)]
    #We are in bin, but have the output file write to the root logscout folder.
    [string] $OutputPath = (Get-Item (Get-Location)).Parent.FullName,

    #Name of the Task. Use a unique name to create multiple scheduled runs. Defaults to "SQL LogScout Task" if omitted.
    [Parameter(Position=4, Mandatory=$false)]
    [string] $CmdTaskName = "SQL LogScout Task",
    
    #Delete existing folder or create new one.
    [Parameter(Position=5, Mandatory=$true)]
    [string] $DeleteFolderOrNew,

    #Start time of collector. 2022-09-29 21:26:00
    [Parameter(Position=6,Mandatory=$true)]
    [datetime] $StartTime,
    
    #How long to execute the collector. In minutes.
    [Parameter(Position=7,Mandatory=$true)]
    [double] $DurationInMins,

    #schedule it for one execution
    [Parameter(Position=8, Mandatory=$false)]
    [switch] $Once = $false,

    #schedule it daily at the specified time
    [Parameter(Position=9, Mandatory=$false)]
    [switch] $Daily = $false,

    #schedule it daily at the specified time
    [Parameter(Position=10, Mandatory=$false)]
    [nullable[boolean]] $CreateCleanupJob = $null,

    #schedule it daily at the specified time
    [Parameter(Position=11, Mandatory=$false)]
    [nullable[datetime]] $CleanupJobTime = $null,

    #schedule it daily at the specified time
    [Parameter(Position=12, Mandatory=$false)]
    [string] $LogonType = $null

    #Later add switch to auto-delete task if it already exists

    #for future scenarios
    #[Parameter(Position=9)]
    #[timespan] $RepetitionDuration, 

    #[Parameter(Position=10)]
    #[timespan] $RepetitionInterval

)




################ Globals ################

[string]$global:CurrentUserAccount = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

################ Import Modules for Shared Functions ################



################ Functions ################
function HandleCatchBlock ([string] $function_name, [System.Management.Automation.ErrorRecord] $err_rec, [bool]$exit_logscout = $false)
<#
    .DESCRIPTION
        error handling
#>  
{
    $error_msg = $err_rec.Exception.Message
    $error_linenum = $err_rec.InvocationInfo.ScriptLineNumber
    $error_offset = $err_rec.InvocationInfo.OffsetInLine
    $error_script = $err_rec.InvocationInfo.ScriptName
    Log-ScheduledTask -Message "'$function_name' failed with error:  $error_msg (line: $error_linenum, offset: $error_offset, file: $error_script)" -WriteToConsole $true -ConsoleMsgColor "Red"
}


function Initialize-ScheduledTaskLog
    (
        [string]$LogFilePath = $env:TEMP,
        [string]$LogFileName = "##SQLLogScout_ScheduledTask"
    )
{
<#
    .DESCRIPTION
        Initialize-ScheduledTaskLog creates the log file specific for scheduled tasks in the desired directory. 
        Logging to console is also written to the persisted file on disk.

#>    
    try
    {
        #Cache LogFileName withotu date so we can delete old records properly
        $LogFileNameStringToDelete = $LogFileName

        #update file with date
        $LogFileName = ($LogFileName -replace "##SQLLogScout_ScheduledTask", ("##SQLLogScout_ScheduledTask_" + @(Get-Date -Format  "yyyyMMddTHHmmssffff") + ".log"))
        $global:ScheduledTaskLog = $LogFilePath + '\' + $LogFileName
        New-Item -ItemType "file" -Path $global:ScheduledTaskLog -Force | Out-Null
        $CurrentTime = (Get-Date -Format("yyyy-MM-dd HH:MM:ss.ms"))
        Write-Host "$CurrentTime : Created log file $global:ScheduledTaskLog"
        $CurrentTime = (Get-Date -Format("yyyy-MM-dd HH:MM:ss.ms"))
        Write-Host "$CurrentTime : Log initialization complete!"

        #Array to store the old files in temp directory that we then delete and use the non-date value as the string to find.
        $FilesToDelete = @(Get-ChildItem -Path ($LogFilePath) | Where-Object {$_.Name -match $LogFileNameStringToDelete} | Sort-Object -Property LastWriteTime -Descending | Select-Object -Skip 10)
        $NumFilesToDelete = $FilesToDelete.Count

        Log-ScheduledTask -Message "Found $NumFilesToDelete older SQL LogScout Scheduled Task Logs"

        # if we have files to delete
        if ($NumFilesToDelete -gt 0) 
        {
            foreach ($elem in $FilesToDelete)
            {
                $FullFileName = $elem.FullName
                Log-ScheduledTask -Message "Attempting to remove file: $FullFileName"
                Remove-Item -Path $FullFileName
            }
        }


    }
    catch
    {
		#Write-Error -Exception $_.Exception
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem  -exit_logscout $true
    }

}

function Log-ScheduledTask 
    
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Message,
        [Parameter(Mandatory=$false, Position=1)]
        [bool]$WriteToConsole = $false,
        [Parameter(Mandatory=$false, Position=2)]
        [System.ConsoleColor]$ConsoleMsgColor = [System.ConsoleColor]::White
    )  
{
<#
    .DESCRIPTION
        Appends messages to the persisted log and also returns output to console if flagged.

#>


    try 
    {
        #Add timestamp
        [string]$Message = (Get-Date -Format("yyyy-MM-dd HH:MM:ss.ms")) + ': '+ $Message
        #if we want to write to console, we can provide that parameter and optionally a color as well.
        if ($true -eq $WriteToConsole)
        {
            if ($ConsoleMsgColor -ine $null -or $ConsoleMsgColor -ine "") 
            {
                Write-Host -Object $Message -ForegroundColor $ConsoleMsgColor
            }
            else 
            {
                #Return message to console with provided color.
                Write-Host -Object $Message
            }
        }        
        #Log to file in $env:temp
        Add-Content -Path $global:ScheduledTaskLog -Value $Message | Out-Null
    }
    catch 
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem  -exit_logscout $true
    }
}


################ Log initialization ################
Initialize-ScheduledTaskLog

Log-ScheduledTask -Message "Creating SQL Scout as Task" -WriteToConsole $true -ConsoleMsgColor "Green"


################ Validate parameters and date ################
try 
#later add check to make sure sql_logscout exists in directory.
{
    #Logscout Path Logic
    if ($true -ieq [string]::IsNullOrEmpty($LogScoutPath))
    {
        #Since logscout is not in bin, we need to back out one directory to execute logscout
        $CurrentDir = Get-Location 
        [string]$LogScoutPath = (Get-Item $CurrentDir).parent.FullName
    }
    #validate the folder
    if ((Test-Path $LogScoutPath) -ieq $true)
    {   
        #trim a trailing backslash if one was provided. otherwise the job would fail
        if ($LogScoutPath.Substring($LogScoutPath.Length -1) -eq "`\")
        {
            $LogScoutPath = $LogScoutPath.Substring(0,$LogScoutPath.Length -1)
        }
    }


    #Make sure characters are permitted
    $disallowed_characters = @("\\","/",":","\*","\?",'"',"<",">","\|")
    foreach ($disallowed_characters in $disallowed_characters)
    {
        if ($CmdTaskName -match $disallowed_characters)
        { 
            Log-ScheduledTask -Message "ERROR: Task Name cannot contain wildcard characters. Disallowed characters: $disallowed_characters. Exiting..." -WriteToConsole $true -ConsoleMsgColor "Red"
            Start-Sleep -Seconds 4
            exit
        }
    }
    
    #Verify provided date for logscout is in the future
    [DateTime] $CurrentTime = Get-Date
    if ($CurrentTime -gt $StartTime)
    {
        Log-ScheduledTask -Message "ERROR: Date or time provided is in the past. Please provide a future date/time. Exiting..." -WriteToConsole $true -ConsoleMsgColor "Red"
        Start-Sleep -Seconds 4
        exit
    }

    #Verify parameter passed
    if (($LogonType -ne "S4U") -and ($LogonType -ne "Interactive") -and ([string]::IsNullOrEmpty($LogonType) -ne $true))
    {
        Log-ScheduledTask -Message "ERROR: LogonType was provided and is not S4U or Interactive. Exiting..." -WriteToConsole $true -ConsoleMsgColor "Red"
        Start-Sleep -Seconds 4
        exit
    }

    ###Cleanup Job Parameter Validation###
    #Verify cleanup job date provided is in the future

    if ($CreateCleanupJob -ieq $true) 
    {
        if ($null -ne $CleanupJobTime) 
        {
            #Get duration of logscout and cleanup 
            $timediff = New-TimeSpan -Start $StartTime -End $CleanupJobTime

            #If cleanup job is set to run in the past, throw error.
            if ($CurrentTime -gt $CleanupJobTime)
            {
                Log-ScheduledTask -Message "ERROR: Cleanup Job Time Date or time provided is in the past. Please provide a future date/time. Exiting..." -WriteToConsole $true -ConsoleMsgColor "Red"
                Start-Sleep -Seconds 4
                exit
            }

            #Verify job is to be running once and that cleanupjobtime is after invocation start.
            if ($StartTime -ige $CleanupJobTime)
            {
                Log-ScheduledTask -Message "ERROR: Logscout configured to run after cleanup. Please correct the execution times. Exiting..." -WriteToConsole $true -ConsoleMsgColor "Red"
                Start-Sleep -Seconds 4
                exit
            }

            #Get minutes between cleanup job and current time. If less than 5, throw error so logscout has some time to shut down.
            elseif ($timediff.TotalMinutes -le "5")
            {
                Log-ScheduledTask -Message "ERROR: CleanupJobTime parameter was provided but is within 5 minutes of LogScout start time. Please provide a value greater than 5 minutes. Exiting.." -WriteToConsole $true -ConsoleMsgColor "Red"
                Start-Sleep -Seconds 4
                exit
            }

            #For once executions, verify cleanup job HH:mm is different than start as we could spin them up at the same time.
            if ($Daily -ieq $true -and (($StartTime.Hour -ieq $CleanupJobTime.Hour) -and ($StartTime.Minute -ieq $CleanupJobTime.Minute)))
            {
                Log-ScheduledTask -Message "ERROR: Logscout configured to run daily and cleanup job set to run at the same hour and minute. Please update the cleanup job to run at a different time. Exiting..." -WriteToConsole $true -ConsoleMsgColor "Red"
                Start-Sleep -Seconds 4
                exit
            }

            else
            {
                Log-ScheduledTask -Message "Cleanup Parameter Validation Passed"
            }

        }
        else 
        {
            #CreateCleanupJob is true, but CleanupJobTime is null. Exit.
            Log-ScheduledTask -Message "ERROR: CreateCleanupJob provided as true but CleanupJobTime omitted. Provide both parameters or neither. Exiting..." -WriteToConsole $true -ConsoleMsgColor "Red"
            Start-Sleep -Seconds 4
            exit
        }
        
    }

    ###/Cleanup Job Parameter Validation###

    else
    {
        Log-ScheduledTask -Message "CreateCleanupJob not provided. No validation performed on CleanupJobTime."
    }

        

    #Calculate stoptime based on minutes provided to determine end time of LogScout
    if ($DurationInMins-lt 1)
    {
        $DurationInMins = 1
    }

    [datetime] $time = $StartTime
    [datetime] $endtime = $time.AddMinutes($DurationInMins)

    Log-ScheduledTask -Message "Based on starttime $StartTime and duration $DurationInMins minute(s), the end time is $endtime" 

    

    #Output path check
    if (([string]::IsNullOrEmpty($OutputPath) -ieq $true) -or ($OutputPath -ieq 'UsePresentDir') )
    {
        $OutputPath = 'UsePresentDir'
    }
    else
    {
        $validpath = Test-Path $OutputPath

        #if $OutputPath is valid use it, otherwise, throw an exception
        if ($validpath -ieq $false)
        {
            Log-ScheduledTask -Message "ERROR: Invalid directory provided as SQL LogScout Output folder. Please correct and re-run. Exiting..." -WriteToConsole $true -ConsoleMsgColor "Red"
            Start-Sleep -Seconds 4
            exit
        }

        #trim a trailing backslash if one was provided. otherwise the job would fail
        if ($OutputPath.Substring($OutputPath.Length -1) -eq "`\")
        {
            $OutputPath = $OutputPath.Substring(0,$OutputPath.Length -1)
        }

    }

    #Whether to delete the existing folder or use new folder with incremental date_time in the name
    #If left blank or null, default behavior is DeleteDefaultFolder
    if ([string]::IsNullOrEmpty($DeleteFolderOrNew) -ieq $true)
    {
        $DeleteFolderOrNew = 'DeleteDefaultFolder'
    }

    elseif ($DeleteFolderOrNew -ieq 'DeleteDefaultFolder')
    {    
        $DeleteFolderOrNew = 'DeleteDefaultFolder'
    }

    elseif ($DeleteFolderOrNew -ieq 'NewCustomFolder')
    {    
        $DeleteFolderOrNew = 'NewCustomFolder'
    }

    else
    {
        Log-ScheduledTask -Message "ERROR: Please specify a valid parameter for DeleteFolderOrNew. Exiting..." -WriteToConsole $true -ConsoleMsgColor "Red"
        exit
    }
    

    #define the schedule (execution time) - either run it one time (Once) or every day at the same time (Daily)
    #Verify both Once and Daily aren't provided. If so, exit.
    if ($Once -ieq $true -and $Daily -ieq $true)
    {
        Log-ScheduledTask -Message "ERROR: Both Once and Daily switches used in command. Please use only one. Exiting..." -WriteToConsole $true -ConsoleMsgColor "Red"
        Start-Sleep -Seconds 4
        exit
    }

    #Verify both Once and Daily aren't omitted. If so, exit.
    if ($Once -ieq $false -and $Daily -ieq $false)
    {
        Log-ScheduledTask -Message "ERROR: Once and Daily not provided. Please provide either Once or Daily to command. Exiting..." -WriteToConsole $true -ConsoleMsgColor "Red"
        Start-Sleep -Seconds 4
        exit
    }
    if ($Once -ieq  $true)
    {
        $trigger = New-ScheduledTaskTrigger -Once -At $StartTime
    }
    elseif ($Daily -ieq $true) 
    {
        #Convert date/time of starttime to different format to prevent skipping a day in collection.'2022-08-24 08:26:00' becomes 8:26:00 AM
        $DailyTimeFormat = Get-Date $StartTime -DisplayHint Time

        $trigger = New-ScheduledTaskTrigger -Daily -At $DailyTimeFormat 
    }
    else 
    {
        Log-ScheduledTask -Message "ERROR: Please specify either '-Once' or '-Daily' parameter (but not both). Exiting..." -WriteToConsole $true -ConsoleMsgColor "Red"
        Start-Sleep -Seconds 4
        exit
    }

    

    ################ Verify Not Duplicated Job ################
    #After all the checks above, we can now see if scheduled SQL LogScout task already exists, exit or prompt for delete
    $LogScoutScheduleTaskExists = Get-ScheduledTask -TaskName $CmdTaskName -ErrorAction SilentlyContinue
    $CleanupTaskName = "SQL LogScout Cleanup Task for '" + $CmdTaskName + "'"
    $LogScoutCleanupScheduleTaskExists = Get-ScheduledTask -TaskName $CleanupTaskName  -ErrorAction SilentlyContinue

    if ($LogScoutScheduleTaskExists)
    {
        Log-ScheduledTask -Message "SQL Logscout task already exists. Would you like to delete associated tasks and continue? Provide Y or N." -WriteToConsole $true -ConsoleMsgColor "Yellow"
        
        $delete_task = $null

        while ( ($delete_task -ne "Y") -and ($delete_task -ne "N") )
        {
            $delete_task = Read-Host "Delete existing SQL LogScout task (Y/N)?"

            $delete_task = $delete_task.ToString().ToUpper()
            if ( ($delete_task -ne "Y") -and ($delete_task -ne "N"))
            {
                Write-Host "Please provide 'Y' or 'N' to proceed"
            }
        }
    
        

        if ($delete_task -ieq 'N')
        {
            Log-ScheduledTask -Message "ERROR: Please review and delete existing task manually if you wish to re-run. Exiting..." -WriteToConsole $true -ConsoleMsgColor "Red"
            Start-Sleep -Seconds 4
            exit
        }
        else 
        {
            Unregister-ScheduledTask -TaskName $CmdTaskName -Confirm:$false
        }

     
    }

    #If cleanup task exists for provided input, remove it
    if ($LogScoutCleanupScheduleTaskExists)
    {
        Log-ScheduledTask -Message "SQL Logscout *Cleanup* task already exists. Removing the task." -WriteToConsole $true -ConsoleMsgColor "Yellow"
        Unregister-ScheduledTask -TaskName $CleanupTaskName -Confirm:$false
    }


    Log-ScheduledTask -Message "Logon type before prompt $LogonType" -WriteToConsole $false

    ################ Prompt User Credentials ################
    if ([string]::IsNullOrEmpty($LogonType) -eq $true)
    {
        Log-ScheduledTask -Message "Will your account be logged in when the task executes" -WriteToConsole $true -ConsoleMsgColor "Green"
        Log-ScheduledTask -Message "(this includes logged in with screen locked)?" -WriteToConsole $true -ConsoleMsgColor "Green"
        Log-ScheduledTask -Message "------------------------" -WriteToConsole $true
        Log-ScheduledTask -Message "Provide Y or N." -WriteToConsole $true -ConsoleMsgColor "Yellow"
        
        [string]$set_logintype = $null

        while ( ($set_logintype -ne "Y") -and ($set_logintype -ne "N") )
        {
            $set_logintype  = Read-Host "Will you be logged in when running the job? Provide 'Y' or 'N'"

            $set_logintype  = $set_logintype.ToString().ToUpper()
            if ( ($set_logintype -ne "Y") -and ($set_logintype -ne "N"))
            {
                Write-Host "Please provide 'Y' or 'N' to proceed"
            }
        }
        $LogonType = $set_logintype
        Log-ScheduledTask -Message "Logon type returned after prompt is $LogonType" -WriteToConsole $false
    }

       
    #Convert LoginType string to int for proper creation of job
    if ($LogonType.ToString().ToUpper() -eq 'N' -or $LogonType.ToString().ToUpper() -eq 'S4U')
    {
        [int]$LogonTypeInt = [int][Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.LogonTypeEnum]::S4U
    }
    elseif ($LogonType.ToString().ToUpper() -eq 'Y' -or $LogonType.ToString().ToUpper() -eq 'INTERACTIVE') 
    {
        [int]$LogonTypeInt = [int][Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.LogonTypeEnum]::Interactive
    }
    else 
    {
        Log-ScheduledTask -Message "ERROR: Unhandled LogonType parameter provided. Exiting..." -WriteToConsole $true -ConsoleMsgColor "Red"
        Start-Sleep -Seconds 4
        exit
    }


    ################ Create SQL LogScout Main Job ################
    $LogScoutPathRoot = $LogScoutPath
    $LogScoutPath = $LogScoutPath +'\SQL_LogScout.cmd'

    #CMD looks for input for -Execute as C:\SQL_LogScout_v4.5_Signed\SQL_LogScout_v4.5_Signed\SQL_LogScout.cmd
    #The start date parameter is not provided below to New-ScheduledTaskAction as the job is invoked based on the task trigger above which does take the StartTime parameter. 
    #To reduce likelihood of issue, 2000 date is hardcoded.
    $actions = (New-ScheduledTaskAction -Execute $LogScoutPath -Argument "$Scenario $SQLInstance `"$OutputPath`" `"$DeleteFolderOrNew`" `"2000-01-01`" `"$endtime`" `"Quiet`"" -WorkingDirectory "$LogScoutPathRoot")


    #Set to run whether user is logged on or not.
    $principal = New-ScheduledTaskPrincipal -UserId $global:CurrentUserAccount -LogonType $LogonTypeInt -RunLevel Highest


    $settings = New-ScheduledTaskSettingsSet -WakeToRun -AllowStartIfOnBatteries
    $task = New-ScheduledTask -Action $actions -Principal $principal -Trigger $trigger -Settings $settings
 

    #Write-Host "`nCreating '$CmdTaskName'... "
    Log-ScheduledTask -Message "Creating '$CmdTaskName'... "
    Register-ScheduledTask -TaskName $CmdTaskName -InputObject $task | Out-Null


    Log-ScheduledTask -Message "Success! Created Windows Task $CmdTaskName" -WriteToConsole $true -ConsoleMsgColor "Magenta"
    Log-ScheduledTask -Message "------------------------" -WriteToConsole $true
    
    $JobCreated = Get-ScheduledTask -TaskName $CmdTaskName | Select-Object -Property TaskName, State -ExpandProperty Actions | Select-Object TaskName, State, Execute, Arguments
    if ($null -ine $JobCreated)
    {
        foreach ($item in $JobCreated)
        {
        
            Log-ScheduledTask -Message ($item.TaskName.ToString() + " | " + $item.State.ToString() + " | " + $item.Execute.ToString() + " | " + $item.Arguments.ToString())
       
        }

    }    


    #future use: Get-ScheduledTask -TaskName $CmdTaskName | Select-Object -ExpandProperty Triggers | Select-Object -Property StartBoundary, ExecutonTimeLimit, Enabled -ExpandProperty Repetition




 ################ Create SQL LogScout Cleanup Job To Prevent Stale Windows Task Entries ################


    #If CreateCleanupJob is omitted, we can prompt user.
    if (($Once -ieq $true) -and ($null -ieq $CreateCleanupJob))
    {
        Log-ScheduledTask -Message "CreateCleanupJob omitted or provided as false"
        
        #Hardcode cleanup job running 11 hours if user didn't pass parameter. Only valid if user is using -Once.
        $CleanupDelay = '660'
            
        [datetime]$CleanupTaskExecutionTime = $StartTime.AddMinutes($CleanupDelay)
        $triggercleanup = New-ScheduledTaskTrigger -Once -At $CleanupTaskExecutionTime

        Log-ScheduledTask -Message "SQL Logscout task was created and was set to execute once." -WriteToConsole $true -ConsoleMsgColor "Green"
        Log-ScheduledTask -Message "Would you like to create a second job that will delete itself" -WriteToConsole $true -ConsoleMsgColor "Green"
        Log-ScheduledTask -Message "and the SQL LogScout task 11 hours after the provided endtime?" -WriteToConsole $true -ConsoleMsgColor "Green"
        Log-ScheduledTask -Message "------------------------" -WriteToConsole $true
        Log-ScheduledTask -Message "Provide Y or N." -WriteToConsole $true -ConsoleMsgColor "Yellow"
        
        [string]$create_delete_task = $null

        while ( ($create_delete_task -ne "Y") -and ($create_delete_task -ne "N") )
        {
            $create_delete_task  = Read-Host "Automatically delete existing task 11 hours after scheduled endtime (Y/N)?"

            $create_delete_task  = $create_delete_task.ToString().ToUpper()
            if ( ($create_delete_task  -ne "Y") -and ($create_delete_task  -ne "N"))
            {
                Write-Host "Please provide 'Y' or 'N' to proceed"
            }
        }

        if ($create_delete_task -ieq 'N')
        {
            Log-ScheduledTask -Message "You declined to automatically delete the job. Please perform manual cleanup in Task Scheduler after logs are collected." -WriteToConsole $true -ConsoleMsgColor "DarkYellow"
        }
        else 
        {
            #2 action task to delete the logscout task and the cleanup job itself to be run 11 hours later
            $actionscleanup = (New-ScheduledTaskAction -Execute schtasks.exe -Argument "/Delete /TN `"$CmdTaskName`" /F")
            $actions2cleanup = (New-ScheduledTaskAction -Execute schtasks.exe -Argument "/Delete /TN `"$CleanupTaskName`" /F")
            $principalcleanup = New-ScheduledTaskPrincipal -UserId $global:CurrentUserAccount -LogonType $LogonTypeInt -RunLevel Highest
            $settingscleanup = New-ScheduledTaskSettingsSet -WakeToRun -AllowStartIfOnBatteries
            #Actions are sequential
            $taskcleanup = New-ScheduledTask -Action $actionscleanup,$actions2cleanup -Principal $principalcleanup -Trigger $triggercleanup -Settings $settingscleanup
        
            Log-ScheduledTask -Message ("Creating " + $CleanupTaskName)
            Register-ScheduledTask -TaskName $CleanupTaskName  -InputObject $taskcleanup | Out-Null
        
        
            Log-ScheduledTask -Message "Success! Created Windows Task for SQL LogScout Cleanup ""$CleanupTaskName""" -WriteToConsole $true -ConsoleMsgColor "Magenta"
            Log-ScheduledTask -Message "------------------------" -WriteToConsole $true

            $CleanupTaskProperties = Get-ScheduledTask -TaskName $CleanupTaskName  | Select-Object -Property TaskName, State -ExpandProperty Actions | Select-Object TaskName, State, Execute, Arguments

            if ($null -ine $CleanupTaskProperties)
            {
                foreach ($item in $CleanupTaskProperties)
                {
                
                    Log-ScheduledTask -Message ($item.TaskName.ToString() + " | " + $item.State.ToString() + " | " + $item.Execute.ToString() + " | " + $item.Arguments.ToString())
            
                }
        
            }    
        }
    }
    #If set to run daily and CreateCleanupJob is null, prompt
    elseif (($Daily -ieq $true) -and ($null -ieq $CreateCleanupJob)) 
    {
        #Prompt user to delete and ask for a date/time to remove
        Log-ScheduledTask -Message "SQL Logscout task invoked to run daily." -WriteToConsole $true -ConsoleMsgColor "Green"
        Log-ScheduledTask -Message "Would you like to create a second job that will delete itself" -WriteToConsole $true -ConsoleMsgColor "Green"
        Log-ScheduledTask -Message "and the SQL LogScout task at the provided time?" -WriteToConsole $true -ConsoleMsgColor "Green"
        Log-ScheduledTask -Message "------------------------" -WriteToConsole $true
        #change time to be number of days.
        Log-ScheduledTask -Message "Enter the number of days after the start time for" -WriteToConsole $true -ConsoleMsgColor "Yellow"
        Log-ScheduledTask -Message "the cleanup job to run such as '60', or 'N'." -WriteToConsole $true -ConsoleMsgColor "Yellow"
        Log-ScheduledTask -Message "If you wish to run indefinitely, provide 'N' and perform manual cleanup." -WriteToConsole $true -ConsoleMsgColor "Yellow"
        [string]$daily_delete_task = $null

        #Check to make sure the value is a postive int or N.
        while ( ($daily_delete_task -inotmatch "^\d+$") -and ($daily_delete_task -ne "N") )
        {
            $daily_delete_task = Read-Host "Please provide response to cleanup job (NumberOfDays/N)?"

            $daily_delete_task = $daily_delete_task.ToString().ToUpper()
            if ( ($daily_delete_task -inotmatch "^\d+$") -and ($daily_delete_task -ne "N"))
            {
                Write-Host "Please provide Number of Days or 'N' to proceed"
            }
        }
        if ($daily_delete_task -ieq 'N')
        {
            Log-ScheduledTask -Message "You declined to automatically delete the job. Please perform manual cleanup in Task Scheduler after logs are collected." -WriteToConsole $true -ConsoleMsgColor "DarkYellow"
        }
        else 
        {
            $daily_delete_task = [int]$daily_delete_task
                #Calculate stoptime based on minutes provided to determine end time of LogScout
            if ($daily_delete_task -lt 1)
            {
                $daily_delete_task = 1
            }

            [datetime] $TimeForCleanup = $StartTime
            [datetime] $TimeForCleanup = $TimeForCleanup.AddDays($daily_delete_task)

            $triggercleanup = New-ScheduledTaskTrigger -Once -At $TimeForCleanup 
            
            #2 action task to delete the logscout task and the cleanup job itself to be run 11 hours later
            $actionscleanup = (New-ScheduledTaskAction -Execute schtasks.exe -Argument "/Delete /TN `"$CmdTaskName`" /F")
            $actions2cleanup = (New-ScheduledTaskAction -Execute schtasks.exe -Argument "/Delete /TN `"$CleanupTaskName`" /F")
            $principalcleanup = New-ScheduledTaskPrincipal -UserId $global:CurrentUserAccount -LogonType $LogonTypeInt -RunLevel Highest
            $settingscleanup = New-ScheduledTaskSettingsSet -WakeToRun -AllowStartIfOnBatteries
            #Actions are sequential
            $taskcleanup = New-ScheduledTask -Action $actionscleanup,$actions2cleanup -Principal $principalcleanup -Trigger $triggercleanup -Settings $settingscleanup
        
            Log-ScheduledTask -Message ("Creating " + $CleanupTaskName)
            Register-ScheduledTask -TaskName $CleanupTaskName  -InputObject $taskcleanup | Out-Null
        
        
            Log-ScheduledTask -Message "Success! Created Windows Task for SQL LogScout Cleanup ""$CleanupTaskName""" -WriteToConsole $true -ConsoleMsgColor "Magenta"
            Log-ScheduledTask -Message "------------------------" -WriteToConsole $true

            $CleanupTaskProperties = Get-ScheduledTask -TaskName $CleanupTaskName  | Select-Object -Property TaskName, State -ExpandProperty Actions | Select-Object TaskName, State, Execute, Arguments

            if ($null -ine $CleanupTaskProperties)
            {
                foreach ($item in $CleanupTaskProperties)
                {
                
                    Log-ScheduledTask -Message ($item.TaskName.ToString() + " | " + $item.State.ToString() + " | " + $item.Execute.ToString() + " | " + $item.Arguments.ToString())
               
                }
        
            }    
        }
    }


    #If user explicitly passes parameters, allows us to silently create. We check earlier that they passed the other parameters with CreateCleanupJob
    elseif ($CreateCleanupJob -ieq $true)
    {
        #user provided parameters for cleanup task, so don't prompt and just create the job.
        Log-ScheduledTask -Message "Cleanup job parameters provided. Creating cleanup task silently." -WriteToConsole $true -ConsoleMsgColor "Green"

        $triggercleanup = New-ScheduledTaskTrigger -Once -At $CleanupJobTime
        $actionscleanup = (New-ScheduledTaskAction -Execute schtasks.exe -Argument "/Delete /TN `"$CmdTaskName`" /F")
        $actions2cleanup = (New-ScheduledTaskAction -Execute schtasks.exe -Argument "/Delete /TN `"$CleanupTaskName`" /F")
        $principalcleanup = New-ScheduledTaskPrincipal -UserId $global:CurrentUserAccount -LogonType $LogonTypeInt -RunLevel Highest
        $settingscleanup = New-ScheduledTaskSettingsSet -WakeToRun -AllowStartIfOnBatteries
        #Actions are sequential
        $taskcleanup = New-ScheduledTask -Action $actionscleanup,$actions2cleanup -Principal $principalcleanup -Trigger $triggercleanup -Settings $settingscleanup

        Log-ScheduledTask -Message ("Creating " + $CleanupTaskName)
        Register-ScheduledTask -TaskName $CleanupTaskName  -InputObject $taskcleanup | Out-Null


        Log-ScheduledTask -Message "Success! Created Windows Task for SQL LogScout Cleanup ""$CleanupTaskName""" -WriteToConsole $true -ConsoleMsgColor "Magenta"
        Log-ScheduledTask -Message "------------------------" -WriteToConsole $true

        $CleanupTaskProperties = Get-ScheduledTask -TaskName $CleanupTaskName  | Select-Object -Property TaskName, State -ExpandProperty Actions | Select-Object TaskName, State, Execute, Arguments
        if ($null -ine $CleanupTaskProperties)
                {
                    foreach ($item in $CleanupTaskProperties)
                    {
                    
                        Log-ScheduledTask -Message ($item.TaskName.ToString() + " | " + $item.State.ToString() + " | " + $item.Execute.ToString() + " | " + $item.Arguments.ToString())
                
                    }
            
                }    
    }
    #If user explicitly said to not create the job, just log a message and don't create the cleanup job.
    elseif  ($CreateCleanupJob -ieq $false)
    {
        Log-ScheduledTask -Message "CreateCleanupJob provided as false. Not creating cleanup task. Please clean up Windows Task Scheudler manually." -WriteToConsole $true -ConsoleMsgColor "Yellow"
    }
    

 ################ Log Completion ################
    Log-ScheduledTask -Message "Thank you for using SQL LogScout! Exiting..." -WriteToConsole $true -ConsoleMsgColor "Green"
    Start-Sleep -Seconds 3
}

catch 
{
    HandleCatchBlock -function_name "ScheduleSQLLogScoutTask" -err_rec $PSItem
}

# SIG # Begin signature block
# MIIoPgYJKoZIhvcNAQcCoIIoLzCCKCsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBBylTKpzBI/nj2
# A9BsW+YWUUZKaI7vu3sQw5ixYgP/QqCCDYUwggYDMIID66ADAgECAhMzAAADri01
# UchTj1UdAAAAAAOuMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjMxMTE2MTkwODU5WhcNMjQxMTE0MTkwODU5WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQD0IPymNjfDEKg+YyE6SjDvJwKW1+pieqTjAY0CnOHZ1Nj5irGjNZPMlQ4HfxXG
# yAVCZcEWE4x2sZgam872R1s0+TAelOtbqFmoW4suJHAYoTHhkznNVKpscm5fZ899
# QnReZv5WtWwbD8HAFXbPPStW2JKCqPcZ54Y6wbuWV9bKtKPImqbkMcTejTgEAj82
# 6GQc6/Th66Koka8cUIvz59e/IP04DGrh9wkq2jIFvQ8EDegw1B4KyJTIs76+hmpV
# M5SwBZjRs3liOQrierkNVo11WuujB3kBf2CbPoP9MlOyyezqkMIbTRj4OHeKlamd
# WaSFhwHLJRIQpfc8sLwOSIBBAgMBAAGjggGCMIIBfjAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUhx/vdKmXhwc4WiWXbsf0I53h8T8w
# VAYDVR0RBE0wS6RJMEcxLTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJh
# dGlvbnMgTGltaXRlZDEWMBQGA1UEBRMNMjMwMDEyKzUwMTgzNjAfBgNVHSMEGDAW
# gBRIbmTlUAXTgqoXNzcitW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIw
# MTEtMDctMDguY3JsMGEGCCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDEx
# XzIwMTEtMDctMDguY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIB
# AGrJYDUS7s8o0yNprGXRXuAnRcHKxSjFmW4wclcUTYsQZkhnbMwthWM6cAYb/h2W
# 5GNKtlmj/y/CThe3y/o0EH2h+jwfU/9eJ0fK1ZO/2WD0xi777qU+a7l8KjMPdwjY
# 0tk9bYEGEZfYPRHy1AGPQVuZlG4i5ymJDsMrcIcqV8pxzsw/yk/O4y/nlOjHz4oV
# APU0br5t9tgD8E08GSDi3I6H57Ftod9w26h0MlQiOr10Xqhr5iPLS7SlQwj8HW37
# ybqsmjQpKhmWul6xiXSNGGm36GarHy4Q1egYlxhlUnk3ZKSr3QtWIo1GGL03hT57
# xzjL25fKiZQX/q+II8nuG5M0Qmjvl6Egltr4hZ3e3FQRzRHfLoNPq3ELpxbWdH8t
# Nuj0j/x9Crnfwbki8n57mJKI5JVWRWTSLmbTcDDLkTZlJLg9V1BIJwXGY3i2kR9i
# 5HsADL8YlW0gMWVSlKB1eiSlK6LmFi0rVH16dde+j5T/EaQtFz6qngN7d1lvO7uk
# 6rtX+MLKG4LDRsQgBTi6sIYiKntMjoYFHMPvI/OMUip5ljtLitVbkFGfagSqmbxK
# 7rJMhC8wiTzHanBg1Rrbff1niBbnFbbV4UDmYumjs1FIpFCazk6AADXxoKCo5TsO
# zSHqr9gHgGYQC2hMyX9MGLIpowYCURx3L7kUiGbOiMwaMIIHejCCBWKgAwIBAgIK
# YQ6Q0gAAAAAAAzANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlm
# aWNhdGUgQXV0aG9yaXR5IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEw
# OTA5WjB+MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYD
# VQQDEx9NaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG
# 9w0BAQEFAAOCAg8AMIICCgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+la
# UKq4BjgaBEm6f8MMHt03a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc
# 6Whe0t+bU7IKLMOv2akrrnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4D
# dato88tt8zpcoRb0RrrgOGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+
# lD3v++MrWhAfTVYoonpy4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nk
# kDstrjNYxbc+/jLTswM9sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6
# A4aN91/w0FK/jJSHvMAhdCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmd
# X4jiJV3TIUs+UsS1Vz8kA/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL
# 5zmhD+kjSbwYuER8ReTBw3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zd
# sGbiwZeBe+3W7UvnSSmnEyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3
# T8HhhUSJxAlMxdSlQy90lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS
# 4NaIjAsCAwEAAaOCAe0wggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRI
# bmTlUAXTgqoXNzcitW2oynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTAL
# BgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBD
# uRQFTuHqp8cx0SOJNDBaBgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jv
# c29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFf
# MDNfMjIuY3JsMF4GCCsGAQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFf
# MDNfMjIuY3J0MIGfBgNVHSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEF
# BQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1h
# cnljcHMuaHRtMEAGCCsGAQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkA
# YwB5AF8AcwB0AGEAdABlAG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn
# 8oalmOBUeRou09h0ZyKbC5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7
# v0epo/Np22O/IjWll11lhJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0b
# pdS1HXeUOeLpZMlEPXh6I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/
# KmtYSWMfCWluWpiW5IP0wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvy
# CInWH8MyGOLwxS3OW560STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBp
# mLJZiWhub6e3dMNABQamASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJi
# hsMdYzaXht/a8/jyFqGaJ+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYb
# BL7fQccOKO7eZS/sl/ahXJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbS
# oqKfenoi+kiVH6v7RyOA9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sL
# gOppO6/8MO0ETI7f33VtY5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtX
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCGg8wghoLAgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAOuLTVRyFOPVR0AAAAA
# A64wDQYJYIZIAWUDBAIBBQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEYj
# O0oaJ21QFDXi1pstybXE3QyIav8zaOZbI+yE6d5uMEQGCisGAQQBgjcCAQwxNjA0
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEcgBpodHRwczovL3d3d3cubWljcm9zb2Z0
# LmNvbTANBgkqhkiG9w0BAQEFAASCAQDYjxRoICe0mBXGq22Sr+KPN8j97W2+HjSc
# fRFb3M0k+l4Vh0sNhzU3vvMT0XAahloomR/wErSUTrkywsQHS7F1d+jlkya223ra
# qIt0a42gjQNqVscF0nLGS6s0vZN/PAPnmjx5U/Mb4JDi96KODDn34IJvH245O1ol
# 9LnNA8AFRSByTcdF80thMuwX2gpB5R95rW9mpAzwowJzCJ03bsTAuZ3TVu+DSNTr
# VN1IjhJNUCOb9ybgth+wAgZ670Oqqx6TfepRImIzj+G1yAt7kCoAcgir3sc/gEAs
# G0e6eKUdpqEIPiZg7or5SGQfnDaUBze4Nr0YTpvJWrR8/gatY+5XoYIXlzCCF5MG
# CisGAQQBgjcDAwExgheDMIIXfwYJKoZIhvcNAQcCoIIXcDCCF2wCAQMxDzANBglg
# hkgBZQMEAgEFADCCAVIGCyqGSIb3DQEJEAEEoIIBQQSCAT0wggE5AgEBBgorBgEE
# AYRZCgMBMDEwDQYJYIZIAWUDBAIBBQAEIDrc3Rk15RX+bF/rXMQWVgOZ3mzYXDO/
# T7kwYYfMwZxNAgZlzgV2/fgYEzIwMjQwMjE2MDkwMDUzLjY0OVowBIACAfSggdGk
# gc4wgcsxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNV
# BAsTHE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGll
# bGQgVFNTIEVTTjpBMDAwLTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRp
# bWUtU3RhbXAgU2VydmljZaCCEe0wggcgMIIFCKADAgECAhMzAAAB6+AYbLW27zjt
# AAEAAAHrMA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
# YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAy
# MDEwMB4XDTIzMTIwNjE4NDUzNFoXDTI1MDMwNTE4NDUzNFowgcsxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBB
# bWVyaWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjpBMDAw
# LTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vydmlj
# ZTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAMEVaCHaVuBXd4mnTWiq
# JoUG5hs1zuFIqaS28nXk2sH8MFuhSjDxY85M/FufuByYg4abAmR35PIXHso6fOvG
# egHeG6+/3V9m5S6AiwpOcC+DYFT+d83tnOf0qTWam4nbtLrFQMfih0WJfnUgJwqX
# oQbhzEqBwMCKeKFPzGuglZUBMvunxtt+fCxzWmKFmZy8i5gadvVNj22el0KFav0Q
# BG4KjdOJEaMzYunimJPaUPmGd3dVoZN6k2rJqSmQIZXT5wrxW78eQhl2/L7PkQve
# iNN0Usvm8n0gCiBZ/dcC7d3tKkVpqh6LHR7WrnkAP3hnAM/6LOotp2wFHe3OOrZF
# +sI0v5OaL+NqVG2j8npuHh8+EcROcMLvxPXJ9dRB0a2Yn+60j8A3GLsdXyAA/OJ3
# 1NiMw9tiobzLnHP6Aj9IXKP5oq0cdaYrMRc+21fMBx7EnUQfvBu6JWTewSs8r0wu
# DVdvqEzkchYDSMQBmEoTJ3mEfZcyJvNqRunazYQlBZqxBzgMxoXUSxDULOAKUNgh
# gbqtSG518juTwv0ooIS59FsrmV1Fg0Cp12v/JIl+5m/c9Lf6+0PpfqrUfhQ6aMMp
# 2OhbeqzslExmYf1+QWQzNvphLOvp5fUuhibc+s7Ul5rjdJjOUHdPPzg6+5VJXs1y
# J1W02qJl5ZalWN9q9H4mP8k5AgMBAAGjggFJMIIBRTAdBgNVHQ4EFgQUdJ4FrNZV
# zG7ipP07mNPYH6oB6uEwHwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIw
# XwYDVR0fBFgwVjBUoFKgUIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9w
# cy9jcmwvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3Js
# MGwGCCsGAQUFBwEBBGAwXjBcBggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3Nv
# ZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENB
# JTIwMjAxMCgxKS5jcnQwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEF
# BQcDCDAOBgNVHQ8BAf8EBAMCB4AwDQYJKoZIhvcNAQELBQADggIBAIN03y+g93wL
# 5VZk/f5bztz9Bt1tYrSw631niQQ5aeDsqaH5YPYuc8lMkogRrGeI5y33AyAnzJDL
# BHxYeAM69vCp2qwtRozg2t6u0joUj2uGOF5orE02cFnMdksPCWQv28IQN71FzR0Z
# JV3kGDcJaSdXe69Vq7XgXnkRJNYgE1pBL0KmjY6nPdxGABhV9osUZsCs1xG9Ja9J
# Rt4jYgOpHELjEFtGI1D7WodcMI+fSEaxd8v7KcNmdwJ+zM2uWBlPbheCG9PNgwdx
# eKgtVij/YeTKjDp0ju5QslsrEtfzAeGyLCuJcgMKeMtWwbQTltHzZCByx4SHFtTZ
# 3VFUdxC2RQTtb3PFmpnr+M+ZqiNmBdA7fdePE4dhhVr8Fdwi67xIzM+OMABu6PBN
# rClrMsG/33stEHRk5s1yQljJBCkRNJ+U3fqNb7PtH+cbImpFnce1nWVdbV/rMQIB
# 4/713LqeZwKtVw6ptAdftmvxY9yCEckAAOWbkTE+HnGLW01GT6LoXZr1KlN5Cdlc
# /nTD4mhPEhJCru8GKPaeK0CxItpV4yqg+L41eVNQ1nY121sWvoiKv1kr259rPcXF
# +8Nmjfrm8s6jOZA579n6m7i9jnM+a02JUhxCcXLslk6JlUMjlsh3BBFqLaq4conq
# W1R2yLceM2eJ64TvZ9Ph5aHG2ac3kdgIMIIHcTCCBVmgAwIBAgITMwAAABXF52ue
# AptJmQAAAAAAFTANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlm
# aWNhdGUgQXV0aG9yaXR5IDIwMTAwHhcNMjEwOTMwMTgyMjI1WhcNMzAwOTMwMTgz
# MjI1WjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYD
# VQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDCCAiIwDQYJKoZIhvcN
# AQEBBQADggIPADCCAgoCggIBAOThpkzntHIhC3miy9ckeb0O1YLT/e6cBwfSqWxO
# dcjKNVf2AX9sSuDivbk+F2Az/1xPx2b3lVNxWuJ+Slr+uDZnhUYjDLWNE893MsAQ
# GOhgfWpSg0S3po5GawcU88V29YZQ3MFEyHFcUTE3oAo4bo3t1w/YJlN8OWECesSq
# /XJprx2rrPY2vjUmZNqYO7oaezOtgFt+jBAcnVL+tuhiJdxqD89d9P6OU8/W7IVW
# Te/dvI2k45GPsjksUZzpcGkNyjYtcI4xyDUoveO0hyTD4MmPfrVUj9z6BVWYbWg7
# mka97aSueik3rMvrg0XnRm7KMtXAhjBcTyziYrLNueKNiOSWrAFKu75xqRdbZ2De
# +JKRHh09/SDPc31BmkZ1zcRfNN0Sidb9pSB9fvzZnkXftnIv231fgLrbqn427DZM
# 9ituqBJR6L8FA6PRc6ZNN3SUHDSCD/AQ8rdHGO2n6Jl8P0zbr17C89XYcz1DTsEz
# OUyOArxCaC4Q6oRRRuLRvWoYWmEBc8pnol7XKHYC4jMYctenIPDC+hIK12NvDMk2
# ZItboKaDIV1fMHSRlJTYuVD5C4lh8zYGNRiER9vcG9H9stQcxWv2XFJRXRLbJbqv
# UAV6bMURHXLvjflSxIUXk8A8FdsaN8cIFRg/eKtFtvUeh17aj54WcmnGrnu3tz5q
# 4i6tAgMBAAGjggHdMIIB2TASBgkrBgEEAYI3FQEEBQIDAQABMCMGCSsGAQQBgjcV
# AgQWBBQqp1L+ZMSavoKRPEY1Kc8Q/y8E7jAdBgNVHQ4EFgQUn6cVXQBeYl2D9OXS
# ZacbUzUZ6XIwXAYDVR0gBFUwUzBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcC
# ARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRv
# cnkuaHRtMBMGA1UdJQQMMAoGCCsGAQUFBwMIMBkGCSsGAQQBgjcUAgQMHgoAUwB1
# AGIAQwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaA
# FNX2VsuP6KJcYmjRPZSQW9fOmhjEMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9j
# cmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8y
# MDEwLTA2LTIzLmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6
# Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0XzIwMTAt
# MDYtMjMuY3J0MA0GCSqGSIb3DQEBCwUAA4ICAQCdVX38Kq3hLB9nATEkW+Geckv8
# qW/qXBS2Pk5HZHixBpOXPTEztTnXwnE2P9pkbHzQdTltuw8x5MKP+2zRoZQYIu7p
# Zmc6U03dmLq2HnjYNi6cqYJWAAOwBb6J6Gngugnue99qb74py27YP0h1AdkY3m2C
# DPVtI1TkeFN1JFe53Z/zjj3G82jfZfakVqr3lbYoVSfQJL1AoL8ZthISEV09J+BA
# ljis9/kpicO8F7BUhUKz/AyeixmJ5/ALaoHCgRlCGVJ1ijbCHcNhcy4sa3tuPywJ
# eBTpkbKpW99Jo3QMvOyRgNI95ko+ZjtPu4b6MhrZlvSP9pEB9s7GdP32THJvEKt1
# MMU0sHrYUP4KWN1APMdUbZ1jdEgssU5HLcEUBHG/ZPkkvnNtyo4JvbMBV0lUZNlz
# 138eW0QBjloZkWsNn6Qo3GcZKCS6OEuabvshVGtqRRFHqfG3rsjoiV5PndLQTHa1
# V1QJsWkBRH58oWFsc/4Ku+xBZj1p/cvBQUl+fpO+y/g75LcVv7TOPqUxUYS8vwLB
# gqJ7Fx0ViY1w/ue10CgaiQuPNtq6TPmb/wrpNPgkNWcr4A245oyZ1uEi6vAnQj0l
# lOZ0dFtq0Z4+7X6gMTN9vMvpe784cETRkPHIqzqKOghif9lwY1NNje6CbaUFEMFx
# BmoQtB1VM1izoXBm8qGCA1AwggI4AgEBMIH5oYHRpIHOMIHLMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1l
# cmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046QTAwMC0w
# NUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2Wi
# IwoBATAHBgUrDgMCGgMVAIAGiXW7XDDBiBS1SjAyepi9u6XeoIGDMIGApH4wfDEL
# MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
# bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWlj
# cm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwDQYJKoZIhvcNAQELBQACBQDpeSym
# MCIYDzIwMjQwMjE2MDAzNjU0WhgPMjAyNDAyMTcwMDM2NTRaMHcwPQYKKwYBBAGE
# WQoEATEvMC0wCgIFAOl5LKYCAQAwCgIBAAICAqwCAf8wBwIBAAICE5wwCgIFAOl6
# fiYCAQAwNgYKKwYBBAGEWQoEAjEoMCYwDAYKKwYBBAGEWQoDAqAKMAgCAQACAweh
# IKEKMAgCAQACAwGGoDANBgkqhkiG9w0BAQsFAAOCAQEAfiNWmXtyMrASCpUxHDAF
# XLwAI6uiU0ucZFf727eSlOf9HqF9qknqN30AAHhQ7j1UKZNFPEikf/lZ9rEL4+Th
# w5bOxb18evcuYOSV07VmzpAuPvj1CioghO/uxDFOEDrSb3r0vM6KqW22bYIIS8qF
# M/wfzPsLIyoXM62zleYuIfUq9tK2GenonE4hlTAWCNyCd0/NxGaT64ZsQbAArrQN
# qtaqMo6QiBU+4YEQSvCLn97JuwDE3h8S9ipNXo50zhVE5rZZBbuQ2kMAOAUZvDPs
# /al8tpMJpw9OTCp2wxUUOByy1wEJRTSgvvKonr7id68Ohtzd1S2gYW/0+uPUnKta
# uzGCBA0wggQJAgEBMIGTMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
# dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMz
# AAAB6+AYbLW27zjtAAEAAAHrMA0GCWCGSAFlAwQCAQUAoIIBSjAaBgkqhkiG9w0B
# CQMxDQYLKoZIhvcNAQkQAQQwLwYJKoZIhvcNAQkEMSIEIL4L01NJTzirqZ+kB96F
# Saq9RpdackfKl0NdZ4d6UxWDMIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCBvQQg
# zrdrvl9pA+F/xIENO2TYNJSAht2LNezPvqHUl2EsLPgwgZgwgYCkfjB8MQswCQYD
# VQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEe
# MBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3Nv
# ZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAevgGGy1tu847QABAAAB6zAiBCB1
# hOajD+4rIhZVH8EsSDCdCVVKoJPF+xne8d4QdcKZ0TANBgkqhkiG9w0BAQsFAASC
# AgAp7xWQS2oqnzcCYj2lMs45LwTeSryIPHM8SLu6fRgFbUkxPuqkbaMurkOj6mnh
# MnU+Bo6v1CpVfSkUiHW9AFxQ8hf9m8v0nvQ4TmSH6mNIdnwYFC+Run93Nh0y492w
# MgqJ8k+4B/zGOb0Kp8vGsSZs8e76o2kMzSqL3grut2f2EEYrODsfmryCQX4uTJp1
# qoJYaV2Ap+sbgP5UwnT255hj9hl3TERc4OThra+II5zkCHirzSLufZiZORUQ6iED
# gt/DciUmpf6JEysxX96yXBatS8ERSihJXoqKJMb9Fvvj+ewSgzeDdfNLrPJlCw7o
# eYrR4ikIdhG6ITbpYKPQsVHAXmUDibpa/AHAwbUwyfeiS9b5Y9k01L4CbVplOT5O
# bLhTQp/lpHZqYNbPrHQVrFw7TLvWFXUYsXh+7sdSHm+6Po2hJjdb0n6GyvlpjJ2B
# dMjz9hEDbxYoHKZ/ysJuj0Qkqsd+eA1WU0fjSOeg20d5Vc0Cu8+jtcV32oFyZdVn
# MePR+UPNdkP2/ZTBu/Qyb3MTmeCctBJAwUZBFcEzyilcgLDvus5NBSszrv7lW8yP
# fldofhKW/YbS6DbMLOyhL02vFHOY2TY0OTrSlc/iMy2NL6whDCvkOWuE+ueW8y+W
# YgswGBIYl5c6eahfSxtdLgd+S5mNPnqqpxL6fGMpvf7YLA==
# SIG # End signature block
