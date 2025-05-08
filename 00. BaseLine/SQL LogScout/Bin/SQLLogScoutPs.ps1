## Copyright (c) Microsoft Corporation.
## Licensed under the MIT license.


<#
.SYNOPSIS
    SQL LogScout allows you to collect diagnostic logs from your SQL Server system to help resolve technical problems.
.DESCRIPTION
.LINK 
https://github.com/microsoft/SQL_LogScout#examples

.EXAMPLE
   SQL_LogScout.cmd

.EXAMPLE
    SQL_LogScout.cmd GeneralPerf

.EXAMPLE
    SQL_LogScout.cmd DetailedPerf SQLInstanceName "UsePresentDir"  "DeleteDefaultFolder"
.EXAMPLE
   SQL_LogScout.cmd AlwaysOn "DbSrv" "PromptForCustomDir"  "NewCustomFolder"  "2000-01-01 19:26:00" "2020-10-29 13:55:00"
.EXAMPLE
   SQL_LogScout.cmd GeneralPerf+AlwaysOn+BackupRestore "DbSrv" "d:\log" "DeleteDefaultFolder" "01-01-2000" "04-01-2021 17:00" Quiet
#>


#=======================================Script parameters =====================================
param
(
    # DebugLevel parameter is deprecated
    # SQL LogScout will generate *_DEBUG.LOG with verbose level 5 logging for all executions
    # to enable debug messages in console, modify $global:DEBUG_LEVEL in LoggingFacility.ps1
    
    #help parameter is optional parameter used to print the detailed help "/?, ? also work"
    [Parameter(ParameterSetName = 'help',Mandatory=$false)]
    [Parameter(Position=0)]
    [switch] $help,

    #Scenario an optional parameter that tells SQL LogScout what data to collect
    [Parameter(Position=1,HelpMessage='Choose a plus-sign separated list of one or more of: Basic,GeneralPerf,DetailedPerf,Replication,AlwaysOn,Memory,DumpMemory,WPR,Setup,NoBasic. Or MenuChoice')]
    [string[]] $Scenario=[String]::Empty,

    #servername\instnacename is an optional parameter since there is code that auto-discovers instances
    [Parameter(Position=2)]
    [string] $ServerName = [String]::Empty,

    #Optional parameter to use current directory or specify a different drive and path 
    [Parameter(Position=3,HelpMessage='Specify a valid path for your output folder, or type "UsePresentDir"')]
    [string] $CustomOutputPath = "PromptForCustomDir",

    #scenario is an optional parameter since there is a menu that covers for it if not present
    [Parameter(Position=4,HelpMessage='Choose DeleteDefaultFolder|NewCustomFolder')]
    [string] $DeleteExistingOrCreateNew = [String]::Empty,

    #specify start time for diagnostic
    [Parameter(Position=5,HelpMessage='Format is: "2020-10-27 19:26:00"')]
    [string] $DiagStartTime = "0000",
    
    #specify end time for diagnostic
    [Parameter(Position=6,HelpMessage='Format is: "2020-10-27 19:26:00"')]
    [string] $DiagStopTime = "0000",

    #specify quiet mode for any Y/N prompts
    [Parameter(Position=7,HelpMessage='Choose Quiet|Noisy')]
    [string] $InteractivePrompts = "Noisy",

    #scenario is an optional parameter since there is a menu that covers for it if not present. Always keep as the last parameter
    [Parameter(Position=8,Mandatory=$false,HelpMessage='Test parameter that should not be used for most collections')]
    [string] $DisableCtrlCasInput = "False"
)


#=======================================Globals =====================================

if ($global:gDisableCtrlCasInput -eq "False")
{
    [console]::TreatControlCAsInput = $true
}

[string]$global:present_directory = ""
[string]$global:output_folder = ""
[string]$global:internal_output_folder = ""
[string]$global:custom_user_directory = ""  # This is for log folder selected by user other that default
[string]$global:userLogfolderselected = ""
[string]$global:perfmon_active_counter_file = "LogmanConfig.txt"
[string]$global:restart_sqlwriter = ""
[bool]$global:perfmon_counters_restored = $false
[string]$NO_INSTANCE_NAME = "no_instance_found"
[string]$global:sql_instance_conn_str = $NO_INSTANCE_NAME #setting the connection sting to $NO_INSTANCE_NAME initially
[System.Collections.ArrayList]$global:processes = New-Object -TypeName System.Collections.ArrayList
[System.Collections.ArrayList] $global:ScenarioChoice = @()
[bool] $global:stop_automatically = $false
[string] $global:xevent_target_file = "xevent_LogScout_target"
[string] $global:xevent_session = "xevent_SQLLogScout"
[string] $global:xevent_alwayson_session = "SQLLogScout_AlwaysOn_Data_Movement"
[bool] $global:xevent_on = $false
[bool] $global:perfmon_is_on = $false
[bool] $global:perfmon_scenario_enabled = $false
[bool] $global:sqlwriter_collector_has_run = $false
[string] $global:app_version = ""
[string] $global:host_name = $env:COMPUTERNAME
[string] $global:wpr_collector_name = ""
[bool] $global:instance_independent_collection = $false
[int] $global:scenario_bitvalue  = 0
[int] $global:sql_major_version = -1
[int] $global:sql_major_build = -1
[long] $global:SQLVERSION = -1
[string] $global:procmon_folder = ""
[bool] $global:gui_mode = $false
[bool] $global:gui_Result = $false
[String[]]$global:varXevents = "xevent_AlwaysOn_Data_Movement", "xevent_core", "xevent_detailed" ,"xevent_general"
[bool] $global:is_secondary_read_intent_only = $false
[bool]$global:allow_static_data_because_service_offline = $false
[string]$global:sql_instance_service_status = ""

