param
(
    [Parameter(Position=0)]
    [string]    $SummaryOutputFile,

    [Parameter(Position=1)]
    [switch]    $DebugOn

)

$DebugOn = $false

<#
1 - This module validates if all the expected log files are generated for the given scenario.
2 - In the case of expected files not being found in the output folder, a message is displayed with the missing file name in red for each scenario.
3 - An array is maintained for each scenario with the list of expected files. If a new log file is collected for a scenario, the corresponding array needs to be updated to include that file in the array.
4 - Execution of the scenario is obtained from ##SQLLOGSCOUT.LOG  by scanning for this text pattern "Scenario Console input:" , so if any changes are made to the  ##SQLLOGSCOUT.LOG file, the logic here needs to be updated here as well.
5 - This module works for validating a single scenario or  multiple scenarios
#>

Import-Module -Name ..\CommonFunctions.psm1
Import-Module -Name ..\LoggingFacility.psm1

# Declaration of global variables
$global:sqllogscout_log = "##SQLLOGSCOUT.LOG"
$global:sqllogscoutdebug_log = "##SQLLOGSCOUT_DEBUG.LOG"
$global:filter_pattern = @("*.txt", "*.out", "*.csv", "*.xel", "*.blg", "*.sqlplan", "*.trc", "*.LOG","*.etl","*.NGENPDB","*.mdmp", "*.pml")
$global:sqllogscout_latest_output_folder = ""
$global:sqllogscout_root_directory = Convert-Path -Path ".\..\..\"   #this goes to the SQL LogScout root directory
$global:sqllogscout_latest_internal_folder = ""
$global:sqllogscout_testing_infrastructure_output_folder = ""
$global:sqllogscout_latest_output_internal_logpath = ""
$global:sqllogscout_latest_output_internal_debuglogpath = ""
$global:DetailFile = ""

[System.Collections.ArrayList]$global:BasicFiles = New-Object -TypeName System.Collections.ArrayList
[System.Collections.ArrayList]$global:GeneralPerfFiles = New-Object -TypeName System.Collections.ArrayList
[System.Collections.ArrayList]$global:DetailedPerfFiles = New-Object -TypeName System.Collections.ArrayList
[System.Collections.ArrayList]$global:ReplicationFiles = New-Object -TypeName System.Collections.ArrayList
[System.Collections.ArrayList]$global:AlwaysOnFiles = New-Object -TypeName System.Collections.ArrayList
[System.Collections.ArrayList]$global:NetworkTraceFiles = New-Object -TypeName System.Collections.ArrayList
[System.Collections.ArrayList]$global:MemoryFiles = New-Object -TypeName System.Collections.ArrayList
[System.Collections.ArrayList]$global:DumpMemoryFiles = New-Object -TypeName System.Collections.ArrayList
[System.Collections.ArrayList]$global:WPRFiles = New-Object -TypeName System.Collections.ArrayList
[System.Collections.ArrayList]$global:SetupFiles = New-Object -TypeName System.Collections.ArrayList
[System.Collections.ArrayList]$global:BackupRestoreFiles = New-Object -TypeName System.Collections.ArrayList
[System.Collections.ArrayList]$global:IOFiles = New-Object -TypeName System.Collections.ArrayList
[System.Collections.ArrayList]$global:LightPerfFiles = New-Object -TypeName System.Collections.ArrayList
[System.Collections.ArrayList]$global:ProcessMonitorFiles = New-Object -TypeName System.Collections.ArrayList
[System.Collections.ArrayList]$global:ServiceBrokerDbMailFiles = New-Object -TypeName System.Collections.ArrayList
[System.Collections.ArrayList]$global:NeverEndingQueryFiles = New-Object -TypeName System.Collections.ArrayList


function CopyArray([System.Collections.ArrayList]$Source, [System.Collections.ArrayList]$Destination)
{
    foreach ($file in $Source)
    {
        [void]$Destination.Add($file)
    }
}



#Function for inclusions and exclusions to search the logs (debug and regular) for a string and add to array if found as we expect the file to be written.
function ModifyArray()
{
    param
        (
            [Parameter(Position=0, Mandatory=$true)]
            [string] $ActionType,

            [Parameter(Position=1, Mandatory=$true)]
            [string] $TextToFind,

            [Parameter(Position=2, Mandatory=$true)]
            [System.Collections.ArrayList] $ArrayToEdit,

            [Parameter(Position=3, Mandatory=$false)]
            [string] $ReferencedLog
        )

        #Check the default log first as there less records than debug log.
        #If we didn't find in default log, then check debug log for the provided string.
        [Boolean] $fTextFound = (Select-String -Path $global:sqllogscout_latest_output_internal_logpath -Pattern $TextToFind) -OR
        (Select-String -Path $global:sqllogscout_latest_output_internal_debuglogpath -Pattern $TextToFind)

    if ($fTextFound) 
    {
        if ($ActionType -eq 'Add')
        {

            [void]$ArrayToEdit.Add($ReferencedLog)
            WriteToConsoleAndFile -Message "Adding value '$ReferencedLog' to array"

        }

        elseif ($ActionType -eq 'Remove')
        {

            [void]$ArrayToEdit.Remove($ReferencedLog)
            WriteToConsoleAndFile -Message "Removing value '$ReferencedLog' from array"

        } elseif ($ActionType -eq "Clear")
        {
            [void]$ArrayToEdit.Clear()
            WriteToConsoleAndFile -Message "Removing all values from array"
        }

        #We didn't find the provided text so don't add to array. We don't expect the file.
        else
        {
            WriteToConsoleAndFile -Message "Improper use of ModifyArray(). Value passed: $ActionType" -ForegroundColor Red
        }
    }
    
}