#constants
[string] $global:BASIC_NAME = "Basic"
[string] $global:GENERALPERF_NAME = "GeneralPerf"
[string] $global:DETAILEDPERF_NAME = "DetailedPerf"
[string] $global:REPLICATION_NAME = "Replication"
[string] $global:ALWAYSON_NAME = "AlwaysOn"
[string] $global:NETWORKTRACE_NAME = "NetworkTrace"
[string] $global:MEMORY_NAME = "Memory"
[string] $global:DUMPMEMORY_NAME = "DumpMemory"
[string] $global:WPR_NAME = "WPR"
[string] $global:SETUP_NAME = "Setup"
[string] $global:BACKUPRESTORE_NAME = "BackupRestore"
[string] $global:IO_NAME = "IO"
[string] $global:LIGHTPERF_NAME = "LightPerf"
[string] $global:NOBASIC_NAME = "NoBasic"
[string] $global:PROCMON_NAME = "ProcessMonitor"
[string] $global:SSB_DBMAIL_NAME = "ServiceBrokerDBMail"
[string] $global:Never_Ending_Query_NAME = "NeverEndingQuery"


#MenuChoice and NoBasic will not go into this array as they don't need to show up as menu choices
[string[]] $global:ScenarioArray = @(
    $global:BASIC_NAME,
    $global:GENERALPERF_NAME,
    $global:DETAILEDPERF_NAME,
    $global:REPLICATION_NAME,
    $global:ALWAYSON_NAME,
    $global:NETWORKTRACE_NAME,
    $global:MEMORY_NAME,
    $global:DUMPMEMORY_NAME,
    $global:WPR_NAME,
    $global:SETUP_NAME,
    $global:BACKUPRESTORE_NAME,
    $global:IO_NAME,
    $global:LIGHTPERF_NAME,
    $global:PROCMON_NAME,
    $global:SSB_DBMAIL_NAME,
    $global:Never_Ending_Query_NAME)


# documenting the bits
# 000000000000000001 (1)   = Basic
# 000000000000000010 (2)   = GeneralPerf
# 000000000000000100 (4)   = DetailedPerf
# 000000000000001000 (8)   = Replication
# 000000000000010000 (16)  = alwayson
# 000000000000100000 (32)  = networktrace
# 000000000001000000 (64)  = memory
# 000000000010000000 (128) = DumpMemory
# 000000000100000000 (256) = WPR
# 000000001000000000 (512) = Setup
# 000000010000000000 (1024)= BackupRestore
# 000000100000000000 (2048)= IO
# 000001000000000000 (4096)= LightPerf
# 000010000000000000 (8192)= NoBasicBit
# 000100000000000000 (16384)= ProcmonBit
# 001000000000000000 (32768)= ServiceBrokerDBMail
# 010000000000000000 (65536)= neverEndingQuery
# 100000000000000000 (131072) = futureBit

[int] $global:basicBit         = 1
[int] $global:generalperfBit   = 2 
[int] $global:detailedperfBit  = 4
[int] $global:replBit          = 8
[int] $global:alwaysonBit      = 16
[int] $global:networktraceBit  = 32
[int] $global:memoryBit        = 64
[int] $global:dumpMemoryBit    = 128
[int] $global:wprBit           = 256
[int] $global:setupBit         = 512
[int] $global:BackupRestoreBit = 1024
[int] $global:IOBit            = 2048
[int] $global:LightPerfBit     = 4096
[int] $global:NoBasicBit       = 8192
[int] $global:ProcmonBit       = 16384
[int] $global:ssbDbmailBit     = 32768
[int] $global:neverEndingQBit  = 65536
[int] $global:futureScBit      = 131072

#globals to map script parameters into
[string[]] $global:gScenario
[string] $global:gServerName
[string] $global:gDeleteExistingOrCreateNew
[string] $global:gDiagStartTime
[string] $global:gDiagStopTime
[string] $global:gInteractivePrompts
[string] $global:gDisableCtrlCasInput


$global:ScenarioBitTbl = @{}
$global:ScenarioMenuOrdinals = @{}

#hashtable to use for lookups bits to names and reverse

$global:ScenarioBitTbl.Add($global:BASIC_NAME                , $global:basicBit)
$global:ScenarioBitTbl.Add($global:GENERALPERF_NAME          , $global:generalperfBit)
$global:ScenarioBitTbl.Add($global:DETAILEDPERF_NAME         , $global:detailedperfBit)
$global:ScenarioBitTbl.Add($global:REPLICATION_NAME          , $global:replBit)
$global:ScenarioBitTbl.Add($global:ALWAYSON_NAME             , $global:alwaysonBit)
$global:ScenarioBitTbl.Add($global:NETWORKTRACE_NAME         , $global:networktraceBit)
$global:ScenarioBitTbl.Add($global:MEMORY_NAME               , $global:memoryBit)
$global:ScenarioBitTbl.Add($global:DUMPMEMORY_NAME           , $global:dumpMemoryBit)
$global:ScenarioBitTbl.Add($global:WPR_NAME                  , $global:wprBit)
$global:ScenarioBitTbl.Add($global:SETUP_NAME                , $global:setupBit)
$global:ScenarioBitTbl.Add($global:BACKUPRESTORE_NAME        , $global:BackupRestoreBit)
$global:ScenarioBitTbl.Add($global:IO_NAME                   , $global:IOBit)
$global:ScenarioBitTbl.Add($global:LIGHTPERF_NAME            , $global:LightPerfBit)
$global:ScenarioBitTbl.Add($global:NOBASIC_NAME              , $global:NoBasicBit)
$global:ScenarioBitTbl.Add($global:PROCMON_NAME              , $global:ProcmonBit)
$global:ScenarioBitTbl.Add($global:SSB_DBMAIL_NAME           , $global:ssbDbmailBit)
$global:ScenarioBitTbl.Add($global:Never_Ending_Query_NAME   , $global:neverEndingQBit)
$global:ScenarioBitTbl.Add("FutureScen"                      , $global:futureScBit)

#hashtable for menu ordinal numbers to be mapped to bits

$global:ScenarioMenuOrdinals.Add(0  , $global:ScenarioBitTbl[$global:BASIC_NAME]        )
$global:ScenarioMenuOrdinals.Add(1  , $global:ScenarioBitTbl[$global:GENERALPERF_NAME]  )
$global:ScenarioMenuOrdinals.Add(2  , $global:ScenarioBitTbl[$global:DETAILEDPERF_NAME] )
$global:ScenarioMenuOrdinals.Add(3  , $global:ScenarioBitTbl[$global:REPLICATION_NAME]  )
$global:ScenarioMenuOrdinals.Add(4  , $global:ScenarioBitTbl[$global:ALWAYSON_NAME]     )
$global:ScenarioMenuOrdinals.Add(5  , $global:ScenarioBitTbl[$global:NETWORKTRACE_NAME] )
$global:ScenarioMenuOrdinals.Add(6  , $global:ScenarioBitTbl[$global:MEMORY_NAME]       )
$global:ScenarioMenuOrdinals.Add(7  , $global:ScenarioBitTbl[$global:DUMPMEMORY_NAME]   )
$global:ScenarioMenuOrdinals.Add(8  , $global:ScenarioBitTbl[$global:WPR_NAME]          )
$global:ScenarioMenuOrdinals.Add(9  , $global:ScenarioBitTbl[$global:SETUP_NAME]        )
$global:ScenarioMenuOrdinals.Add(10 , $global:ScenarioBitTbl[$global:BACKUPRESTORE_NAME])
$global:ScenarioMenuOrdinals.Add(11 , $global:ScenarioBitTbl[$global:IO_NAME]           )
$global:ScenarioMenuOrdinals.Add(12 , $global:ScenarioBitTbl[$global:LIGHTPERF_NAME]    )
$global:ScenarioMenuOrdinals.Add(13 , $global:ScenarioBitTbl[$global:PROCMON_NAME]      )
$global:ScenarioMenuOrdinals.Add(14 , $global:ScenarioBitTbl[$global:SSB_DBMAIL_NAME]   )
$global:ScenarioMenuOrdinals.Add(15 , $global:ScenarioBitTbl[$global:Never_Ending_Query_NAME]   )

# synchronizable hashtable (collection) to be used for thread synchronization
[hashtable] $global:xevent_ht = @{}
$global:xevent_ht.IsSynchronized = $true

#SQLSERVERPROPERTY list will be popluated during intialization
$global:SQLSERVERPROPERTYTBL = @{}

$global:SqlServerVersionsTbl = @{}

#SQLCMD objects reusing the same connection to query SQL Server where needed is more efficient.
[System.Data.SqlClient.SqlConnection] $global:SQLConnection
[System.Data.SqlClient.SqlCommand] $global:SQLCcommand

#=======================================Start of \OUTPUT and \INTERNAL directories and files Section
#======================================== START of Process management section
if ($PSVersionTable.PSVersion.Major -gt 4) { Import-Module .\GUIHandler.psm1 }
Import-Module .\CommonFunctions.psm1
#=======================================End of \OUTPUT and \INTERNAL directories and files Section
#======================================== END of Process management section