function BuildBasicFileArray([bool]$IsNoBasic)
{
    $global:BasicFiles =
	@(
		'ERRORLOG',
		'SQLAGENT',
		'system_health',
		'RunningDrivers.csv',
		'RunningDrivers.txt',
		'SystemInfo_Summary.out',
		'MiscDiagInfo.out',
		'TaskListServices.out',
		'TaskListVerbose.out',
		'PowerPlan.out',
		'WindowsHotfixes.out',
        'WindowsDiskInfo.out',
		'FLTMC_Filters.out',
		'FLTMC_Instances.out',
		'EventLog_Application.csv',
		'EventLog_System.csv',
        'EventLog_System.out',
        'EventLog_Application.out',
		'UserRights.out',	
		'Fsutil_SectorInfo.out',
        'Perfmon.out',
        'DNSClientInfo.out',
        'IPConfig.out',
        'NetTCPandUDPConnections.out',
        'SQL_AzureVM_Information.out',
        'Environment_Variables.out',
        'azcmagent-logs'
	)

	# inclusions and exclusions to the array
    ModifyArray -ActionType "Add" -TextToFind "This is a Windows Cluster for sure!"  -ArrayToEdit $global:BasicFiles -ReferencedLog "_SQLDIAG"
    ModifyArray -ActionType "Remove" -TextToFind "Azcmagent not found" -ArrayToEdit $global:BasicFiles -ReferencedLog "azcmagent-logs"
    ModifyArray -ActionType "Remove" -TextToFind "Will not collect SQLAssessmentAPI" -ArrayToEdit $global:BasicFiles -ReferencedLog "SQLAssessmentAPI"
    ModifyArray -ActionType "Remove" -TextToFind "No SQLAgent log files found" -ArrayToEdit $global:BasicFiles -ReferencedLog "SQLAGENT"
    ModifyArray -ActionType "Remove" -TextToFind "SQL_AzureVM_Information will not be collected" -ArrayToEdit $global:BasicFiles -ReferencedLog "SQL_AzureVM_Information.out"
    ModifyArray -ActionType "Add" -TextToFind "memory dumps \(max count limit of 20\), from the past 2 months, of size < 100 MB"  -ArrayToEdit $global:BasicFiles -ReferencedLog ".mdmp"
    ModifyArray -ActionType "Add" -TextToFind "memory dumps \(max count limit of 20\), from the past 2 months, of size < 100 MB"  -ArrayToEdit $global:BasicFiles -ReferencedLog "SQLDUMPER_ERRORLOG.log"
    ModifyArray -ActionType "Clear" -TextToFind "NeverEndingQuery Exit without collection" -ArrayToEdit $global:BasicFiles

    #calculate count of expected files
    $ExpectedFiles = $global:BasicFiles
    return $ExpectedFiles

}

function BuildGeneralPerfFileArray([bool]$IsNoBasic)
{
    $global:GeneralPerfFiles =
	@(
        'Perfmon.out',
        'xevent_LogScout_target',
        'ExistingProfilerXeventTraces.out',
        'HighCPU_perfstats.out',
        'PerfStats.out',
        'PerfStatsSnapshotStartup.out',
        'QueryStore.out',
        'TempDB_and_Tran_Analysis.out',
        'linked_server_config.out',
        'PerfStatsSnapshotShutdown.out',
        'Top_CPU_QueryPlansXml_Shutdown_'
	)

    if ($IsNoBasic -ne $true)
    {
        #add the basic array files
        CopyArray -Source $global:BasicFiles -Destination $global:GeneralPerfFiles
    }

	# inclusions and exclusions to the array
    #...

    #calculate count of expected files
    $ExpectedFiles = $global:GeneralPerfFiles
    return $ExpectedFiles

}

function BuildDetailedPerfFileArray([bool]$IsNoBasic)
{

    $global:DetailedPerfFiles =
	@(
        'Perfmon.out',
        'xevent_LogScout_target',
        'ExistingProfilerXeventTraces.out',
        'HighCPU_perfstats.out',
        'PerfStats.out',
        'PerfStatsSnapshotStartup.out',
        'QueryStore.out',
        'TempDB_and_Tran_Analysis.out',
        'linked_server_config.out',
        'PerfStatsSnapshotShutdown.out',
        'Top_CPU_QueryPlansXml_Shutdown_'
     )

    if ($IsNoBasic -ne $true)
    {
        #add the basic array files
        CopyArray -Source $global:BasicFiles -Destination $global:DetailedPerfFiles
    }

	# inclusions and exclusions to the array
    #...

    #calculate count of expected files
    $ExpectedFiles = $global:DetailedPerfFiles
    return $ExpectedFiles
}


function BuildReplicationFileArray([bool]$IsNoBasic)
{

    $global:ReplicationFiles =
	@(
        'ChangeDataCaptureStartup.out',
        'Change_TrackingStartup.out',
        'ChangeDataCaptureShutdown.out',
        'Change_TrackingShutdown.out'
     )

    if ($IsNoBasic -ne $true)
    {
        #add the basic array files
        CopyArray -Source $global:BasicFiles -Destination $global:ReplicationFiles
    }

	# inclusions and exclusions to the array
    ModifyArray -ActionType "Add" -TextToFind "Collecting Replication Metadata"  -ArrayToEdit $global:ReplicationFiles -ReferencedLog "Repl_Metadata_CollectorShutdown"

    #calculate count of expected files
    $ExpectedFiles = $global:ReplicationFiles
    return $ExpectedFiles

}

function BuildAlwaysOnFileArray([bool]$IsNoBasic)
{

    $global:AlwaysOnFiles =
	@(
        'AlwaysOnDiagScript.out',
        'AlwaysOn_Data_Movement_target',
        'xevent_LogScout_target',
        'Perfmon.out',
        'cluster.log',
        'GetAGTopology.xml'
     )

    if ($IsNoBasic -ne $true)
    {
        #add the basic array files
        CopyArray -Source $global:BasicFiles -Destination $global:AlwaysOnFiles
	}

    # inclusions and exclusions to the array
    ModifyArray -ActionType "Remove" -TextToFind "AlwaysOn_Data_Movement Xevents is not supported on SQL Server version"  -ArrayToEdit $global:AlwaysOnFiles -ReferencedLog "AlwaysOn_Data_Movement_target"
    ModifyArray -ActionType "Remove" -TextToFind "This is Not a Windows Cluster!"  -ArrayToEdit $global:AlwaysOnFiles -ReferencedLog "cluster.log"
    ModifyArray -ActionType "Remove" -TextToFind "HADR is off, skipping data movement and AG Topology" -ArrayToEdit $global:AlwaysOnFiles -ReferencedLog "GetAGTopology.xml"
    ModifyArray -ActionType "Remove" -TextToFind "HADR is off, skipping data movement and AG Topology" -ArrayToEdit $global:AlwaysOnFiles -ReferencedLog "AlwaysOn_Data_Movement_target"
    ModifyArray -ActionType "Remove" -TextToFind "HADR is off, skipping data movement and AG Topology" -ArrayToEdit $global:AlwaysOnFiles -ReferencedLog "xevent_LogScout_target"

    #calculate count of expected files
    $ExpectedFiles = $global:AlwaysOnFiles
    return $ExpectedFiles
}


function BuildNetworkTraceFileArray([bool]$IsNoBasic)
{

    $global:NetworkTraceFiles =
	@(
        'delete.me',
        'NetworkTrace_LogmanStart1.etl'
     )

    #network trace does not collect basic scenario logs with it

    # inclusions and exclusions to the array
    #...

    #calculate count of expected files
    $ExpectedFiles = $global:NetworkTraceFiles
    return $ExpectedFiles
}