#======================================== START OF NETNAME + INSTANCE SECTION - Instance Discovery
Import-Module .\InstanceDiscovery.psm1
#======================================== END OF NETNAME + INSTANCE SECTION - Instance Discovery


#======================================== START of Console LOG SECTION
Import-Module .\LoggingFacility.psm1
#======================================== END of Console LOG SECTION

#======================================== START of File Attribute Validation SECTION
Import-Module .\Confirm-FileAttributes.psm1
#======================================== END of File Attribute Validation SECTION

#======================================== START of File Attribute Validation SECTION
Import-Module .\SQLLogScoutPs.psm1 -DisableNameChecking
#======================================== END of File Attribute Validation SECTION


function PrintHelp ([string]$ValidArguments ="", [int]$index=777, [bool]$brief_help = $true)
{
   Try
   { 
       if ($brief_help -eq $true)
       {

           $HelpStr = "`n[-Help <string>] " 
           $scenarioHlpStr = "`n[-Scenario <string[]>] "
           $serverInstHlpStr = "`n[-ServerName <string>] " 
           $customOutputPathHlpStr = "`n[-CustomOutputPath <string>] "
           $delExistingOrCreateNewHlpStr = "`n[-DeleteExistingOrCreateNew <string>] "
           $DiagStartTimeHlpStr = "`n[-DiagStartTime <string>] "
           $DiagStopTimeHlpStr = "`n[-DiagStopTime <string>] "
           $InteractivePromptsHlpStr = "`n[-InteractivePrompts <string>] "
           $DisableCtrlCasInputHlpStr = "`n[-DisableCtrlCasInput <string>] "
       
        

           switch ($index) 
           {
               0 { $HelpStr = $HelpStr + "< " + $ValidArguments +" >"}
               1 { $scenarioHlpStr = $scenarioHlpStr + "< " + $ValidArguments +" >"}
               2 { $serverInstHlpStr = $serverInstHlpStr + "< " + $ValidArguments +" >"}
               3 { $customOutputPathHlpStr = $customOutputPathHlpStr + "< " + $ValidArguments +" >"}
               4 { $delExistingOrCreateNewHlpStr = $delExistingOrCreateNewHlpStr + "< " + $ValidArguments +" >"}
               5 { $DiagStartTimeHlpStr= $DiagStartTimeHlpStr + "< " + $ValidArguments +" >"}
               6 { $DiagStopTimeHlpStr = $DiagStopTimeHlpStr + "< " + $ValidArguments +" >"}
               7 { $InteractivePromptsHlpStr = $InteractivePromptsHlpStr + "< " + $ValidArguments +" >"}
               8 { $DisableCtrlCasInputHlpStr = $DisableCtrlCasInputHlpStr + "< " + $ValidArguments +" >"}
           }

   

       $HelpString = "`nSQL_LogScout `n" `
       + $scenarioHlpStr `
       + $serverInstHlpStr `
       + $customOutputPathHlpStr `
       + $delExistingOrCreateNewHlpStr `
       + $DiagStartTimeHlpStr`
       + $DiagStopTimeHlpStr `
       + $InteractivePromptsHlpStr ` + "`n" `
       + "`nExample: `n" `
       + "  SQL_LogScout.cmd GeneralPerf+AlwaysOn+BackupRestore DbSrv `"d:\log`" DeleteDefaultFolder `"01-01-2000`" `"04-01-2021 17:00`" Quiet`n"


           Microsoft.PowerShell.Utility\Write-Host $HelpString
        }
        else {
    

            Microsoft.PowerShell.Utility\Write-Host "

            sql_logscout.cmd [-Scenario <string[]>] [-ServerInstanceConStr <string>] [-CustomOutputPath <string>] [-DeleteExistingOrCreateNew <string>] [-DiagStartTime <string>] [-DiagStopTime <string>] [-InteractivePrompts <string>] [<CommonParameters>]
        
            DESCRIPTION
                SQL LogScout allows you to collect diagnostic logs from your SQL Server 
                system to help you and Microsoft technical support engineers (CSS) to 
                resolve SQL Server technical incidents faster. 
            
            ONLINE HELP:    
                You can find help for SQLLogScout help PowerShell online  
                at https://github.com/microsoft/sql_logscout 

            EXAMPLES:
                A. Execute SQL LogScout (most common execution)
                This is the most common method to execute SQL LogScout which allows you to pick your choices from a menu of options " -ForegroundColor Green

            Microsoft.PowerShell.Utility\Write-Host " "
            Microsoft.PowerShell.Utility\Write-Host "               SQL_LogScout.cmd"

            Microsoft.PowerShell.Utility\Write-Host "
                B. Execute SQL LogScout using a specific scenario. This command starts the diagnostic collection with 
                the GeneralPerf scenario." -ForegroundColor Green

            Microsoft.PowerShell.Utility\Write-Host " "
            Microsoft.PowerShell.Utility\Write-Host "               SQL_LogScout.cmd GeneralPerf" 
            
            Microsoft.PowerShell.Utility\Write-Host "
                C. Execute SQL LogScout by specifying folder creation option
                Execute SQL LogScout using the DetailedPerf Scenario, specifies the Server name, 
                use the present directory and folder option to delete the default \output folder if present" -ForegroundColor Green

            Microsoft.PowerShell.Utility\Write-Host " "
            Microsoft.PowerShell.Utility\Write-Host "               SQL_LogScout.cmd DetailedPerf SQLInstanceName ""UsePresentDir""  ""DeleteDefaultFolder"" "
            
            Microsoft.PowerShell.Utility\Write-Host "
                D. Execute SQL LogScout with start and stop times
            
                The following example collects the AlwaysOn scenario against the ""DbSrv""  default instance, 
                prompts user to choose a custom path and a new custom subfolder, and sets the stop time to some time in the future, 
                while setting the start time in the past to ensure the collectors start without delay. " -ForegroundColor Green

            Microsoft.PowerShell.Utility\Write-Host " "
            Microsoft.PowerShell.Utility\Write-Host "               SQL_LogScout.cmd AlwaysOn ""DbSrv"" ""PromptForCustomDir""  ""NewCustomFolder""  ""2000-01-01 19:26:00"" ""2020-10-29 13:55:00""  "


            Microsoft.PowerShell.Utility\Write-Host "
                Note: All parameters are required if you need to specify the last parameter. For example, if you need to specify stop time, 
                the prior parameters have to be passed.

                E. Execute SQL LogScout with multiple scenarios and in Quiet mode

                The example collects logs for GeneralPerf, AlwaysOn, and BackupRestore scenarios against the a default instance, 
                re-uses the default \output folder but creates it in the ""D:\Log"" custom path, and sets the stop time to some time in the future, 
                while setting the start time in the past to ensure the collectors start without delay. It also automatically accepts the prompts 
                by using Quiet mode and helps a full automation with no interaction." -ForegroundColor Green

                Microsoft.PowerShell.Utility\Write-Host " "
                Microsoft.PowerShell.Utility\Write-Host "               SQL_LogScout.cmd GeneralPerf+AlwaysOn+BackupRestore ""DbSrv"" ""d:\log"" ""DeleteDefaultFolder"" ""01-01-2000"" ""04-01-2021 17:00"" Quiet "
            
            Microsoft.PowerShell.Utility\Write-Host "
                Note: Selecting Quiet mode implicitly selects ""Y"" to all the screens that requires your agreement to proceed."  -ForegroundColor Green
        
            Microsoft.PowerShell.Utility\Write-Host ""
        }

        #Exit the program at this point
        #exit
    }
   catch 
   {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
   }
}


function ValidateParameters ()
{
     if ($help -eq $true) #""/?",  "?",--help",
     {
        PrintHelp -ValidArguments "" -brief_help $false
        return $false
     }



    #validate the Scenario parameter
    if ([String]::IsNullOrEmpty($Scenario) -eq $false)
    {

        $ScenarioArrayParam = $Scenario.Split('+')

        # use the global scenario Array , but also add the command-line only parameters MenuChoice and NoBasic as valid options
        [string[]] $localScenArray = $global:ScenarioArray
        $localScenArray+="MenuChoice"
        $localScenArray+="NoBasic"

        try 
        {
            foreach ($scenItem in $ScenarioArrayParam)
            {
                if (($localScenArray -notcontains $scenItem))
                {
                    Write-LogError "Parameter 'Scenario' only accepts these values individually or combined, separated by '+' (e.g Basic+AlwaysOn):`n $localScenArray. Current value '$scenItem' is incorrect."
                    PrintHelp -ValidArguments $localScenArray -index 1
                    return $false
                }
            }

            #assign $Scenario param to a global so it can be used later
            $global:gScenario = $Scenario

        }
        catch 
        {
            HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
        }
    }
    else 
    {
        #assign $gScenario to empty string
        $global:gScenario = ""
    }
    
    #validate the $ServerName parameter - actually most of the validation happens later
    if ($null -ne $ServerName)
    {
        #assign $ServerName param to a global so it can be used later
        $global:gServerName = $ServerName
    }
    else 
    {
        Write-LogError "Parameter 'ServerName' accepts a non-null value. Value '$ServerName' is incorrect."
        PrintHelp -ValidArguments "<server\instance>" -index 2
        return $false
    }
    
        
    #validate CustomOutputPath parameter
    $global:custom_user_directory = $CustomOutputPath

    if ($true -eq [String]::IsNullOrWhiteSpace($global:custom_user_directory))
    {
        $global:custom_user_directory = "PromptForCustomDir"
    }

    $CustomOutputParamArr = @("UsePresentDir", "PromptForCustomDir")
    if( ($global:custom_user_directory -inotin $CustomOutputParamArr) -and ((Test-Path -Path $global:custom_user_directory -PathType Container) -eq $false) )
    {
        Write-LogError "Parameter 'CustomOutputPath' accepts an existing folder path OR one of these values: $CustomOutputParamArr. Value '$CustomOutputPath' is incorrect."
        PrintHelp -ValidArguments $CustomOutputParamArr -index 3
        return $false
    }
    
    #validate DeleteExistingOrCreateNew parameter
    if ([String]::IsNullOrWhiteSpace($DeleteExistingOrCreateNew) -eq $false)
    {
        $DelExistingOrCreateNewParamArr = @("DeleteDefaultFolder","NewCustomFolder")
        if($DeleteExistingOrCreateNew -inotin $DelExistingOrCreateNewParamArr)
        {
            Write-LogError "Parameter 'DeleteExistingOrCreateNew' can only accept one of these values: $DelExistingOrCreateNewParamArr. Current value '$DeleteExistingOrCreateNew' is incorrect."
            PrintHelp -ValidArguments $DelExistingOrCreateNewParamArr -index 4
            return $false
        }
        else
        {
            $global:gDeleteExistingOrCreateNew = $DeleteExistingOrCreateNew
        }
    }

    #validate DiagStartTime parameter
    if (($DiagStartTime -ne "0000") -and ($false -eq [String]::IsNullOrWhiteSpace($DiagStartTime)))
    {
        [DateTime] $dtStartOut = New-Object DateTime
        if([DateTime]::TryParse($DiagStartTime, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$dtStartOut) -eq $false)
        {
            Write-LogError "Parameter 'DiagStartTime' accepts DateTime values (e.g. `"2021-07-07 17:14:00`"). Current value '$DiagStartTime' is incorrect."
            PrintHelp -ValidArguments "yyyy-MM-dd hh:mm:ss" -index 5
            return $false
        }
        else 
        {
            $global:gDiagStartTime = $DiagStartTime
        }
    }
    

    #validate DiagStopTime parameter
    if (($DiagStopTime -ne "0000") -and ($false -eq [String]::IsNullOrWhiteSpace($DiagStopTime)))
    {
        [DateTime] $dtStopOut = New-Object DateTime
        if([DateTime]::TryParse($DiagStopTime, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$dtStopOut) -eq $false)
        {
            Write-LogError "Parameter 'DiagStopTime' accepts DateTime values (e.g. `"2021-07-07 17:14:00`"). Current value '$DiagStopTime' is incorrect."
            PrintHelp -ValidArguments "yyyy-MM-dd hh:mm:ss" -index 6
            return $false
        }
        else
        {
            $global:gDiagStopTime  = $DiagStopTime
        }
    }

    #validate InteractivePrompts parameter
    if ($true -eq [String]::IsNullOrWhiteSpace($InteractivePrompts))
    {
        # reset the parameter to default value of Noisy if it was empty space or NULL
        $global:gInteractivePrompts = "Noisy" 
    }
    else 
    {
        $global:gInteractivePrompts = $InteractivePrompts
    }


    $InteractivePromptsParamArr = @("Quiet","Noisy")
    if($global:gInteractivePrompts -inotin $InteractivePromptsParamArr)
    {
        
        Write-LogError "Parameter 'InteractivePrompts' can only accept one of these values: $InteractivePromptsParamArr. Current value '$global:gInteractivePrompts' is incorrect."
        PrintHelp -ValidArguments $InteractivePromptsParamArr -index 7
        return $false
    }

    #validate DisableCtrlCasInput parameter
    
    if ($DisableCtrlCasInput -eq "True")
    {
        #If DisableCtrlCasInput is true, then pass as true
        $global:gDisableCtrlCasInput = "True"
    }

    else 
    {
        #any value other than True or null/whitespace, set value to false.
        $global:gDisableCtrlCasInput = "False"
    }

    # return true since we got to here
    return $true
}