function BuildMemoryFileArray([bool]$IsNoBasic)
{

    $global:MemoryFiles =
	@(
        'SQL_Server_Mem_Stats.out',
        'Perfmon.out'
    )

    if ($IsNoBasic -ne $true)
    {
        #add the basic array files
        CopyArray -Source $global:BasicFiles -Destination $global:MemoryFiles
	}

    # inclusions and exclusions to the array
    #...

    #calculate count of expected files
    $ExpectedFiles = $global:MemoryFiles
    return $ExpectedFiles
}


function BuildDumpMemoryFileArray([bool]$IsNoBasic)
{

    $global:DumpMemoryFiles =
	@(
        'SQLDmpr',
        'SQLDUMPER_ERRORLOG.log'
    )

    #dumpmemory does not collect basic scenario logs with it

    # inclusions and exclusions to the array
    #...

    #calculate count of expected files
    $ExpectedFiles = $global:DumpMemoryFiles
    return $ExpectedFiles
}

function BuildWPRFileArray([bool]$IsNoBasic)
{

    $global:WPRFiles = 	@()

    #WPR does not collect basic scenario logs with it

    # inclusions and exclusions to the array
    #...

    #cpu scenario
    $WPRCollected = Select-String -Path $global:sqllogscout_latest_output_internal_logpath -Pattern "WPR_CPU_Stop"

    if ([string]::IsNullOrEmpty($WPRCollected) -eq $false)
    {
        [void]$global:WPRFiles.Add("WPR_CPU_Stop.etl")
    }

    #heap and virtual memory
    $WPRCollected = Select-String -Path $global:sqllogscout_latest_output_internal_logpath -Pattern "WPR_HeapAndVirtualMemory_Stop "

    if ([string]::IsNullOrEmpty($WPRCollected) -eq $false)
    {
        [void]$global:WPRFiles.Add("WPR_HeapAndVirtualMemory_Stop.etl")
    }

    #disk and file I/O
    $WPRCollected = Select-String -Path $global:sqllogscout_latest_output_internal_logpath -Pattern "WPR_DiskIO_FileIO_Stop"

    if ([string]::IsNullOrEmpty($WPRCollected) -eq $false)
    {
        [void]$global:WPRFiles.Add("WPR_DiskIO_FileIO_Stop.etl")
    }

    #filter drivers scenario
    $WPRCollected = Select-String -Path $global:sqllogscout_latest_output_internal_logpath -Pattern "WPR_MiniFilters_Stop"

    if ([string]::IsNullOrEmpty($WPRCollected) -eq $false)
    {
        [void]$global:WPRFiles.Add("WPR_MiniFilters_Stop.etl")
    }


    #calculate count of expected files
    $ExpectedFiles = $global:WPRFiles
    return $ExpectedFiles
}

function BuildSetupFileArray([bool]$IsNoBasic)
{

    $global:SetupFiles =
	@(
        'Setup_Bootstrap',
        '_HKLM_CurVer_Uninstall.txt',
        '_HKLM_MicrosoftSQLServer.txt'
    )


    if ($IsNoBasic -ne $true)
    {
        #add the basic array files
        CopyArray -Source $global:BasicFiles -Destination $global:SetupFiles
	}


    # inclusions and exclusions to the array
    #...

    #calculate count of expected files
    $ExpectedFiles = $global:SetupFiles
    return $ExpectedFiles
}

function BuildBackupRestoreFileArray([bool]$IsNoBasic)
{

    $global:BackupRestoreFiles =
	@(
        'xevent_LogScout_target',
        'Perfmon.out_000001.blg',
        'VSSAdmin_Providers.out',
        'VSSAdmin_Shadows.out',
        'VSSAdmin_Shadowstorage.out',
        'VSSAdmin_Writers.out',
        'SqlWriterLogger.txt'
    )

    if ($IsNoBasic -ne $true)
    {
        #add the basic array files
        CopyArray -Source $global:BasicFiles -Destination $global:BackupRestoreFiles
	}

    # inclusions and exclusions to the array
    ModifyArray -ActionType "Remove" -TextToFind "Not collecting SQL VSS log"  -ArrayToEdit $global:BackupRestoreFiles -ReferencedLog "SqlWriterLogger.txt"
    ModifyArray -ActionType "Remove" -TextToFind "Backup_restore_progress_trace XEvent exists in SQL Server 2016 and higher and cannot be collected for instance"  -ArrayToEdit $global:BackupRestoreFiles -ReferencedLog "xevent_LogScout_target"

    #calculate count of expected files
    $ExpectedFiles = $global:BackupRestoreFiles
    return $ExpectedFiles
}

function BuildIOFileArray([bool]$IsNoBasic)
{

    $global:IOFiles =
	@(
        'StorPort.etl',
        'High_IO_Perfstats.out',
        'Perfmon.out'
    )


    if ($IsNoBasic -ne $true)
    {
        #add the basic array files
        CopyArray -Source $global:BasicFiles -Destination $global:IOFiles
	}


    # inclusions and exclusions to the array
    #...

    #calculate count of expected files
    $ExpectedFiles = $global:IOFiles
    return $ExpectedFiles
}

function BuildLightPerfFileArray([bool]$IsNoBasic)
{
    $global:LightPerfFiles =
	@(
        'Perfmon.out',
        'ExistingProfilerXeventTraces.out',
        'HighCPU_perfstats.out',
        'PerfStats.out',
        'PerfStatsSnapshotStartup.out',
        'QueryStore.out',
        'TempDB_and_Tran_Analysis.out',
        'linked_server_config.out',
        'PerfStatsSnapshotShutdown.out',
        'Top_CPU_QueryPlansXml_Shutdown_'
    )

    if ($IsNoBasic -ne $true)
    {
        #add the basic array files
        CopyArray -Source $global:BasicFiles -Destination $global:LightPerfFiles
	}

    # inclusions and exclusions to the array
    #...

    #calculate count of expected files
    $ExpectedFiles = $global:LightPerfFiles
    return $ExpectedFiles
}
function BuildProcessMonitorFileArray([bool]$IsNoBasic)
{

    $global:ProcessMonitorFiles =
	@(
        'ProcessMonitor.pml'
     )


    #ProcessMonitor does not collect basic scenario logs with it


    # inclusions and exclusions to the array
    #...

    #calculate count of expected files
    $ExpectedFiles = $global:ProcessMonitorFiles
    return $ExpectedFiles
}

function BuildNeverEndingQueryFileArray([bool]$IsNoBasic)
{
    $global:NeverEndingQueryFiles =
    @(
        'NeverEndingQuery_perfstats.out',
        'NeverEnding_HighCPU_QueryPlansXml_',
        'NeverEnding_statistics_QueryPlansXml_'
    )

    if ($true -ne $IsNoBasic) 
        {
            #add the basic array files
            CopyArray -Source $global:BasicFiles -Destination $global:NeverEndingQueryFiles
        }
    ModifyArray -ActionType "Clear" -TextToFind "NeverEndingQuery Exit without collection" -ArrayToEdit $global:NeverEndingQueryFiles 

    return $global:NeverEndingQueryFiles
}
function BuildServiceBrokerDbMailFileArray([bool]$IsNoBasic)
{

    $global:ServiceBrokerDbMailFiles =
	@(
        'Perfmon.out',
        'SSB_DbMail_Diag.out',
        'xevent_LogScout_target'
     )

    #network trace does not collect basic scenario logs with it

    # inclusions and exclusions to the array
    #...

    #calculate count of expected files
    $ExpectedFiles = $global:ServiceBrokerDbMailFiles
    return $ExpectedFiles
}

function WriteToSummaryFile ([string]$SummaryOutputString)
{
    if ([string]::IsNullOrWhiteSpace($SummaryOutputFile) -ne $true)
    {
        Write-Output $SummaryOutputString |Out-File $SummaryOutputFile -Append
    }

}

function WriteToConsoleAndFile ([string]$Message, [string]$ForegroundColor = "")
{
    if ($ForegroundColor -ne "")
    {
        Write-Host $Message -ForegroundColor $ForegroundColor
    }
    else
    {
        Write-Host $Message
    }

    if ($true -eq (Test-Path $global:DetailFile))
    {
        Write-Output $Message | Out-File -FilePath $global:DetailFile -Append
    }
}

function DiscoverScenarios ([string]$SqlLogscoutLog)
{
    #find the line in the log file that says "The scenarios selected are: 'GeneralPerf Basic' " It contains the scenarios being executed
    #then strip out just the scenario names and use those to find if all the files for them are present

    [String] $ScenSelStr = (Select-String -Path $SqlLogscoutLog -Pattern "The scenarios selected are:" |Select-Object -First 1 Line).Line

    if ($DebugOn)
    {
        Write-Host "ScenSelStr: $ScenSelStr"
    }


    # this section parses out the scenario names from the string extracted from the log
    # NoBasic may also be there and will be used later

    $colon_position = $ScenSelStr.LastIndexOf(":")
    $colon_position = $colon_position + 1
    $ScenSelStr = ($ScenSelStr.Substring($colon_position).TrimEnd()).TrimStart()
    $ScenSelStr = $ScenSelStr.Replace('''','')
    $ScenSelStr = $ScenSelStr.Replace(' ','+')

    #popluate an array with the scenarios
    [string[]]$scenStrArray = $ScenSelStr.Split('+')

    #remove any blank elements in the array
    $scenStrArray = $scenStrArray.Where({ "" -ne $_ })


    return $scenStrArray

}


function CreateTestResultsFile ([string[]]$ScenarioArray)
{

    $fileScenString =""

    foreach($scenario in $ScenarioArray)
    {
        switch ($scenario)
        {
            "NoBasic"       {$fileScenString +="NoB"}
            "Basic"         {$fileScenString +="Bas"}
            "GeneralPerf"   {$fileScenString +="GPf"}
            "DetailedPerf"  {$fileScenString +="DPf"}
            "Replication"   {$fileScenString +="Rep"}
            "AlwaysOn"      {$fileScenString +="AO"}
            "NetworkTrace"  {$fileScenString +="Net"}
            "Memory"        {$fileScenString +="Mem"}
            "DumpMemory"    {$fileScenString +="Dmp"}
            "WPR"           {$fileScenString +="Wpr"}
            "Setup"         {$fileScenString +="Set"}
            "BackupRestore" {$fileScenString +="Bkp"}
            "IO"            {$fileScenString +="IO"}
            "LightPerf"     {$fileScenString +="LPf"}
            "ProcessMonitor"{$fileScenString +="PrM"}
            "ServiceBrokerDBMail"{$fileScenString +="Ssb"}
            "NeverEndingQuery" {$fileScenString +="NEQ"}
        }

        $fileScenString +="_"

    }

    # create the file validation log
    if (!(Test-Path -Path $global:sqllogscout_testing_infrastructure_output_folder))
    {
        Write-Host "Folder '$global:sqllogscout_testing_infrastructure_output_folder' does not exist. Cannot create text output file"
    }
    else
    {
        $FileName = "FileValidation_" + $fileScenString + (Get-Date -Format "MMddyyyyHHmmss").ToString() + ".txt"
        $global:DetailFile = $global:sqllogscout_testing_infrastructure_output_folder + "\" + $FileName

        Write-Host "Creating file validation log in folder '$global:DetailFile'"
        New-Item -ItemType File -Path  $global:sqllogscout_testing_infrastructure_output_folder -Name $FileName | Out-Null
    }

}

function Set-TestInfraOutputFolder()
{
    $present_directory = Convert-Path -Path "."   #this gets the current directory called \TestingInfrastructure

	#create the testing infrastructure output folder
    $folder = New-Item -Path $present_directory -Name "Output" -ItemType Directory -Force
    $global:sqllogscout_testing_infrastructure_output_folder = $folder.FullName

    #create the LogFileMissing.log if output and/or internal folders/files are missing
    $PathToFileMissingLogFile =  $global:sqllogscout_testing_infrastructure_output_folder + '\LogScoutFolderOrFileMissing.LOG'

    # get the latest output folder that contains SQL LogScout logs
    $latest = Get-ChildItem -Path $global:sqllogscout_root_directory -Filter "output*" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    
    #if no output folder is found, then we cannot continue
    if ([String]::IsNullOrWhiteSpace($latest))
    {
        Write-Host "No 'output*' folder(s) found'. Cannot continue" -ForegroundColor Red
        Write-Output "No 'output*' folder(s) found'. Cannot continue"  | Out-File -FilePath $PathToFileMissingLogFile -Append
        return $false
    }

    #set the path to the latest output folder
    $global:sqllogscout_latest_output_folder = ($global:sqllogscout_root_directory + "\"+ $latest + "\")

    #check if the \output folder exists
    if (!(Test-Path -Path $global:sqllogscout_latest_output_folder ))
    {
        $OutputFolderCheckLogMessage = "Folder '" + $global:sqllogscout_latest_output_folder + "' does not exist"
        $OutputFolderCheckLogMessage = $OutputFolderCheckLogMessage.replace("`n", " ")

        Write-Host $OutputFolderCheckLogMessage -ForegroundColor Red
        Write-Output $OutputFolderCheckLogMessage  | Out-File -FilePath $PathToFileMissingLogFile -Append

        return $false
    }

    #check if the \internal folder exists
    $global:sqllogscout_latest_internal_folder = ($global:sqllogscout_latest_output_folder + "internal\")

    if (!(Test-Path -Path $global:sqllogscout_latest_internal_folder ))
    {
        $OutputInternalFolderCheckLogMessage = "Folder '" + $global:sqllogscout_latest_internal_folder + "' does not exist"
        $OutputInternalFolderCheckLogMessage = $OutputInternalFolderCheckLogMessage.replace("`n", " ")

        Write-Host $OutputInternalFolderCheckLogMessage -ForegroundColor Red
        Write-Output $OutputInternalFolderCheckLogMessage | Out-File -FilePath $PathToFileMissingLogFile -Append

        return $false
    }

    #get the path to the latest SQL LogScout log and debug log files
	$global:sqllogscout_latest_output_internal_logpath = ($global:sqllogscout_latest_internal_folder + $global:sqllogscout_log)
    $global:sqllogscout_latest_output_internal_debuglogpath = ($global:sqllogscout_latest_internal_folder + $global:sqllogscoutdebug_log)

    return $true
}

#--------------------------------------------------------Scenario check Start ------------------------------------------------------------

function FileCountAndFileTypeValidation([string]$scenario_string, [bool]$IsNoBasic)
{
    $summary_out_string = ""
    $return_val = $true

    try
    {

        $msg = ''

        #build the array of expected files for the respective scenario
        switch ($scenario_string)
        {
            "Basic"
            {
                $ExpectedFiles = BuildBasicFileArray -IsNoBasic $IsNoBasic
                $ExpectedFileCount = $global:BasicFiles.Count
            }
            "GeneralPerf"
            {
                $ExpectedFiles = BuildGeneralPerfFileArray -IsNoBasic $IsNoBasic
                $ExpectedFileCount = $global:GeneralPerfFiles.Count
            }
            "DetailedPerf"
            {
                $ExpectedFiles = BuildDetailedPerfFileArray -IsNoBasic $IsNoBasic
                $ExpectedFileCount = $global:DetailedPerfFiles.Count
            }
            "Replication"
            {
                $ExpectedFiles = BuildReplicationFileArray -IsNoBasic $IsNoBasic
                $ExpectedFileCount = $global:ReplicationFiles.Count
            }
            "AlwaysOn"
            {
                $ExpectedFiles = BuildAlwaysOnFileArray -IsNoBasic $IsNoBasic
                $ExpectedFileCount = $global:AlwaysOnFiles.Count
            }
            "NetworkTrace"
            {
                $ExpectedFiles = BuildNetworkTraceFileArray -IsNoBasic $IsNoBasic
                $ExpectedFileCount = $global:NetworkTraceFiles.Count
            }
            "Memory"
            {
                $ExpectedFiles = BuildMemoryFileArray -IsNoBasic $IsNoBasic
                $ExpectedFileCount = $global:MemoryFiles.Count
            }
            "DumpMemory"
            {
                $ExpectedFiles = BuildDumpMemoryFileArray -IsNoBasic $IsNoBasic
                $ExpectedFileCount = $global:DumpMemoryFiles.Count
            }
            "WPR"
            {
                $ExpectedFiles = BuildWPRFileArray -IsNoBasic $IsNoBasic
                $ExpectedFileCount = $global:WPRFiles.Count
            }
            "Setup"
            {
                $ExpectedFiles = BuildSetupFileArray -IsNoBasic $IsNoBasic
                $ExpectedFileCount = $global:SetupFiles.Count
            }
            "BackupRestore"
            {
                $ExpectedFiles = BuildBackupRestoreFileArray -IsNoBasic $IsNoBasic
                $ExpectedFileCount = $global:BackupRestoreFiles.Count
            }
            "IO"
            {
                $ExpectedFiles = BuildIOFileArray -IsNoBasic $IsNoBasic
                $ExpectedFileCount = $global:IOFiles.Count
            }

            "LightPerf"
            {
                $ExpectedFiles = BuildLightPerfFileArray -IsNoBasic $IsNoBasic
                $ExpectedFileCount = $global:LightPerfFiles.Count
            }
            "ProcessMonitor"
            {
                $ExpectedFiles = BuildProcessMonitorFileArray -IsNoBasic $IsNoBasic
                $ExpectedFileCount = $global:ProcessMonitorFiles.Count
            }
            "ServiceBrokerDbMail"
            {
                $ExpectedFiles = BuildServiceBrokerDbMailFileArray -IsNoBasic $IsNoBasic
                $ExpectedFileCount = $global:ServiceBrokerDbMailFiles.Count
            }
            "NeverEndingQuery"
            {
                $ExpectedFiles = BuildNeverEndingQueryFileArray -IsNoBasic $IsNoBasic
                $ExpectedFileCount = $global:NeverEndingQueryFiles.Count
            }
        }


        #print this if Debug is enabled
        if ($DebugOn)
        {
            Write-Host "******** IsNoBasic: " $IsNoBasic
            Write-Host "******** ScenarioName: " $scenario_string
        }

        WriteToConsoleAndFile -Message "" 
        WriteToConsoleAndFile -Message ("Expected files list: " + $ExpectedFiles)
        WriteToConsoleAndFile -Message ("Expected File Count: " + $ExpectedFileCount)
        


        #-------------------------------------next section does the specific file type validation ------------------------------
        #get a list of all the files in the \Output folder and exclude the \internal folder
        $LogsCollected = Get-ChildItem -Path $global:sqllogscout_latest_output_folder -Exclude "internal"

        $summary_out_string = "File validation test for '$scenario_string':"

        $msg = "-- File validation result for '$scenario_string' scenario --"
        WriteToConsoleAndFile -Message ""
        WriteToConsoleAndFile -Message $msg

        $missing_files_count = 0

        #loop through the expected files array
        foreach ($expFile in $ExpectedFiles)
        {
            $file_found = $false

            #loop through array of actual files found
            foreach ($actFile in $LogsCollected)
            {
                # if a file is found , set the flag
                if ($actFile.Name -like ("*" + $expFile + "*"))
                {
                    $file_found = $true
                }
            }

            if ($false -eq $file_found)
            {
                $missing_files_count++
                WriteToConsoleAndFile -Message ("File '$expFile' not found!") -ForegroundColor Red
            }
        } #end of outer loop

        if ($missing_files_count -gt 0)
        {
            WriteToConsoleAndFile -Message ""
            WriteToConsoleAndFile -Message ("Missing file count = $missing_files_count")

            WriteToConsoleAndFile -Message ("Status: FAILED") -ForegroundColor Red

            $summary_out_string =  ($summary_out_string + " "*(60 - $summary_out_string.Length) +"FAILED!!! (See '$global:DetailFile' for more details)")

            $return_val = $false
        }
        else
        {
            WriteToConsoleAndFile -Message ""

            WriteToConsoleAndFile -Message "Status: SUCCESS" -ForegroundColor Green
            WriteToConsoleAndFile -Message ("Summary: All expected log files for scenario '$scenario_string' are present in your latest output folder!!")

            $summary_out_string =  ($summary_out_string + " "*(60 - $summary_out_string.Length) +"SUCCESS")

            $return_val = $true
        }

        #write to Summary.txt if ConsistenQualityTests has been executed
        if ([string]::IsNullOrWhiteSpace($SummaryOutputFile ) -ne $true)
        {
            Write-Output $summary_out_string |Out-File $SummaryOutputFile -Append
        }

        


        #-------------------------------------next section does an overall file count  ------------------------------

        #count the number of files
        $collectCount = ($LogsCollected | Measure-Object).Count

        #first check a simple file count

        $msg = "Total file count in the \Output folder is : " + $collectCount
        
        WriteToConsoleAndFile -Message ""
        WriteToConsoleAndFile -Message $msg
        WriteToConsoleAndFile -Message "`n************************************************************************************************`n"

        #send out success of failure message: true (success) or false (failed)
        #if the expected file count is not equal to the actual file count, then fail
        #if the expected file count is equal to the actual file count, then pass
        return $return_val

    } # end of try
    catch
    {
        $mycommand = $MyInvocation.MyCommand
        $error_msg = $PSItem.Exception.Message
        Write-Host $_.Exception.Message
        $error_linenum = $PSItem.InvocationInfo.ScriptLineNumber
        $error_offset = $PSItem.InvocationInfo.OffsetInLine
        Write-LogError "Function $mycommand failed with error:  $error_msg (line: $error_linenum, $error_offset)"
        return $false
    }

}

#--------------------------------------------------------Scenario check end ------------------------------------------------------------

function main()
{
    $ret = $true

    # Call Function to set global variables that represent the various SQLLogScout output folder structures like debug, internal, output, testinginfra etc.
    if (!(Set-TestInfraOutputFolder))
    {
        Write-Host "Cannot continue test due to missing folders. Exiting..." -ForegroundColor Red
        return
    }

    #if SQL LogScout has been run longer than 2 days ago, prompt to re-run
    $currentDate = [DateTime]::Now.AddDays(-2)


    try
    {

        # get the latest sqllogscoutlog file and full path
        $sqllogscoutlog = Get-Childitem -Path $global:sqllogscout_latest_output_internal_logpath -Filter $global:sqllogscout_log

        # if check for the file $SqlLogScoutLog
        if (!(Test-Path -Path $sqllogscoutlog))
        {
            throw "SQLLogScoutLog file or path are invalid. Exiting..."
        }

        if ($sqllogscoutlog.LastWriteTime -gt $currentDate)
        {

            # discover scenarios
			[string[]]$scenStrArray = DiscoverScenarios -SqlLogscoutLog $SqlLogscoutLog

            #crate the test results output file
            CreateTestResultsFile -ScenarioArray $scenStrArray

            #write a first line to output file
            $filemsg = "Executing file validation test from output folder: '$global:sqllogscout_latest_output_folder'`n"
            WriteToConsoleAndFile -Message $filemsg
            WriteToConsoleAndFile -Message "`n************************************************************************************************`n"

            #if there are scenarios let's validate the files
			if ($scenStrArray.Count -gt 0)
            {
                $nobasic = $false

				# check for NoBasic and set flag
				foreach($str_scn in $scenStrArray)
                {
                    if ($str_scn -eq "NoBasic")
                    {
                        $nobasic = $true
                    }
                }

                #iterates through the array of scenarios and executes file validation for each of them
                foreach($str_scn in $scenStrArray)
                {
                    WriteToConsoleAndFile -Message ("Scenario: '$str_scn'")

                    if ($str_scn -eq "NoBasic")
                    {
                        WriteToConsoleAndFile -Message "`n************************************************************************************************`n"
                        continue
                    }

                    #validate the file
                    $ret = FileCountAndFileTypeValidation -scenario_string $str_scn -IsNoBasic $nobasic
                }
            }
            else
            {
                WriteToConsoleAndFile -Message "No valid Scenario found to process. Exiting"
                return $false

            }
        }
        else
        {
            Write-Host 'The collected files are old. Please re-run the SQL LogScout and collect more recent logs.......' -ForegroundColor Red
            return $false
        }

        Write-Host "`n`n"
        $msg = "Testing has been completed, the reports are at: " + $global:sqllogscout_testing_infrastructure_output_folder
        Write-Host $msg

        #send out success of failure message: true (success) or false (failed) that came from FileCountAndFileTypeValidation
        return $ret

    }
    catch
    {
        $mycommand = $MyInvocation.MyCommand
        $error_msg = $PSItem.Exception.Message
        Write-Host $_.Exception.Message
        $error_linenum = $PSItem.InvocationInfo.ScriptLineNumber
        $error_offset = $PSItem.InvocationInfo.OffsetInLine
        Write-LogError "Function '$mycommand' in 'FileCountAndTypeValidation.ps1' failed with error:  $error_msg (line: $error_linenum, $error_offset)"
    }
}

main

# SIG # Begin signature block
# MIIoPAYJKoZIhvcNAQcCoIIoLTCCKCkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAFnc1HbVomz8ru
# v1gdsOndWpASoAm+REhPMb7MLPUBb6CCDYUwggYDMIID66ADAgECAhMzAAADri01
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
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCGg0wghoJAgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAOuLTVRyFOPVR0AAAAA
# A64wDQYJYIZIAWUDBAIBBQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKpV
# kCeD+DgZEgu5nO7Po00YZSTIBaYmZP2XJEbH15QjMEQGCisGAQQBgjcCAQwxNjA0
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEcgBpodHRwczovL3d3d3cubWljcm9zb2Z0
# LmNvbTANBgkqhkiG9w0BAQEFAASCAQDeKLuYoXgAFEe9lYzLyPcLmArdJQDiHBO8
# cbc3d9bik1rq54o54A4dI+cV2wawCQZVqRYuiLoidQfghALH/Z7rUEVFD9UXmDgq
# 03R+C6tfhRjmrnQPcVeapfvmThP93OfmM4hgMAudHRHKCpHEzak3E6hQOFxblBnO
# uFzA5bxLWpjp4CJ+2Pz3TI4UWHD0OE8KBYgn21nRsezoo3cutyagxs3OOm6veNBl
# YxMvXyWPjCJoOM+1K/4z87cVIQKjJjKr+4ZzeBCxVUFgWcFRV127cDbnKUr9m+q0
# NNnHaB/UpcpZRwU57XLSqYeD4pKf42jiB0TjhDdHduClK/qyiqckoYIXlTCCF5EG
# CisGAQQBgjcDAwExgheBMIIXfQYJKoZIhvcNAQcCoIIXbjCCF2oCAQMxDzANBglg
# hkgBZQMEAgEFADCCAVEGCyqGSIb3DQEJEAEEoIIBQASCATwwggE4AgEBBgorBgEE
# AYRZCgMBMDEwDQYJYIZIAWUDBAIBBQAEILfARhlsj5CnsaAbhWkgVoXzulRQdOr0
# uJURr80a3ajBAgZlzf7wRFAYEjIwMjQwMjE2MDkwMDM1Ljc5WjAEgAIB9KCB0aSB
# zjCByzELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
# B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UE
# CxMcTWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVs
# ZCBUU1MgRVNOOjkyMDAtMDVFMC1EOTQ3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBTZXJ2aWNloIIR7DCCByAwggUIoAMCAQICEzMAAAHnLo8vkwtPG+kA
# AQAAAecwDQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
# MTAwHhcNMjMxMjA2MTg0NTE5WhcNMjUwMzA1MTg0NTE5WjCByzELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFt
# ZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOjkyMDAt
# MDVFMC1EOTQ3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNl
# MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAwlefL+CLkOufVzzNQ7Wl
# jL/fx0VAuZHYhBfPWAT+v0Z+5I6jJGeREnpn+RJYuAi7UFUnn0aRdY+0uSyyorDF
# jhkWi3GlWxk33JiNbzESdbczMAjSKAqv78vFh/EHVdQfwG+bCvkPciL8xsOO031z
# xPEZa2rsCv3vp1p8DLdOtGpBGYiSc9VYdS4UmCmoj/WdtxGZhhEwlooJCm3LgJ4b
# 4d8qzGvPbgX2nh0GRBxkKnbJDOPBAXFklnaYkkgYgMcoR1JG5J5fTz87Qf0lMc0W
# Y1M1h4PW39ZqmdHCIgFgtBIyuzjYZUHykkR1SyizT6Zd//lC+F43NGL3anPPIDi1
# K//OE/f8Sua/Nrpb0adgPP2q/XBuFu+udLimgMUQJoC+ISoCF+f9GiALG8qiTmuj
# iBkhfWvg315dS6UDzSke/drHBe7Yw+VqsCLon0vWFIhzL0S44ypNEkglf5qVwtAa
# D5JOWrH8a6yWwrCXjx0jhG5aSc0Zs2j+jjF8EXK2+01xUDrE5CrqpFr72CD71cwu
# vFDPjLJCz5XdXqnTjjCu0m239rRkmX9/ojsFkDHFlwfYMOYCtwCGCtPFpCSbssz6
# n4rYLm3UQpmK/QlbDTrlvsBw2BoXIiQxdi5K45BVI1HF0iCXfX9rLGIrWfQrqxle
# +AUHH68Y75NS/I77Te5rpSMCAwEAAaOCAUkwggFFMB0GA1UdDgQWBBTP/uCYgJ82
# OHaRH/2Za4dSu96PWDAfBgNVHSMEGDAWgBSfpxVdAF5iXYP05dJlpxtTNRnpcjBf
# BgNVHR8EWDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
# L2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcmww
# bAYIKwYBBQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jvc29m
# dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0El
# MjAyMDEwKDEpLmNydDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUF
# BwMIMA4GA1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsFAAOCAgEAdKHw25PpZVot
# XAup7H4nuSbadPaOm+gEQqb7Qz6tihT/oYvlDTT+yxnIirnJKlwpgUxSIXwXhksb
# 5OsnKJHUK9/NeaRDmmFk5x70NPvISsvOq9ReK3wbuKBweXE8tPE+KIaxvzmBvwf4
# DZ89Dper+7v6hI8+PM12emZcShsmcCpimVmgXdg2BMMyqXS5AcbOgOnp1mUdI2Pq
# uRXW1eOYIRkyoEq+RAgDpyw+J4ycH4yKtJkWVsA2UKF7SUmlR0rtpR0C92BxBYpL
# p21EyXzXwQyy+xr/rE5kYg2ZMuTgMaCxtoGk37ohW36Zknz3IJeQjlM3zEJ86Sn1
# +vhZCNEEDb7j6VrA1PLEfrp4tlZg6O65qia6JuIoYFTXS2jHzVKrwS+WYkitc5mh
# CwSfWvmDoxOaZkmq1ubBm5+4lZBdlvSUCDh+rRlixSUuR7N+s2oZKB4fIg/ety3h
# o2apBbrCmlFu9sjI/8sU3hhAzqCK9+ZMF8a9VLvs5Lq9svhbjWNKGY6ac6feQFtZ
# XoT9MWjvqAVdV372grq/weT1QKdsc66LDBFHAMKSaYqPlWHyLnxo+5nl3BkGFgPF
# Jq/CugLqPiZY/CHhUupUryoakKZnQcwDBqjzkCrdTsN2V8XoSu7wIopt2YgC5TNC
# ueOpNLGa8XWT4KZs+zvMPYBy7smQEHswggdxMIIFWaADAgECAhMzAAAAFcXna54C
# m0mZAAAAAAAVMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZp
# Y2F0ZSBBdXRob3JpdHkgMjAxMDAeFw0yMTA5MzAxODIyMjVaFw0zMDA5MzAxODMy
# MjVaMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNV
# BAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMIICIjANBgkqhkiG9w0B
# AQEFAAOCAg8AMIICCgKCAgEA5OGmTOe0ciELeaLL1yR5vQ7VgtP97pwHB9KpbE51
# yMo1V/YBf2xK4OK9uT4XYDP/XE/HZveVU3Fa4n5KWv64NmeFRiMMtY0Tz3cywBAY
# 6GB9alKDRLemjkZrBxTzxXb1hlDcwUTIcVxRMTegCjhuje3XD9gmU3w5YQJ6xKr9
# cmmvHaus9ja+NSZk2pg7uhp7M62AW36MEBydUv626GIl3GoPz130/o5Tz9bshVZN
# 7928jaTjkY+yOSxRnOlwaQ3KNi1wjjHINSi947SHJMPgyY9+tVSP3PoFVZhtaDua
# Rr3tpK56KTesy+uDRedGbsoy1cCGMFxPLOJiss254o2I5JasAUq7vnGpF1tnYN74
# kpEeHT39IM9zfUGaRnXNxF803RKJ1v2lIH1+/NmeRd+2ci/bfV+AutuqfjbsNkz2
# K26oElHovwUDo9Fzpk03dJQcNIIP8BDyt0cY7afomXw/TNuvXsLz1dhzPUNOwTM5
# TI4CvEJoLhDqhFFG4tG9ahhaYQFzymeiXtcodgLiMxhy16cg8ML6EgrXY28MyTZk
# i1ugpoMhXV8wdJGUlNi5UPkLiWHzNgY1GIRH29wb0f2y1BzFa/ZcUlFdEtsluq9Q
# BXpsxREdcu+N+VLEhReTwDwV2xo3xwgVGD94q0W29R6HXtqPnhZyacaue7e3Pmri
# Lq0CAwEAAaOCAd0wggHZMBIGCSsGAQQBgjcVAQQFAgMBAAEwIwYJKwYBBAGCNxUC
# BBYEFCqnUv5kxJq+gpE8RjUpzxD/LwTuMB0GA1UdDgQWBBSfpxVdAF5iXYP05dJl
# pxtTNRnpcjBcBgNVHSAEVTBTMFEGDCsGAQQBgjdMg30BATBBMD8GCCsGAQUFBwIB
# FjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9y
# eS5odG0wEwYDVR0lBAwwCgYIKwYBBQUHAwgwGQYJKwYBBAGCNxQCBAweCgBTAHUA
# YgBDAEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAU
# 1fZWy4/oolxiaNE9lJBb186aGMQwVgYDVR0fBE8wTTBLoEmgR4ZFaHR0cDovL2Ny
# bC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0XzIw
# MTAtMDYtMjMuY3JsMFoGCCsGAQUFBwEBBE4wTDBKBggrBgEFBQcwAoY+aHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXRfMjAxMC0w
# Ni0yMy5jcnQwDQYJKoZIhvcNAQELBQADggIBAJ1VffwqreEsH2cBMSRb4Z5yS/yp
# b+pcFLY+TkdkeLEGk5c9MTO1OdfCcTY/2mRsfNB1OW27DzHkwo/7bNGhlBgi7ulm
# ZzpTTd2YurYeeNg2LpypglYAA7AFvonoaeC6Ce5732pvvinLbtg/SHUB2RjebYIM
# 9W0jVOR4U3UkV7ndn/OOPcbzaN9l9qRWqveVtihVJ9AkvUCgvxm2EhIRXT0n4ECW
# OKz3+SmJw7wXsFSFQrP8DJ6LGYnn8AtqgcKBGUIZUnWKNsIdw2FzLixre24/LAl4
# FOmRsqlb30mjdAy87JGA0j3mSj5mO0+7hvoyGtmW9I/2kQH2zsZ0/fZMcm8Qq3Uw
# xTSwethQ/gpY3UA8x1RtnWN0SCyxTkctwRQEcb9k+SS+c23Kjgm9swFXSVRk2XPX
# fx5bRAGOWhmRaw2fpCjcZxkoJLo4S5pu+yFUa2pFEUep8beuyOiJXk+d0tBMdrVX
# VAmxaQFEfnyhYWxz/gq77EFmPWn9y8FBSX5+k77L+DvktxW/tM4+pTFRhLy/AsGC
# onsXHRWJjXD+57XQKBqJC4822rpM+Zv/Cuk0+CQ1ZyvgDbjmjJnW4SLq8CdCPSWU
# 5nR0W2rRnj7tfqAxM328y+l7vzhwRNGQ8cirOoo6CGJ/2XBjU02N7oJtpQUQwXEG
# ahC0HVUzWLOhcGbyoYIDTzCCAjcCAQEwgfmhgdGkgc4wgcsxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVy
# aWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjo5MjAwLTA1
# RTAtRDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaIj
# CgEBMAcGBSsOAwIaAxUAs3IE5xmrEsHv3a7vnD3tTRf78EOggYMwgYCkfjB8MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNy
# b3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQsFAAIFAOl4fT8w
# IhgPMjAyNDAyMTUxMjA4MzFaGA8yMDI0MDIxNjEyMDgzMVowdjA8BgorBgEEAYRZ
# CgQBMS4wLDAKAgUA6Xh9PwIBADAJAgEAAgFxAgH/MAcCAQACAhJYMAoCBQDpec6/
# AgEAMDYGCisGAQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSCh
# CjAIAgEAAgMBhqAwDQYJKoZIhvcNAQELBQADggEBAGl618a7bu9Z/cfumnef9d4Y
# 51qSXYvZiUSgYAj2erL3GxjpyCtm1yfS0c+01+eJ2YHWeoGAiE3zU6OZku8KI5sR
# 1dbSz3cszc2794Z1QBSHCXkYPb2isPS7ZwcyPNLgTaw/4/tvCcO2C4el5Ryny1cy
# Cvl451nkYZBAo5mOvHKsQrjEVywt9GDL5yJlXwNgXPASpmktlic7fkLIm2FijabM
# o+aCFWZbjHFFrciSt4uXeZAOpjeqxwLdmJhwm6YcXfkdaOpXm5E8j2seEPoHlDZE
# A2CiN8PEoV9iU5iOSjIml/ZiC28ac0ND9sfATHrCxiZMdYtk1qyjJM+kOpNlIc8x
# ggQNMIIECQIBATCBkzB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3Rv
# bjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
# aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAA
# Aecujy+TC08b6QABAAAB5zANBglghkgBZQMEAgEFAKCCAUowGgYJKoZIhvcNAQkD
# MQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJBDEiBCAiVcdgLqHLnu7QUw1tWY+2
# r2lENSRDLrUOEw9oC9uLmTCB+gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0EIOU2
# XQ12aob9DeDFXM9UFHeEX74Fv0ABvQMG7qC51nOtMIGYMIGApH4wfDELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAHnLo8vkwtPG+kAAQAAAecwIgQgbSti
# cu2IQX7RV4aVKkhTLeEHcnBUQtthlx7T9gCQju4wDQYJKoZIhvcNAQELBQAEggIA
# aYMgVzxofV9yg4IC0a+AcNwcOYrplCYDozZ9gsQxi2kP+fJJW9FZGKBoXoj4poPl
# luv28wu9/m86k+7f2B5QhU8vhmiV5sF4IvqZYDVR6MCmF9VI28rWvfL8zsSz/Z7i
# dCpMMEvuhOhdmaRxKBLWEsnT1MqxRil81zvAKBAMY/YSq/wmNKJodP62NC2hWkA5
# 4BQjmCDKqKrF/7Z1BQ5HQiQka0/U9tVmG5zfpOl5naRvbPMhIBRLnSmOIxmpiTzl
# /SKlSDsKF5BXlIhkpWjiJVbA7mElGBp9lwfPfDKoa3fw9TUkGZJsHjjuEAif0Yzi
# ROkulhwUpkglrHgukMxbQ657BZC5QVUeMNeiTM8Q0RQr9iSl4SIVKK2+IPXxUrXq
# KIr/jfbvfLG1bh76yVqJCvyD8aGxQ5Ep/TBbcA2reFqj6i/qP6Ea5oX2joKfFGwq
# B+kazrPcXY61k3OoqFVA6S0AqM/pjQvZEm0HpeTPRO9X4q/Rvmc6/INpNr/t4sEr
# evr72MymiAzdDYumor36d9zUCyNR30UeOCKPrIg+G9S3TN5lZHUgq3NEB+ijwvoP
# T5qWCzoaiFtLHexiQtXIoClznnmOtkq65+6DHjanBSyzFjISe0BtGwmbBhvH0T5j
# h7OHQDPtf2fOk/+v/2uACOLSrE4rHE9n8N9urq6qCgo=
# SIG # End signature block