#print copyright message
CopyrightAndWarranty

#validate parameters
$ret = ValidateParameters

#start program
if ($ret -eq $true)
{
    Start-SQLLogScout
}


# SIG # Begin signature block
# MIIoPQYJKoZIhvcNAQcCoIIoLjCCKCoCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDLAoUelbM+RxFV
# o13s6UeuedeZllmSWZDUU9clUR48NqCCDYUwggYDMIID66ADAgECAhMzAAADri01
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
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCGg4wghoKAgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAOuLTVRyFOPVR0AAAAA
# A64wDQYJYIZIAWUDBAIBBQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIH6V
# /hcpTtiSw0lqoowfoXrCV1Hc+VvM3eJ5uuJwlwiaMEQGCisGAQQBgjcCAQwxNjA0
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEcgBpodHRwczovL3d3d3cubWljcm9zb2Z0
# LmNvbTANBgkqhkiG9w0BAQEFAASCAQDOtHaqaNfFvHgbQNA76HF2pALYsc8L1kFX
# dJVg5qPsaOFlaM07SBJEP83zW8lPk3trVc6xkWgO2pyT5eLJ/IHLRL7xiJiP4sXR
# 5hnQY9DNuYdCk2lvBhR3mg/QMjpiHoHjB2/9/RJNOmOWcyH/der1C2+bJsQwqkcz
# qAScpHvmH2jiIV7+YsY5jDGSXQSMNWVWQNB2QRs0TVT1KBtDfvOODeCK/6TJV44U
# bFC/ONRsdLy4CHckrRG9m1gXm75zECeX0ebk2avsdXHuLoz0IHsm/kcjLaOlJByb
# n2RxrkidtqREiX6DCBTLNuKMkFKjB6LNfLPshfW34yxiRuVYqhl+oYIXljCCF5IG
# CisGAQQBgjcDAwExgheCMIIXfgYJKoZIhvcNAQcCoIIXbzCCF2sCAQMxDzANBglg
# hkgBZQMEAgEFADCCAVEGCyqGSIb3DQEJEAEEoIIBQASCATwwggE4AgEBBgorBgEE
# AYRZCgMBMDEwDQYJYIZIAWUDBAIBBQAEIB22D2ongu1zAHQgRyuSPE1HZriyRBQP
# weQz7xdRcDJEAgZlzgV2/ysYEjIwMjQwMjE2MDkwMDU3LjgyWjAEgAIB9KCB0aSB
# zjCByzELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
# B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UE
# CxMcTWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVs
# ZCBUU1MgRVNOOkEwMDAtMDVFMC1EOTQ3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBTZXJ2aWNloIIR7TCCByAwggUIoAMCAQICEzMAAAHr4BhstbbvOO0A
# AQAAAeswDQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
# MTAwHhcNMjMxMjA2MTg0NTM0WhcNMjUwMzA1MTg0NTM0WjCByzELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFt
# ZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1MgRVNOOkEwMDAt
# MDVFMC1EOTQ3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNl
# MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAwRVoIdpW4Fd3iadNaKom
# hQbmGzXO4UippLbydeTawfwwW6FKMPFjzkz8W5+4HJiDhpsCZHfk8hceyjp868Z6
# Ad4br7/dX2blLoCLCk5wL4NgVP53ze2c5/SpNZqbidu0usVAx+KHRYl+dSAnCpeh
# BuHMSoHAwIp4oU/Ma6CVlQEy+6fG2358LHNaYoWZnLyLmBp29U2PbZ6XQoVq/RAE
# bgqN04kRozNi6eKYk9pQ+YZ3d1Whk3qTasmpKZAhldPnCvFbvx5CGXb8vs+RC96I
# 03RSy+byfSAKIFn91wLt3e0qRWmqHosdHtaueQA/eGcAz/os6i2nbAUd7c46tkX6
# wjS/k5ov42pUbaPyem4eHz4RxE5wwu/E9cn11EHRrZif7rSPwDcYux1fIAD84nfU
# 2IzD22KhvMucc/oCP0hco/mirRx1pisxFz7bV8wHHsSdRB+8G7olZN7BKzyvTC4N
# V2+oTORyFgNIxAGYShMneYR9lzIm82pG6drNhCUFmrEHOAzGhdRLENQs4ApQ2CGB
# uq1IbnXyO5PC/SighLn0WyuZXUWDQKnXa/8kiX7mb9z0t/r7Q+l+qtR+FDpowynY
# 6Ft6rOyUTGZh/X5BZDM2+mEs6+nl9S6GJtz6ztSXmuN0mM5Qd08/ODr7lUlezXIn
# VbTaomXllqVY32r0fiY/yTkCAwEAAaOCAUkwggFFMB0GA1UdDgQWBBR0ngWs1lXM
# buKk/TuY09gfqgHq4TAfBgNVHSMEGDAWgBSfpxVdAF5iXYP05dJlpxtTNRnpcjBf
# BgNVHR8EWDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
# L2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcmww
# bAYIKwYBBQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jvc29m
# dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0El
# MjAyMDEwKDEpLmNydDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUF
# BwMIMA4GA1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsFAAOCAgEAg3TfL6D3fAvl
# VmT9/lvO3P0G3W1itLDrfWeJBDlp4Oypoflg9i5zyUySiBGsZ4jnLfcDICfMkMsE
# fFh4Azr28KnarC1GjODa3q7SOhSPa4Y4XmisTTZwWcx2Sw8JZC/bwhA3vUXNHRkl
# XeQYNwlpJ1d7r1WrteBeeREk1iATWkEvQqaNjqc93EYAGFX2ixRmwKzXEb0lr0lG
# 3iNiA6kcQuMQW0YjUPtah1wwj59IRrF3y/spw2Z3An7Mza5YGU9uF4Ib082DB3F4
# qC1WKP9h5MqMOnSO7lCyWysS1/MB4bIsK4lyAwp4y1bBtBOW0fNkIHLHhIcW1Nnd
# UVR3ELZFBO1vc8Wamev4z5mqI2YF0Dt9148Th2GFWvwV3CLrvEjMz44wAG7o8E2s
# KWsywb/fey0QdGTmzXJCWMkEKRE0n5Td+o1vs+0f5xsiakWdx7WdZV1tX+sxAgHj
# /vXcup5nAq1XDqm0B1+2a/Fj3IIRyQAA5ZuRMT4ecYtbTUZPouhdmvUqU3kJ2Vz+
# dMPiaE8SEkKu7wYo9p4rQLEi2lXjKqD4vjV5U1DWdjXbWxa+iIq/WSvbn2s9xcX7
# w2aN+ubyzqM5kDnv2fqbuL2Ocz5rTYlSHEJxcuyWTomVQyOWyHcEEWotqrhyiepb
# VHbItx4zZ4nrhO9n0+HlocbZpzeR2AgwggdxMIIFWaADAgECAhMzAAAAFcXna54C
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
# ahC0HVUzWLOhcGbyoYIDUDCCAjgCAQEwgfmhgdGkgc4wgcsxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVy
# aWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjpBMDAwLTA1
# RTAtRDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaIj
# CgEBMAcGBSsOAwIaAxUAgAaJdbtcMMGIFLVKMDJ6mL27pd6ggYMwgYCkfjB8MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNy
# b3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQsFAAIFAOl5LKYw
# IhgPMjAyNDAyMTYwMDM2NTRaGA8yMDI0MDIxNzAwMzY1NFowdzA9BgorBgEEAYRZ
# CgQBMS8wLTAKAgUA6XkspgIBADAKAgEAAgICrAIB/zAHAgEAAgITnDAKAgUA6Xp+
# JgIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMCoAowCAIBAAIDB6Eg
# oQowCAIBAAIDAYagMA0GCSqGSIb3DQEBCwUAA4IBAQB+I1aZe3IysBIKlTEcMAVc
# vAAjq6JTS5xkV/vbt5KU5/0eoX2qSeo3fQAAeFDuPVQpk0U8SKR/+Vn2sQvj5OHD
# ls7FvXx69y5g5JXTtWbOkC4++PUKKiCE7+7EMU4QOtJvevS8zoqpbbZtgghLyoUz
# /B/M+wsjKhczrbOV5i4h9Sr20rYZ6eicTiGVMBYI3IJ3T83EZpPrhmxBsACutA2q
# 1qoyjpCIFT7hgRBK8Iuf3sm7AMTeHxL2Kk1ejnTOFUTmtlkFu5DaQwA4BRm8M+z9
# qXy2kwmnD05MKnbDFRQ4HLLXAQlFNKC+8qievuJ3rw6G3N3VLaBhb/T649Scq1q7
# MYIEDTCCBAkCAQEwgZMwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0
# b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
# dGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMA
# AAHr4BhstbbvOO0AAQAAAeswDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJ
# AzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQg7KkZ54fcEReYrkLjg5q3
# 6/Vs+sbO2dKOmzBZa7YvuOQwgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCDO
# t2u+X2kD4X/EgQ07ZNg0lICG3Ys17M++odSXYSws+DCBmDCBgKR+MHwxCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
# HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29m
# dCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB6+AYbLW27zjtAAEAAAHrMCIEIHWE
# 5qMP7isiFlUfwSxIMJ0JVUqgk8X7Gd7x3hB1wpnRMA0GCSqGSIb3DQEBCwUABIIC
# AGg9T5NcVC54Pp1y8f0CPjlTfOW2nYAwjuiwCHH67bbA5jDZMl2YlNfzXd03DLLh
# LXkay5NfA2SZbjGJxvvxjkQtf1+oFEtyuvhs01ut+VtFVfcO6fVNV1ycNDo6BgFE
# GbKZEzO7voS5uOVskxUGAWyYNIt+RF3ixyalpPAIUckWXSYzLaIaoz0/qF0Q5dgX
# XYDTNsRM2+79qnNrgYrhGspwhDzz0rZ3ARA1sXnsxN0FY/vYvwH/EcHo/GCXxPTy
# h2scaxt6NQpzLdad7/4wXDERgxFxpuUm0b65hMIXy0M9PuNlY23LUwD4AmRUii8x
# TKfK4u0X/l1ZxjK4+ZJmwmTYNPfqIYdlUMI8qx9R19Mdl4WvEODgZcjHxCrE9bkE
# UxqlOeLOcsgkTXlIvbRh4ujpOWZM5oSjnEP7r/hMPt2nluF+s8cUsEQCDwRPjKxk
# yXWNg1/tSLfhX9lpKgO/X2hQJGCkDzbtHkdZjDC1tzx9LdSQyDBbhfoeB/m2BC1/
# R8ryQ3DR8PT1ApwptFT4tj/vb0VnKw12LdHxFzxbKSzgsqf1oAT6u2hN81tZ9mKq
# I89UayKexGJ5ggsoebvZU5rhn1IwnqP3vuTVx9yfhZb7aS4z2djN/XXGge73cfEO
# eYtwEUUrwILI7zzsF9Kmr+PNasU7TLObnbQZy7qEc6VB
# SIG # End signature block
