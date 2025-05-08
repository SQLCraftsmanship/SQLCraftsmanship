
#=======================================Start of \OUTPUT and \Internal directories and files Section
function InitCriticalDirectories()
{
    try 
    {
        # This will set presentaion mode either GUI or console.
         if ($PSVersionTable.PSVersion.Major -gt 4) {
            Set-Mode
        }
        else{
            $PSVersion =$PSVersionTable.PSVersion.Major
            Write-LogWarning "Only script mode is supported on PS Version: $PSVersion"
        }
        if ($global:gui_mode) 
        {
            InitializeGUIComponent  
            if($global:gui_Result -eq $false)
            {
                exit
            }
        }
        else
        {
            #initialize this directories
            Set-PresentDirectory 
              
        }  
        Set-OutputPath
        Set-InternalPath
    }
    catch
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem  -exit_logscout $true  
    }

}


function Set-PresentDirectory()
{
	Write-LogDebug "inside" $MyInvocation.MyCommand

    try 
    {
        $global:present_directory = Convert-Path -Path "."
        Write-LogInformation "The Present folder for this collection is" $global:present_directory     
    }
    catch 
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem        
    }
    
}

function Set-OutputPath()
{

    try
    {
        Write-LogDebug "inside" $MyInvocation.MyCommand
        
        #default final directory to present directory (.)

        #parent of \Bin folder
        $parent_directory = (Get-Item $global:present_directory).Parent.FullName

        [string] $final_directory  = $parent_directory

        # if "UsePresentDir" is passed as a param value, then create where SQL LogScout runs
        if ($global:custom_user_directory -eq "UsePresentDir")
        {
            $final_directory  = $parent_directory
        }
        #if a custom directory is passed as a parameter to the script. Parameter validation also runs Test-Path on $CustomOutputPath
        elseif (Test-Path -Path $global:custom_user_directory)
        {
            $final_directory = $global:custom_user_directory

        }
        elseif ($global:custom_user_directory -eq "PromptForCustomDir" -And !$global:gui_mode)    
        {
            $userlogfolder = Read-Host "Would your like the logs to be collected on a non-default drive and directory?" -CustomLogMessage "Prompt CustomDir Console Input:"
            $HelpMessage = "Please enter a valid input (Y or N)"

            $ValidInput = "Y","N"
            $AllInput = @()
            $AllInput += , $ValidInput
            $AllInput += , $userlogfolder
            $AllInput += , $HelpMessage

            $YNselected = validateUserInput($AllInput)
            

            if ($YNselected -eq "Y")
            {
                [string] $customOutDir = [string]::Empty

                while([string]::IsNullOrWhiteSpace($customOutDir) -or !(Test-Path -Path $customOutDir))
                {

                    $customOutDir = Read-Host "Enter an output folder with no quotes (e.g. C:\MyTempFolder or C:\My Folder)" -CustomLogMessage "Get Custom Output Folder Console Input:"
                    if ($customOutDir -eq "" -or !(Test-Path -Path $customOutDir))
                    {
                        Write-Host "'" $customOutDir "' is not a valid path. Please, enter a valid drive and folder location" -ForegroundColor Yellow
                    }
                }

                $final_directory =  $customOutDir
            }


        }

        if ($global:gui_mode)
        {
            # Seting final diretory from GUI.
            $final_directory = $Global:txtPresentDirectory.Text
        }

        #the output folder is subfolder of current folder where the tool is running
        $global:output_folder =  ($final_directory + "\output\")
    }
    catch
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
        exit
    }

}

function Set-NewOutputPath 
{
    Write-LogDebug "inside" $MyInvocation.MyCommand
    
    try 
    {
        [string] $new_output_folder_name = "_" + @(Get-Date -Format yyyyMMddTHHmmss) + "\"
        $global:output_folder = $global:output_folder.Substring(0, ($global:output_folder.Length-1)) + $new_output_folder_name        
    }
    catch
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem  
    }
    
}



function Set-InternalPath()
{
	Write-LogDebug "inside" $MyInvocation.MyCommand
    
    try 
    {
        #the \internal folder is subfolder of \output
        $global:internal_output_folder =  ($global:output_folder  + "internal\")    
    }
    catch 
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem    
    }
}

function CreatePartialOutputFilename ([string]$server)
{
    Write-LogDebug "inside" $MyInvocation.MyCommand

    try 
    {
        if ($global:output_folder -ne "")
        {
            $server_based_file_name = $server -replace "\\", "_"
            $output_file_name = $global:output_folder + $server_based_file_name + "_" + @(Get-Date -Format "yyyyMMddTHHmmssffff")
        }
        Write-LogDebug "The server_based_file_name: " $server_based_file_name -DebugLogLevel 3
        Write-LogDebug "The output_path_filename is: " $output_file_name -DebugLogLevel 2
        
        return $output_file_name
    }
    catch 
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem    
    }
    
}

function CreatePartialErrorOutputFilename ([string]$server)
{
    Write-LogDebug "inside" $MyInvocation.MyCommand

	try 
    {
        if (($server -eq "") -or ($null -eq $server)) 
        {
            $server = $global:host_name 
        }
        
        $error_folder = $global:internal_output_folder 
        
        $server_based_file_name = $server -replace "\\", "_"
        $error_output_file_name = $error_folder + $server_based_file_name + "_" + @(Get-Date -Format "yyyyMMddTHHmmssffff")
        
        Write-LogDebug "The error_output_path_filename is: " $error_output_file_name -DebugLogLevel 2
        
        return $error_output_file_name
        
    }

    catch 
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem 
    }
}

function ReuseOrRecreateOutputFolder() 
{
    Write-LogDebug "inside" $MyInvocation.MyCommand

    Write-LogDebug "Output folder is: $global:output_folder" -DebugLogLevel 3
    Write-LogDebug "Error folder is: $global:internal_output_folder" -DebugLogLevel 3
    
    try {
    
        #delete entire \output folder and files/subfolders before you create a new one, if user chooses that
        if ($global:gui_mode) 
        {
            if($Global:overrideExistingCheckBox.IsChecked) {$DeleteOrNew = "D"}
            else{$DeleteOrNew = "N"}
        }
        elseif (Test-Path -Path $global:output_folder)  
        {
            if ([string]::IsNullOrWhiteSpace($global:gDeleteExistingOrCreateNew) )
            {
                Write-LogInformation ""
        
                [string]$DeleteOrNew = ""
                Write-LogWarning "It appears that output folder '$global:output_folder' has been used before."
                Write-LogWarning "You can choose to:"
                Write-LogWarning " - Delete (d) the \output folder contents and recreate it"
                Write-LogWarning " - Create a new (n) folder using '\Output_yyyyMMddTHHmmss' format. You can manually delete this folder in the future" 
    
                while (-not(($DeleteOrNew -eq "D") -or ($DeleteOrNew -eq "N"))) 
                {
                    $DeleteOrNew = Read-Host "Delete ('d') or create new ('n') >" -CustomLogMessage "Output folder Console input:"
                    
                    $DeleteOrNew = $DeleteOrNew.ToString().ToUpper()
                    if (-not(($DeleteOrNew -eq "D") -or ($DeleteOrNew -eq "N"))) {
                        Write-LogError ""
                        Write-LogError "Please chose [d] to delete the output folder $global:output_folder and all files inside of the folder."
                        Write-LogError "Please chose [n] to create a new folder"
                        Write-LogError ""
                    }
                }

            }

            elseif ($global:gDeleteExistingOrCreateNew -in "DeleteDefaultFolder","NewCustomFolder") 
            {
                Write-LogDebug "The DeleteExistingOrCreateNew parameter is $($global:gDeleteExistingOrCreateNew)" -DebugLogLevel 2

                switch ($global:gDeleteExistingOrCreateNew) 
                {
                    "DeleteDefaultFolder"   {$DeleteOrNew = "D"}
                    "NewCustomFolder"       {$DeleteOrNew = "N"}
                }
                
            }

        }#end of IF

        
        #Get-Childitem -Path $output_folder -Recurse | Remove-Item -Confirm -Force -Recurse  | Out-Null
        if ($DeleteOrNew -eq "D") 
        {
            #delete the existing \output folder
            if (Test-Path -Path $global:output_folder)
            {
                Remove-Item -Path $global:output_folder -Force -Recurse  | Out-Null
                Write-LogWarning "Deleted $global:output_folder and its contents"
            }
        }
        elseif ($DeleteOrNew -eq "N") 
        {

            #these two calls updates the two globals for the new output and internal folders using the \Output_yyyyMMddTHHmmss format.
            
            # [string] $new_output_folder_name = "_" + @(Get-Date -Format yyyyMMddTHHmmss) + "\"
            # $global:output_folder = $global:output_folder.Substring(0, ($global:output_folder.Length-1)) + $new_output_folder_name

            Set-NewOutputPath
            Write-LogDebug "The new output path is: $global:output_folder" -DebugLogLevel 3
        
            #call Set-InternalPath to reset the \Internal folder
            Set-InternalPath
            Write-LogDebug "The new error path is: $global:internal_output_folder" -DebugLogLevel 3
        }

        

	
        #create an output folder AND error directory in one shot (creating the child folder \internal will create the parent \output also). -Force will not overwrite it, it will reuse the folder
        New-Item -Path $global:internal_output_folder -ItemType Directory -Force | out-null 
        
        Write-LogInformation "Output path: $global:output_folder"  #DO NOT CHANGE - Message is backward compatible
        Write-LogInformation "Error  path is" $global:internal_output_folder 
    }
    catch 
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem -exit_logscout $true
        return $false
    }
}

function BuildFinalOutputFile([string]$output_file_name, [string]$collector_name, [bool]$needExtraQuotes, [string]$fileExt = ".out")
{
	Write-LogDebug "inside" $MyInvocation.MyCommand
	
    try 
    {
        $final_output_file = $output_file_name + "_" + $collector_name + $fileExt
	
        if ($needExtraQuotes)
        {
            $final_output_file = "`"" + $final_output_file + "`""
        }

        return $final_output_file
    }

    catch 
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
    }
	
}

function BuildInputScript([string]$present_directory, [string]$script_name)
{
	Write-LogDebug "inside" $MyInvocation.MyCommand
    
    try 
    {
        if($global:gui_Result -eq $true -And $global:varXevents.contains($script_name) -eq $True)
        {
            
            $input_script = "`"" + $global:internal_output_folder + $script_name +".sql" + "`""
            return $input_script
        }
        else
        {
            $input_script = "`"" + $present_directory+"\"+$script_name +".sql" + "`""
            return $input_script
        }
        
    }
    
    catch 
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem    
    }
	
}

function BuildFinalErrorFile([string]$partial_error_output_file_name, [string]$collector_name, [bool]$needExtraQuotes)
{
	Write-LogDebug "inside" $MyInvocation.MyCommand
	
    try 
    {
        $error_file = $partial_error_output_file_name + "_"+ $collector_name + "_errors.out"
	
        if ($needExtraQuotes)
        {
            $error_file = "`"" + $error_file + "`""
        }
		
	    return $error_file
    }
    catch 
    {

        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
    }
	
}


#=======================================End of \OUTPUT and \Internal directories and files Section


#======================================== START of Process management section

function StartNewProcess()
{
    param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [String] $FilePath,

        [Parameter(Mandatory=$false, Position=1)]
        [String] $ArgumentList = [String]::Empty,

        [Parameter(Mandatory=$false, Position=2)]
        [System.Diagnostics.ProcessWindowStyle] $WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Minimized,
    
        [Parameter(Mandatory=$false, Position=3)]
        [String] $RedirectStandardError = [String]::Empty,    
    
        [Parameter(Mandatory=$false, Position=4)]
        [String] $RedirectStandardOutput = [String]::Empty,

        [Parameter(Mandatory=$false, Position=5)]
        [bool] $Wait = $false
    )

    Write-LogDebug "inside" $MyInvocation.MyCommand

    if ($global:gDisableCtrlCasInput -eq "False")
    {
        [console]::TreatControlCAsInput = $true
    }

    try 
    {
        #build a hash table of parameters
            
        $StartProcessParams = @{            
            FilePath= $FilePath
        }    

        if ($ArgumentList -ne [String]::Empty)
        {
            [void]$StartProcessParams.Add("ArgumentList", $ArgumentList)     
        }

        if ($null -ne $WindowStyle)
        {
            [void]$StartProcessParams.Add("WindowStyle", $WindowStyle)     
        }

        if ($RedirectStandardOutput -ne [String]::Empty)
        {
            [void]$StartProcessParams.Add("RedirectStandardOutput", $RedirectStandardOutput)     
        }

        if ($RedirectStandardError -ne [String]::Empty)
        {
            [void]$StartProcessParams.Add("RedirectStandardError", $RedirectStandardError)     
        }

        # we will always use -PassThru because we want to keep track of processes launched
        [void]$StartProcessParams.Add("PassThru", $null)     

        if ($true -eq $Wait)
        {
            [void]$StartProcessParams.Add("Wait", $null)
        }
        #print the command executed
        Write-LogDebug $FilePath $ArgumentList

        Write-LogDebug ("StartNewProcess parameters: " + $StartProcessParams.Keys) -DebugLogLevel 5
        Write-LogDebug ("StartNewProcess parameter values: " + $StartProcessParams.Values) -DebugLogLevel 5

        # start the process
        #equivalent to $p = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -WindowStyle $WindowStyle -RedirectStandardOutput $RedirectStandardOutput -RedirectStandardError $RedirectStandardError -PassThru -Wait
        $p = Start-Process @StartProcessParams

        #touch a few properties to make sure the process object is populated with them - specifically name and start time
        $pn = $p.ProcessName
        $sh = $p.SafeHandle
        $st = $p.StartTime
        $prid = $p.Id

        Write-LogDebug "Process started: name = '$pn', id ='$prid', starttime = '$($st.ToString("yyyy-MM-dd HH:mm:ss.fff"))' " -DebugLogLevel 1

        # add the process object to the array of started processes (if it has not exited already)
        if($false -eq $p.HasExited)   
        {
            [void]$global:processes.Add($p)
        }

        # this is equivalent to a return - but used in PS to send the value to the pipeline 
        return $p

    }
    catch 
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
        return
    }
    

}

# fucntion to collect SQL SERVERPROPERTY and cahe it in $global:SQLSERVERPROPERTYTBL 
# if globla variable is populated it will use it.

function getServerproperty() 
{
    Write-LogDebug "inside " $MyInvocation.MyCommand

    $SQLSERVERPROPERTYTBL = @{}
    [String] $query 
    
    if ($global:SQLSERVERPROPERTYTBL.Count -gt 0) {
        Write-LogDebug "SQLSERVERPROPERTYTBL cached " -DebugLogLevel 2
        return $global:SQLSERVERPROPERTYTBL
    }

    $properties = "BuildClrVersion",
                    "Collation",
                    "CollationID",
                    "ComparisonStyle",
                    "ComputerNamePhysicalNetBIOS",
                    "Edition",
                    "EditionID",
                    "EngineEdition",
                    "FilestreamConfiguredLevel",
                    "FilestreamEffectiveLevel",
                    "FilestreamShareName",
                    "HadrManagerStatus",
                    "InstanceDefaultBackupPath",
                    "InstanceDefaultDataPath",
                    "InstanceDefaultLogPath",
                    "InstanceName",
                    "IsAdvancedAnalyticsInstalled",
                    "IsBigDataCluster",
                    "IsClustered",
                    "IsExternalAuthenticationOnly",
                    "IsExternalGovernanceEnabled",
                    "IsFullTextInstalled",
                    "IsHadrEnabled",
                    "IsIntegratedSecurityOnly",
                    "IsLocalDB",
                    "IsPolyBaseInstalled",
                    "IsServerSuspendedForSnapshotBackup",
                    "IsSingleUser",
                    "IsTempDbMetadataMemoryOptimized",
                    "IsXTPSupported",
                    "LCID",
                    "LicenseType",
                    "MachineName",
                    "NumLicenses",
                    "PathSeparator",
                    "ProcessID",
                    "ProductBuild",
                    "ProductBuildType",
                    "ProductLevel",
                    "ProductMajorVersion",
                    "ProductMinorVersion",
                    "ProductUpdateLevel",
                    "ProductUpdateReference",
                    "ProductVersion",
                    "ResourceLastUpdateDateTime",
                    "ResourceVersion",
                    "ServerName",
                    "SqlCharSet",
                    "SqlCharSetName",
                    "SqlSortOrder",
                    "SqlSortOrderName",
                    "SuspendedDatabaseCount"    

    foreach ($propertyName in $properties) {
        $query += "  SELECT SERVERPROPERTY ('$propertyName') as value, cast('$propertyName' as varchar(100)) as PropertyName UNION `r`n"
    }
    $query = $query.Substring(0,$query.Length - 9)

    Write-LogDebug "Serverproperty Query : $query" -DebugLogLevel 2

    $result = execSQLQuery -SqlQuery $query
    $emptyTBL =  @{Empty=$true}

    #if no connection, return null
    if ($false -eq $result)
    {
        Write-LogDebug "Failed to connect to SQL instance (may be expected behavior)" -DebugLogLevel 2
        return $emptyTBL
    }
    else 
    {
        #We connected, but resultset is blank for some reason. Return null.
        if ($result.Tables[0].rowcount -eq 0)
        {
            Write-LogDebug "No SERVERPROPERTY returned" -DebugLogLevel 2
            return $emptyTBL
        }
    }

    foreach ($row in $result.Tables[0].Rows) {
        $SQLSERVERPROPERTYTBL.add($row.PropertyName.ToString().Trim(), $row.value)
    }
    
    $global:SQLSERVERPROPERTYTBL = $SQLSERVERPROPERTYTBL

    return $SQLSERVERPROPERTYTBL
}

function getSQLConnection ([Boolean] $SkipStatusCheck = $false)
{
    Write-LogDebug "inside " $MyInvocation.MyCommand

    try
    {
        $globalCon = $global:SQLConnection

        if ( $null -eq $globalCon) 
        {
            Write-LogDebug "SQL Connection is null, initializing now" -DebugLogLevel 2

            [System.Data.SqlClient.SqlConnection] $globalCon = New-Object System.Data.SqlClient.SqlConnection
            $conString = getSQLConnectionString -SkipStatusCheck $SkipStatusCheck
            if ($false -eq $conString ) 
            {
                #we failed to get proper conneciton string
                Write-LogDebug "We failed to get connection string, check pervious messages to for more details"  -DebugLogLevel 3
            
                return $false
            }

            $globalCon.ConnectionString = $conString
            
            $globalCon.Open() | Out-Null
            
            $global:SQLConnection = $globalCon
        
        } elseif (($globalCon.GetType() -eq [System.Data.SqlClient.SqlConnection]) -and ($globalCon.State -ne "Open") )
        {
            Write-LogDebug "Connection exists and is not Open, opening now" -DebugLogLevel 2
            
            $globalCon.Open() | Out-Null
        } elseif ( $globalCon.GetType() -ne [System.Data.SqlClient.SqlConnection]) 
        {

            Write-LogError "Could not create or obtain SqlConnection object  "  $globalCon.GetType()

            return $false
        }
        
        return $globalCon

    }

    catch {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
        return $false
    }
}

function getSQLConnectionString ([Boolean] $SkipStatusCheck = $false)
{
    Write-LogDebug "inside " $MyInvocation.MyCommand

    try 
    {
        if 
        (
            ($global:sql_instance_conn_str -eq $NO_INSTANCE_NAME)    -or    
            ($true -eq $global:instance_independent_collection )     -or 
            ( ("Running" -ne $global:sql_instance_service_status) -and (-$false -eq $SkipStatusCheck) )
        )
        {
            Write-LogWarning "No SQL Server instance found, instance is offline, or instance-independent collection. Not executing SQL queries."
            return $false
        }
        elseif ([String]::IsNullOrEmpty($global:sql_instance_conn_str) -eq $false)
        {
            
            $SQLInstance = $global:sql_instance_conn_str
        } 
        else 
        {
            Write-LogError "SQL Server instance name is empty. Exiting..."
            exit
        }

        Write-LogDebug "Received parameter SQLInstance: `"$SQLInstance`"" -DebugLogLevel 2
        
        #default integrated security and encryption with trusted server certificate
        return "Server=$SQLInstance;Database=master;Application Name=SQLLogScout;Integrated Security=True;Encrypt=True;TrustServerCertificate=true;"
    }

    catch {
       HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
       return $false
    }        
}

function getSQLCommand([Boolean] $SkipStatusCheck)
{
    Write-LogDebug "inside " $MyInvocation.MyCommand

    try 
    {
     
        $SqlCmd = $global:SQLCommand
        
        if ($null -eq $SqlCmd) 
        {
            $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
            $conn = getSQLConnection($SkipStatusCheck)

            if ($false -eq $conn) {
                #failed to obtain a connection
                Write-LogDebug "Failed to get a connection object, check previous messages" -DebugLogLevel 3
                return $false
            }
            $SqlCmd.Connection = $conn
        }
        
        if ($SqlCmd.GetType() -eq [System.Data.SqlClient.SqlCommand]) 
        {
            return $SqlCmd
        }

        Write-LogDebug "Did not get a valid SQLCommand , Type : $SqlCmd.GetType() " -DebugLogLevel 2 
        
        #if type is not correct don't return it
        return $false
    }

    catch {
       HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
       return $false
    }
}

function execSQLNonQuery ($SqlQuery,[Boolean] $TestFailure = $false) 
{
    Write-LogDebug "inside " $MyInvocation.MyCommand

    return execSQLQuery -SqlQuery $SqlQuery  -Command "ExecuteNonQuery" -TestFailure $TestFailure
}

function execSQLReader($SqlQuery, $CommandBehavior, $TestFailure = $false, $CommandType = [System.Data.CommandType]::StoredProcedure)
{
    Write-LogDebug "inside " $MyInvocation.MyCommand

    return execSQLQuery -SqlQuery $SqlQuery  -Command "ExecuteReader" -CommandBehavior $CommandBehavior -TestFailure $TestFailure
}

function execSQLScalar ($SqlQuery, [int] $Timeout = 30, [Boolean] $TestFailure = $false) 
{
    Write-LogDebug "inside " $MyInvocation.MyCommand

    return execSQLQuery -SqlQuery $SqlQuery  -Command "ExecuteScalar" -Timeout $Timeout -TestFailure $TestFailure
}
function saveContentToFile() 
{
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory, Position=0)]
        [String]$content,
        [Parameter(Mandatory, Position=1)]
        [String] $fileName
    )
    
    Write-LogDebug "inside " $MyInvocation.MyCommand

    $content | out-file $fileName | Out-Null
    return $true
}
function saveSQLQuery() 
{
[CmdletBinding()]
    param 
    (
        [Parameter(Mandatory, Position=0)]
        [String]$SqlQuery,
        [Parameter(Mandatory, Position=1)]
        [String] $fileName,
        [int] $Timeout = 30,
        [Boolean] $TestFailure = $false
    )

    Write-LogDebug "inside " $MyInvocation.MyCommand

    $DS = execSQLQuery -SqlQuery $SqlQuery -Timeout $Timeout -TestFailure $TestFailure
    
    if ($DS.GetType() -eq [System.Data.DataSet])
    {
        try {
            [String] $content =""
            foreach ($row in $DS.Tables[0].Rows)
            {
                $content = $content + $row[0]
            }
            Write-LogDebug "Saving query to file $fileName"

            
            $content | out-file $fileName | Out-Null
            return $true
        } catch 
        {
            Write-LogError "Could not save query to file $fileName "
    
            $mycommand = $MyInvocation.MyCommand
            $error_msg = $PSItem.Exception.InnerException.Message
            Write-LogError "$mycommand Function failed with error:  $error_msg"
    
            return $false
        }
        

    } else {
        Write-LogDebug "Query failed, errors mabye in execSQLQuery messages " -DebugLogLevel 3
        return $false
    }
    
} #saveSQLQuery -SqlQuery -fileName

#execSQLQery connect to SQL Server using System.data objects
#The simplest way to use it is 

<#
    .SYNOPSIS
        Returns false if query fails and Dataset if it succeeds 

    .DESCRIPTION
        Returns false if query fails and Dataset if it succeeds 
        Can be used to perofrm ExecNonQuery and ExcuteReader as well

    .EXAMPLE
        execQuery -SqlQuery "SELECT 1 "
#>

function execSQLQuery()
{
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory, Position=0)]
        [String]$SqlQuery,
        [Parameter(Mandatory=$false)]
        [Boolean]$SkipStatusCheck = $false,
        [Parameter(Mandatory=$false)]
        [Boolean]$TestFailure = $false,
        [String]$Command = "SelectCommand",
        [System.Data.CommandBehavior] $CommandBehavior,
        [int] $Timeout = 30
    )
    
     Write-LogDebug "inside " $MyInvocation.MyCommand
        
     #if in Teting Mode return false immediately
     if ($TestFailure) { return $false }
     
     $permittedCommands = "SelectCommand", "ExecuteNonQuery", "ExecuteReader", "ExecuteScalar"
     
     if (-not( $permittedCommands -contains $command) ) 
     {
         Write-LogWarning "Permitted commands for execQuery are : " $permittedCommands.ToString
         exit
     }

    Write-LogDebug "Creating SqlClient objects and setting parameters" -DebugLogLevel 2
        
    $SqlCmd = getSQLCommand($SkipStatusCheck)
    
    if ($false -eq $SqlCmd) 
    {
        return $false
    }

    $SqlCmd.CommandText = $SqlQuery
    $SqlCmd.CommandTimeout = $Timeout
    
    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $DataSetResult = New-Object System.Data.DataSet

    Write-LogDebug "About to call the required command : $Command " -DebugLogLevel 2
    try {
        
        if ($Command -eq "SelectCommand") 
        {
            $SqlAdapter.SelectCommand = $SqlCmd
            $SqlAdapter.Fill($DataSetResult) | Out-Null #fill method returns rowcount, Out-Null prevents the number from being printed in console
            return $DataSetResult
        } elseif ($Command -eq "ExecuteNonQuery") 
        {           
            $SqlCmd.ExecuteNonQuery() | Out-Null
            return $true;

        } elseif ($command -eq "ExecuteScalar") {
            return $SqlCmd.ExecuteScalar()

        } elseif ($Command -eq "ExecuteReader")
        {
            #this shold eventually be passed as parameter if other function will require different return values.
            $SqlRetValue = New-Object System.Data.SqlClient.SqlParameter
            $SqlRetValue.DbType = [System.Data.DbType]::Int32
            $SqlRetValue.Direction = [System.Data.ParameterDirection]::ReturnValue
            
            $SqlCmd.Parameters.Add($SqlRetValue) | Out-Null

            #SQL Reader and ExecuteNonQuery can execute SP
            $SqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
            
            $SqlReader = $SqlCmd.ExecuteReader($CommandBehavior)

            $result = [PSCustomObject] @{
                SQLReader = $SqlReader
                ReturnValue = $SqlRetValue
            }
            
            return $result;
        }
    }
    catch 
    {
        Write-LogError "Could not connect to SQL Server instance '$SQLInstance' to perform query."

        $mycommand = $MyInvocation.MyCommand
        $error_msg = $PSItem.Exception.InnerException.Message
        Write-LogError "$mycommand Function failed with error:  $error_msg"

        # we can't connect to SQL, probably whole capture will fail, so we just abort here
        return $false
    }
}

function Start-SQLCmdProcess([string]$collector_name, [string]$input_script_name, [bool]$is_query=$false, [string]$query_text, [bool]$has_output_results=$true, [bool]$wait_sync=$false, [string]$server = $global:sql_instance_conn_str, [string]$setsqlcmddisplaywidth)
{
    Write-LogDebug "Inside" $MyInvocation.MyCommand


    if ($global:gDisableCtrlCasInput -eq "False")
    {
        [console]::TreatControlCAsInput = $true
    }


    # if query is empty and script should be populated
    # if query is populated script should be ::Empty


    try 
    {
        
        #in case CTRL+C is pressed
        HandleCtrlC

        if ($true -eq [string]::IsNullOrWhiteSpace($collector_name))
        {
            $collector_name = "blank_collector_name"
        }

        $input_script = BuildInputScript $global:present_directory $input_script_name 
        
        $executable = "sqlcmd.exe"

        #command arguments for sqlcmd; server connection, trusted connection, Hostname, wide output, and encryption negotiation
        $argument_list = "-S" + $server + " -E -Hsqllogscout -w8000 -C -N"

        #if secondary replica has read-intent, we add -KReadOnly to avoid failures on those secondaries
        if ($global:is_secondary_read_intent_only -eq $true)
        {
            $argument_list += " -KReadOnly"
        }

        #if query is passed, use the -Q parameter
        if (($is_query -eq $true) -and ([string]::IsNullOrWhiteSpace($query_text) -ne $true) )
        {
            $argument_list += " -Q`"" + $query_text + "`""
        }
        else #otherwise use an input script
        {
            $argument_list += " -i" + $input_script 
        }

        #most executions produce output - so we should include an -o parameter for SQLCMD
        if ($has_output_results -eq $true)
        {
            $partial_output_file_name = CreatePartialOutputFilename ($server)
            
            
            $output_file = BuildFinalOutputFile -output_file_name $partial_output_file_name -collector_name $collector_name -needExtraQuotes $true

            $argument_list += " -o" + $output_file
        }

        #Depending on the script executed, we may need to increase the result length. Logically we should only care about this parameter if we are writing an output file.
        
        #If $setsqlcmddisplaywidth is passed to Start-SQLCmdProcess explicitly, then use that explicit
        if (([string]::IsNullOrEmpty($setsqlcmddisplaywidth) -eq $false) -and ($has_output_results -eq $true))
        {
            $argument_list += " -y" + $setsqlcmddisplaywidth
        }

        #If $setsqlcmddisplaywidth is NOT passed to Start-SQLCmdProcess explicitly, then pass it by default with 512 hardcoded value.
        if (([string]::IsNullOrEmpty($setsqlcmddisplaywidth) -eq $true) -and ($has_output_results -eq $true))
        {
            $argument_list += " -y" + "512"
        }


        
        $partial_error_output_file_name = CreatePartialErrorOutputFilename($server)
    
        Write-LogDebug "The partial_error_output_file_name is $partial_error_output_file_name" -DebugLogLevel 3
        Write-LogDebug "The partial_output_file_name is $partial_output_file_name" -DebugLogLevel 3

        $error_file = BuildFinalErrorFile -partial_error_output_file_name $partial_error_output_file_name -collector_name ($collector_name+"_stderr") -needExtraQuotes $false 
        $stdoutput_file = BuildFinalErrorFile -partial_error_output_file_name $partial_error_output_file_name -collector_name ($collector_name+"_stdout") -needExtraQuotes $false 

        Write-LogInformation "Executing Collector: $collector_name"
        StartNewProcess -FilePath $executable -ArgumentList $argument_list -WindowStyle Hidden -RedirectStandardError $error_file -RedirectStandardOutput $stdoutput_file -Wait $wait_sync | Out-Null
        
    }
    catch 
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
        return
    }
}

#======================================== END of Process management section

#check if HADR is enabled from serverproperty
function isHADREnabled() 
{
    Write-LogDebug "Inside" $MyInvocation.MyCommand
    
    $propertiesList = $global:SQLSERVERPROPERTYTBL
    
    if (!$propertiesList) {
        #We didn't receive server properteis     
        Write-LogError " getServerproperty returned no results " 
        return $false
    }
    
    $isHadrEnabled = $propertiesList."IsHadrEnabled"

    if ($isHadrEnabled -eq "1") {
        return $True
    }
    
    return $false

}

#check if cluster - based on cluster service status and cluster registry key
function IsClustered()
{
    Write-LogDebug "Inside" $MyInvocation.MyCommand

    $ret = $false
    $error_msg = ""
        
    $clusServiceisRunning = $false
    $clusRegKeyExists = $false
    $ClusterServiceKey="HKLM:\Cluster"

    # Check if cluster service is running
    try 
    { 
        if ((Get-Service |  Where-Object  {$_.Displayname -match "Cluster Service"}).Status -eq "Running") 
        {
            $clusServiceisRunning =  $true
            Write-LogDebug "Cluster services status is running: $clusServiceisRunning  " -DebugLogLevel 2   
        }
        
        if (Test-Path $ClusterServiceKey) 
        { 
            $clusRegKeyExists  = $true
            Write-LogDebug "Cluster key $ClusterServiceKey Exists: $clusRegKeyExists  " -DebugLogLevel 2
        }

        if (($clusRegKeyExists -eq $true) -and ($clusServiceisRunning -eq $true ))
        {
            Write-LogDebug 'This is a Windows Cluster for sure!' -DebugLogLevel 2
            return $true
        }
        else 
        {
            Write-LogDebug 'This is Not a Windows Cluster!' -DebugLogLevel 2
            return $false
        }
    }
    catch 
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
    }

    return $ret
}

function Get-InstanceNameOnly([string]$NetnamePlusInstance)
{
    Write-LogDebug "inside" $MyInvocation.MyCommand

    try 
    {
        $selectedSqlInstance  = $NetnamePlusInstance.Substring($NetnamePlusInstance.IndexOf("\") + 1)
        return $selectedSqlInstance         
    }
    catch 
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
    }

}

# use this to look up Windows version
function GetWindowsVersion
{
   #Write-LogDebug "Inside" $MyInvocation.MyCommand

   try {
       $winver = [Environment]::OSVersion.Version.Major  
   }
   catch
   {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
        return
   }
   
   
   #Write-Debug "Windows version is: $winver" -DebugLogLevel 3

   return $winver;
}



#used in Catch blocks throughout
function HandleCatchBlock ([string] $function_name, [System.Management.Automation.ErrorRecord] $err_rec, [bool]$exit_logscout = $false)
{
    $error_msg = $err_rec.Exception.Message
    $error_linenum = $err_rec.InvocationInfo.ScriptLineNumber
    $error_offset = $err_rec.InvocationInfo.OffsetInLine
    $error_script = $err_rec.InvocationInfo.ScriptName
    Write-LogError "Function '$function_name' failed with error:  $error_msg (line: $error_linenum, offset: $error_offset, file: $error_script)"    

    if ($exit_logscout)
    {
        Write-LogWarning "Exiting SQL LogScout..."
        exit
    }
}

Function GetRegistryKeys
{
<#
    .SYNOPSIS
        This function is the Powershell equivalent of reg.exe        
    .DESCRIPTION
        This function writes the registry extract to an output file. It takes three parameters:
        $RegPath - This is a mandatory input paramter that accepts the registry key value
        $RegOutputFilename - This is a mandatory input parameter that takes the output file name with path to write the registry information into
        $Recurse - This is a mandatory boolean input parameter that indicates whether to recurse the given registry key to include subkeys.

    .EXAMPLE
        GetRegistryKeys -RegPath "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer" -RegOutputFilename "C:\temp\RegistryKeys\HKLM_CV_Installer_PS.txt" -Recurse $true
        Reg.exe equivalent
        reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer" /s > C:\temp\RegistryKeys\HKLM_CV_Installer_Reg.txt

        GetRegistryKeys -RegPath "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer" -RegOutputFilename "C:\temp\RegistryKeys\HKLM_CV_Installer_PS.txt"
        Reg.exe equivalent
        reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer" > C:\temp\RegistryKeys\HKLM_CV_Installer_Reg.txt
#>
    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$RegPath, #Registry Key Location
        [string]$RegOutputFilename, #Output file name
        [bool]$Recurse = $true #Get the nested subkeys for the given registry key if $recurse = true
    )
    
    try
    {
        # String used to hold the output buffer before writing to file. Introduced for performance so that disk writes can be reduced. 
        [System.Text.StringBuilder]$str_InstallerRegistryKeys = New-Object -TypeName System.Text.StringBuilder

        #Gets the registry key and only the properties of the registry keys
        Get-Item -Path  $RegPath | Out-File  -FilePath $RegOutputFilename -Encoding utf8

        #Get all nested subkeys of the given registry key and assosicated properties if $recurse = true. Only gets the first level of nested keys if $recurse = false
        if ($Recurse -eq $true)
        {
            $Keys = Get-ChildItem -recurse $RegPath
        }
        else
        {
            $Keys = Get-ChildItem $RegPath
        }
        
        # This counter is incremented with every foreach loop. Once the counter evaluates to 0 with mod 50, the flush to the output file on disk is performed from the string str_InstallerRegistryKeys that holds the contents in memory. The value of 50 was chosen imprecisely to batch entries in memory before flushing to improve performance.
        [bigint]$FlushToDisk = 0

        # This variable is used to hold the PowerShell Major version for calling the appropriate cmdlet that is compatible with the PS Version
        [int]$CurrentPSMajorVer = ($PSVersionTable.PSVersion).Major


        # This variable is used to hold the PowerShell Major version for calling the appropriate cmdlet that is compatible with the PS Version
        [int]$CurrentPSMajorVer = ($PSVersionTable.PSVersion).Major


        # for each nested key perform an iteration to get all the properties for writing to the output file
        foreach ($k in $keys)
        {
            if ($null -eq $k)
            {
                continue
            }
       
            # Appends the key's information to in-memory stringbuilder string str_InstallerRegistryKeys
            [void]$str_InstallerRegistryKeys.Append("`n" + $k.Name.tostring() + "`n" + "`n")

  
            #When the FlushToDisk counter evalues to 0 with modulo 50, flush the contents ofthe string to the output file on disk
            if ($FlushToDisk % 50 -eq 0)
            {
                Add-Content -Path ($regoutputfilename) -Value ($str_InstallerRegistryKeys.ToString())
                $str_InstallerRegistryKeys = ""
            }

            # Get all properties of the given registry key
            $props = (Get-Item -Path $k.pspath).property

            # Loop through the properties, and for each property , write the details into the stringbuilder in memory. 
            foreach ($p in $props) 
            {
                # Fetches the value of the property ; Get-ItemPropertyValue cmdlet only works with PS Major Version 5 and above. For PS 4 and below, we need to use a workaround.
                # Fetches the value of the property ; Get-ItemPropertyValue cmdlet only works with PS Major Version 5 and above. For PS 4 and below, we need to use a workaround.
                $v = ""
                if ($CurrentPSMajorVer -lt 5)
                {
                    $v = $((Get-ItemProperty -Path $k.pspath).$p) 
                }
                else
                {
                    $v = Get-ItemPropertyvalue -Path $k.pspath -name  $p 
                }
        
                # Fethes the type of property. For default property that has a non-null value, GetValueKind has a bug due to which it cannot fetch the type. This check is to 
                # define type as null if the property is default. 
                try
                {           
                     if ( ($p -ne "(default)") -or ( ( ( $p -eq "(default)" ) -and ($null -eq $v) ) ) )
                     {
                        $t = $k.GetValueKind($p)
                     }
                    else 
                    {
                        $t = ""
                    }
                }
                catch
                {
                    HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
                }
                
                # Reg.exe displays the Windows API registry data type, whereas PowerShell displays the data type in a different format. This switch statement converts the 
                # PS data type to the Windows API registry data type using the table on this MS Docs article as reference: https://learn.microsoft.com/en-us/dotnet/api/microsoft.win32.registryvaluekind?view=net-7.0
                switch($t)
                {
                    "DWord" {$t = "REG_DWORD"}
                    "String" {$t = "REG_SZ"}
                    "ExpandString" {$t = "REG_EXPAND_SZ"}
                    "Binary" {$t = "REG_BINARY"}
                    "QWord" {$t = "REG_QWORD"}
                    "MultiString" {$t = "REG_MULTI_SZ"}
                }
                
                # This if statement formats the REG_DWORD and REG_BINARY to the right values
                if ($t -eq "REG_DWORD")
                {
                    [void]$str_InstallerRegistryKeys.Append("`t$p`t$t`t" + '0x'+ '{0:X}' -f $v + " ($v)" + "`n")
                }
                elseif ($t -eq "REG_BINARY")
                {
                    $hexv = ([System.BitConverter]::ToString([byte[]]$v)).Replace('-','')
                    [void]$str_InstallerRegistryKeys.Append("`t$p`t$t`t$hexv"  + "`n")
                }
                else
                {
                    [void]$str_InstallerRegistryKeys.Append("`t$p`t$t`t$v"  + "`n" )
                }

                # If FLushToDisk value evaluates to 0 when modul0 50 is performed, the contents in memory are flushed to the output file on disk. 
                if ($FlushToDisk % 50 -eq 0)
                {
                    Add-Content -Path ($RegOutputFilename) -Value ($str_InstallerRegistryKeys.ToString())
                    $str_InstallerRegistryKeys = ""
                }
        
                $FlushToDisk = $FlushToDisk + 1
        
            } # End of property loop
       
        $FlushToDisk = $FlushToDisk + 1
        } # End of key loop
        
        # Flush any remaining contents in stringbuilder to disk.
        Add-Content -Path ($RegOutputFilename) -Value ($str_InstallerRegistryKeys.ToString())
        $str_InstallerRegistryKeys = ""
    }
    catch
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
    }
} #End of GetRegistryKeys

#Test connection functionality to see if SQL accessible.
function Test-SQLConnection ([string]$SQLServerName,[string]$SqlQuery)
{
    Write-LogDebug "inside" $MyInvocation.MyCommand

    if ([string]::IsNullOrEmpty($SqlQuery))
    {
        $Sqlquery = "SELECT @@SERVERNAME"
    }
    
    $DataSetPermissions = execSQLQuery -SqlQuery $Sqlquery -SkipStatusCheck $true #-TestFailure $true
    
    if ($DataSetPermissions -eq $false) {
        return $false;
    } else {
        return $true;
    }
}

#Call this function to check if your version is supported checkSQLVersion -VersionsList @("SQL2022RTMCU8", "SQL2019RTMCU23")
#The function checks if current vesion is higher than versionsList, if you want it lowerthan, then user -LowerThan:$true
function checkSQLVersion ([String[]] $VersionsList, [Boolean]$LowerThan = $false, [Long] $SQLVersion = -1)
{
    Write-LogDebug "inside" $MyInvocation.MyCommand

    #in case we decide to pass the version , for testing or any other reason
    if ($SQLVersion -eq -1) {
        $currentSQLVersion =  $global:SQLVERSION 
    } else {
        $currentSQLVersion = $SQLVersion
    }

    [long[]] $versions = @()
    foreach ($ver in $VersionsList) 
    {
        $versions += $global:SqlServerVersionsTbl[$ver]
    }

    #upper limit is used to up the version to its ceiling
    $upperLimit = 999999999
    
    #count is needed to check if we are on the upper limit of the array
    [int] $count = 0

    $modulusFactor = 1000000000

    #sorting is important to make sure we compare the upper limits first and exit early
    if (-Not $LowerThan) 
    {
        $sortedVersions = $versions  | Sort-Object -Descending
    } else {
        $sortedVersions = $versions  | Sort-Object 
    }

    foreach ($v in $sortedVersions)
    {
        $vLower = $v - ($v % $modulusFactor)
        
        #if we are on the head of the array, make the limit significantly high and low to encompass all above upper ad below lower.
        if ($count -eq 0 )
        {
            $vUpper = $upperLimit * $modulusFactor * 1000
            $vLower = 0
        } else {
            $vUpper = $vLower + $upperLimit
        }

        #This bit identifies the upper/lower limits to compare to, to avoid having copy of the same if statement
        if (-Not $LowerThan) {
            $gtBaseValue = $v
            $leBaseValue = $vUpper
        } else {
            $gtBaseValue = $vLower
            $leBaseValue = $v-1 #-1 needed to make sure we are less than Base not equl.
        }
        Write-LogDebug "current $currentSQLVersion gt $gtBaseValue lt $leBaseValue" -DebugLogLevel 3
        if ($currentSQLVersion -ge $gtBaseValue -and $currentSQLVersion -le $leBaseValue )
        {
            Write-LogDebug "Version $currentSQLVersion is supported in $v" -DebugLogLevel 3
            return $true
        }
        $count ++
    }

    Write-LogDebug "Version $currentSQLVersion is not supported" -DebugLogLevel 3
    #we reach here, we are unsupported
    return $false
}

function GetLogPathFromReg([string]$server, [string]$logType) 
{
    Write-LogDebug "Inside" $MyInvocation.MyCommand

    try
    {
        $vInstance = ""
        $vRegInst = ""
        $RegPathParams = ""
        $retLogPath = ""
        $regInstNames = "HKLM:SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL"


        # extract the instance name from the server name
        $instByPort = GetSQLInstanceNameByPortNo($server)
        Write-LogDebug "Result from GetSQLInstanceNameByPortNo is '$instByPort'" -DebugLogLevel 2
        
        if ($true -ne [String]::IsNullOrWhiteSpace($instByPort))
        {
            $vInstance = $instByPort
        }
        else 
        {
            if ($server -like '*\*')
            {
                $vInstance = Get-InstanceNameOnly($server)
            }
            else 
            {
                $vInstance = "MSSQLSERVER"
            }
        }
        
        Write-LogDebug "Instance name is $vInstance" -DebugLogLevel 2

        # make sure a Instance Names is a valid registry key (could be missing if SQL Server is not installed or registry is corrupt)
        if (Test-Path -Path $regInstNames)
        {
            $vRegInst = (Get-ItemProperty -Path $regInstNames).$vInstance
        }
        else
        {
            Write-LogDebug "Registry regInstNames='$regInstNames' is not valid or doesn't exist" -DebugLogLevel 2
            return $false
        }
        

        # validate the registry value with the instance name appended to the end
        # for example, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL\SQL2017
        if ([String]::IsNullOrWhiteSpace($vRegInst) -eq $true)
        {
            Write-LogDebug "Registry value vRegInst is null or empty. Not getting files from Log directory" -DebugLogLevel 2
            return $false
        }
        else
        {
            # get the SQL Server registry key + instance name
            $RegPathParams = "HKLM:SOFTWARE\Microsoft\Microsoft SQL Server\" + $vRegInst 

            switch ($logType)
            {
                {($_ -eq "ERRORLOG") -or ($_ -eq "POLYBASELOG")}
                {
                    # go after the startup params registry key 
                    $RegPathParams +=  "\MSSQLServer\Parameters"
                
                    # validate key to get the path to the ERRORLOG
                    if (Test-Path -Path $RegPathParams)
                    {
                        # strip the -e from the beginning of the string
                        $retLogPath = (Get-ItemProperty -Path $RegPathParams).SQLArg1 -replace "^-e", ""
    
                        # strip the word ERRORLOG from the end of the string
                        $retLogPath = Split-Path $retLogPath -Parent

                        if ($logType -eq "POLYBASELOG") 
                        {
                            # append the PolyBase folder name to the end of the path
                            $retLogPath = $retLogPath + "\PolyBase\"
                        }
                    }
                    else
                    {
                        Write-LogDebug "Registry RegPathParams='$RegPathParams' is not valid or doesn't exist" -DebugLogLevel 2
                        return $false
                    }
                }
                "DUMPLOG"
                {
                    # go after the dump configured registry key
                    # HKLM:SOFTWARE\Microsoft\Microsoft SQL Server\vRegInst\CPE
                    $vRegDmpPath = $RegPathParams + "\CPE"
                
                    if (Test-Path -Path $vRegDmpPath)
                    {
                        # strip the -e from the beginning of the string
                        $retLogPath = (Get-ItemProperty -Path $vRegDmpPath).ErrorDumpDir
                    }
                    else
                    {
                        Write-LogDebug "Registry RegDmpPath='$vRegDmpPath' is not valid or doesn't exist" -DebugLogLevel 2
                        return $false
                    }
                }
                Default
                {
                    Write-LogDebug "Invalid logType='$logType' passed to GetLogPathFromReg()" -DebugLogLevel 2
                    return $false
                }
            }
        }

        # make sure the path to the log directory is valid
        if (Test-Path -Path $retLogPath -PathType Container)
        {
            Write-LogDebug "Log path is $retLogPath" -DebugLogLevel 2
        }
        else
        {
            if ($logType -ne "POLYBASELOG")
            {
                Write-LogWarning "The directory $retLogPath is not accessible to collect logs. Check the disk is mounted and the folder is valid. Continuing with other collectors."
            }
            #Give user time to read the prompt.
            Start-Sleep -Seconds 4

            Write-LogDebug "Log path '$retLogPath' is not valid or doesn't exist" -DebugLogLevel 2
            return $false
        }

        # return the path to directory pulled from registry
        return $retLogPath
        
    }
    catch 
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
    }
}
function setDisableCtrlCasInput 
{
    if ($global:gDisableCtrlCasInput -eq "False")
    {
        [console]::TreatControlCAsInput = $true
    }
}

# SIG # Begin signature block
# MIIn0wYJKoZIhvcNAQcCoIInxDCCJ8ACAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCjuU52yZt3lqMT
# SIYWciJn39YoL/zeeWXVw5CWf0d2BqCCDYUwggYDMIID66ADAgECAhMzAAADri01
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
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCGaQwghmgAgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAOuLTVRyFOPVR0AAAAA
# A64wDQYJYIZIAWUDBAIBBQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIE2P
# bb2tLpvChTWh7NWqZob8sdDHkl+UcQFm8FUWW5f5MEQGCisGAQQBgjcCAQwxNjA0
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEcgBpodHRwczovL3d3d3cubWljcm9zb2Z0
# LmNvbTANBgkqhkiG9w0BAQEFAASCAQAzvgxWoXjKcHMm6uqnQYygb9LR4EDGAkq+
# FOQes+j1EcBUdB6GzPTr1sRRF5b2TaSEKblJBMbYTNNjHHxUGaekGId9SQZwBi1R
# LodvnFUKY1gu+ZcWBUaj7wqOwEn0FRf35YoU5YayCBhImLMogiKNSI6g/K+e0dRH
# dKNKFk70Nnv8R0fFcOqeVH2Y1smgBESxvywfG2TxcCj/UK/y/4XWc+jLXiorHrMB
# GIDIRajPykVR2rNbFyR93nthNwpDAgiQOCtebUO6NxIEW9kH6qROmisucuSrkGwp
# hhE1lTXaBRdqnlGQlZaX88xoV0TerfObhQlTNFEX3t3atcAYO+LMoYIXLDCCFygG
# CisGAQQBgjcDAwExghcYMIIXFAYJKoZIhvcNAQcCoIIXBTCCFwECAQMxDzANBglg
# hkgBZQMEAgEFADCCAVkGCyqGSIb3DQEJEAEEoIIBSASCAUQwggFAAgEBBgorBgEE
# AYRZCgMBMDEwDQYJYIZIAWUDBAIBBQAEIHcpSRL4sy5AeglXz0KD8i4uRM5WzRyW
# vQg13vDOF2gYAgZluqQ/ZUoYEzIwMjQwMjE2MDkwMDI3LjgxMVowBIACAfSggdik
# gdUwgdIxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xLTArBgNV
# BAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJhdGlvbnMgTGltaXRlZDEmMCQGA1UE
# CxMdVGhhbGVzIFRTUyBFU046M0JENC00QjgwLTY5QzMxJTAjBgNVBAMTHE1pY3Jv
# c29mdCBUaW1lLVN0YW1wIFNlcnZpY2WgghF7MIIHJzCCBQ+gAwIBAgITMwAAAeWP
# asDzPbQLowABAAAB5TANBgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJVUzETMBEG
# A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFt
# cCBQQ0EgMjAxMDAeFw0yMzEwMTIxOTA3MzVaFw0yNTAxMTAxOTA3MzVaMIHSMQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNy
# b3NvZnQgSXJlbGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsTHVRoYWxl
# cyBUU1MgRVNOOjNCRDQtNEI4MC02OUMzMSUwIwYDVQQDExxNaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBTZXJ2aWNlMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA
# qXvgOtq7Y7osusk7cfJO871pdqL/943I/kwtZmuZQY04kw/AwjTxX3MF9E81y5yt
# 4hhLIkeOQwhQaa6HSs9Xn/b5QIsas3U/vuf1+r+Z3Ncw3UXOpo8d0oSUqd4lDxHp
# w/h2u7YbKaa3WusZw17zTQJwPp3812iiaaR3X3pWo62NkUDVda74awUF5YeJ7P8+
# WWpwz95ae2RAyzSUrTOYJ8f4G7uLWH4UNFHwXtbNSv/szeOFV0+kB+rbNgIDxlUs
# 2ASLNj68WaDH7MO65T8YKEMruSUNwLD7+BWgS5I6XlyVCzJ1ZCMklftnbJX7UoLo
# bUlWqk/d2ko8A//i502qlHkch5vxNrUl+NFTNK/epKN7nL1FhP8CNY1hDuCx7O4N
# Yz/xxnXWRyjUm9TI5DzH8kOQwWpJHCPW/6ZzosoqWP/91YIb8fD2ml2VYlfqmwN6
# xC5BHsVXt4KpX+V9qOguk83H/3MXV2/zJcF3OZYk94KJ7ZdpCesAoOqUbfNe7H20
# 1CbPYv3pN3Gcg7Y4aZjEEABkBagpua1gj4KLPgJjI7QWblndPjRrl3som5+0XoJO
# hxxz9Sn+OkV9CK0t+N3vVxL5wsJ6hD6rSfQgAu9X5pxsQ2i5I6uO/9C1jgUiMeUj
# nN0nMmcayRUnmjOGOLRhGxy/VbAkUC7LIIxC8t2Y910CAwEAAaOCAUkwggFFMB0G
# A1UdDgQWBBTf/5+Hu01zMSJ8ReUJCAU5eAyHqjAfBgNVHSMEGDAWgBSfpxVdAF5i
# XYP05dJlpxtTNRnpcjBfBgNVHR8EWDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jv
# c29mdC5jb20vcGtpb3BzL2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENB
# JTIwMjAxMCgxKS5jcmwwbAYIKwYBBQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRw
# Oi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRp
# bWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNydDAMBgNVHRMBAf8EAjAAMBYGA1Ud
# JQEB/wQMMAoGCCsGAQUFBwMIMA4GA1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsF
# AAOCAgEAM/rCE4WMPVp3waQQn2gsG69+Od0zIZD1HgeAEpKU+3elrRdUtyKasmUO
# coaAUGJbAjpc6DDzaF2iUOIwMEstZExMkdZV5RjWBThcHw44jEFz39DzfNvVzRFY
# S6mALjwj5v7bHZU2AYlSxAjI9HY+JdCFPk/J6syBqD05Kh1CMXCk10aKudraulXb
# cRTAV47n7ehJfgl4I1m+DJQ7MqnIy+pVq5uj4aV/+mx9bm0hwyNlW3R6WzB+rSok
# 1CChiKltpO+/vGaLFQkZNuLFiJ9PACK89wo116Kxma22zs4dsAzv3lm8otISpeJF
# SMNhnJ4fIDKwwQAtsiF1eAcSHrQqhnLOUFfPdXESKsTueG5w3Aza1WI6XAjsSR5T
# mG51y2dcIbnkm4zD/BvtzvVEqKZkD8peVamYG+QmQHQFkRLw4IYN37Nj9P0GdOny
# yLfpOqXzhV+lh72IebLs+qrGowXYKfirZrSYQyekGu4MYT+BH1zxJUnae2QBHLlJ
# +W64n8wHrXJG9PWZTHeXKmk7bZ4+MGOfCgS9XFsONPWOF0w116864N4kbNEsr0c2
# ZMML5N1lCWP5UyAibxl4QhE0XShq+IX5BlxRktbNZtirrIOiTwRkoWJFHmi0GgYu
# 9pgWnEFlQTyacsq4OVihuOvGHuWfCvFX98zLQX19KjYnEWa0uC0wggdxMIIFWaAD
# AgECAhMzAAAAFcXna54Cm0mZAAAAAAAVMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYD
# VQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEe
# MBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3Nv
# ZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAxMDAeFw0yMTA5MzAxODIy
# MjVaFw0zMDA5MzAxODMyMjVaMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
# aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
# MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA5OGmTOe0ciELeaLL1yR5
# vQ7VgtP97pwHB9KpbE51yMo1V/YBf2xK4OK9uT4XYDP/XE/HZveVU3Fa4n5KWv64
# NmeFRiMMtY0Tz3cywBAY6GB9alKDRLemjkZrBxTzxXb1hlDcwUTIcVxRMTegCjhu
# je3XD9gmU3w5YQJ6xKr9cmmvHaus9ja+NSZk2pg7uhp7M62AW36MEBydUv626GIl
# 3GoPz130/o5Tz9bshVZN7928jaTjkY+yOSxRnOlwaQ3KNi1wjjHINSi947SHJMPg
# yY9+tVSP3PoFVZhtaDuaRr3tpK56KTesy+uDRedGbsoy1cCGMFxPLOJiss254o2I
# 5JasAUq7vnGpF1tnYN74kpEeHT39IM9zfUGaRnXNxF803RKJ1v2lIH1+/NmeRd+2
# ci/bfV+AutuqfjbsNkz2K26oElHovwUDo9Fzpk03dJQcNIIP8BDyt0cY7afomXw/
# TNuvXsLz1dhzPUNOwTM5TI4CvEJoLhDqhFFG4tG9ahhaYQFzymeiXtcodgLiMxhy
# 16cg8ML6EgrXY28MyTZki1ugpoMhXV8wdJGUlNi5UPkLiWHzNgY1GIRH29wb0f2y
# 1BzFa/ZcUlFdEtsluq9QBXpsxREdcu+N+VLEhReTwDwV2xo3xwgVGD94q0W29R6H
# XtqPnhZyacaue7e3PmriLq0CAwEAAaOCAd0wggHZMBIGCSsGAQQBgjcVAQQFAgMB
# AAEwIwYJKwYBBAGCNxUCBBYEFCqnUv5kxJq+gpE8RjUpzxD/LwTuMB0GA1UdDgQW
# BBSfpxVdAF5iXYP05dJlpxtTNRnpcjBcBgNVHSAEVTBTMFEGDCsGAQQBgjdMg30B
# ATBBMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
# L0RvY3MvUmVwb3NpdG9yeS5odG0wEwYDVR0lBAwwCgYIKwYBBQUHAwgwGQYJKwYB
# BAGCNxQCBAweCgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMB
# Af8wHwYDVR0jBBgwFoAU1fZWy4/oolxiaNE9lJBb186aGMQwVgYDVR0fBE8wTTBL
# oEmgR4ZFaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMv
# TWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3JsMFoGCCsGAQUFBwEBBE4wTDBKBggr
# BgEFBQcwAoY+aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNS
# b29DZXJBdXRfMjAxMC0wNi0yMy5jcnQwDQYJKoZIhvcNAQELBQADggIBAJ1Vffwq
# reEsH2cBMSRb4Z5yS/ypb+pcFLY+TkdkeLEGk5c9MTO1OdfCcTY/2mRsfNB1OW27
# DzHkwo/7bNGhlBgi7ulmZzpTTd2YurYeeNg2LpypglYAA7AFvonoaeC6Ce5732pv
# vinLbtg/SHUB2RjebYIM9W0jVOR4U3UkV7ndn/OOPcbzaN9l9qRWqveVtihVJ9Ak
# vUCgvxm2EhIRXT0n4ECWOKz3+SmJw7wXsFSFQrP8DJ6LGYnn8AtqgcKBGUIZUnWK
# NsIdw2FzLixre24/LAl4FOmRsqlb30mjdAy87JGA0j3mSj5mO0+7hvoyGtmW9I/2
# kQH2zsZ0/fZMcm8Qq3UwxTSwethQ/gpY3UA8x1RtnWN0SCyxTkctwRQEcb9k+SS+
# c23Kjgm9swFXSVRk2XPXfx5bRAGOWhmRaw2fpCjcZxkoJLo4S5pu+yFUa2pFEUep
# 8beuyOiJXk+d0tBMdrVXVAmxaQFEfnyhYWxz/gq77EFmPWn9y8FBSX5+k77L+Dvk
# txW/tM4+pTFRhLy/AsGConsXHRWJjXD+57XQKBqJC4822rpM+Zv/Cuk0+CQ1Zyvg
# DbjmjJnW4SLq8CdCPSWU5nR0W2rRnj7tfqAxM328y+l7vzhwRNGQ8cirOoo6CGJ/
# 2XBjU02N7oJtpQUQwXEGahC0HVUzWLOhcGbyoYIC1zCCAkACAQEwggEAoYHYpIHV
# MIHSMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQL
# EyRNaWNyb3NvZnQgSXJlbGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsT
# HVRoYWxlcyBUU1MgRVNOOjNCRDQtNEI4MC02OUMzMSUwIwYDVQQDExxNaWNyb3Nv
# ZnQgVGltZS1TdGFtcCBTZXJ2aWNloiMKAQEwBwYFKw4DAhoDFQD3jaIa5gWuwTjD
# NYN3zkSkzpGLCqCBgzCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
# aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
# MA0GCSqGSIb3DQEBBQUAAgUA6Xjl9DAiGA8yMDI0MDIxNjAzMzUxNloYDzIwMjQw
# MjE3MDMzNTE2WjB3MD0GCisGAQQBhFkKBAExLzAtMAoCBQDpeOX0AgEAMAoCAQAC
# AgQOAgH/MAcCAQACAhFuMAoCBQDpejd0AgEAMDYGCisGAQQBhFkKBAIxKDAmMAwG
# CisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMBhqAwDQYJKoZIhvcNAQEF
# BQADgYEAJmlTSTIZ+nO3jldANk0dl4cb0ypxsHaXzs/NKLEWZUHaETXyVa8JoPLs
# okBneiZk3qH5E+VFnggzjHmDHZruasmk8rzjqRF6JJCS9ME4H21j/rQmgmEAPpMW
# LWH3qel2qv0zWtK9awX2ynM14nkfZ7Q3LkQsFCdoFC/32AcnZNExggQNMIIECQIB
# ATCBkzB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYD
# VQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAeWPasDzPbQL
# owABAAAB5TANBglghkgBZQMEAgEFAKCCAUowGgYJKoZIhvcNAQkDMQ0GCyqGSIb3
# DQEJEAEEMC8GCSqGSIb3DQEJBDEiBCCJUqc/UZvoiIjeysRySxRsjHk15JgpHjsH
# 6UaWQoy4PDCB+gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0EIBWp0//+qPEYWF7Z
# hugRd5vwj+kCh/TULCFvFQf1Tr3tMIGYMIGApH4wfDELMAkGA1UEBhMCVVMxEzAR
# BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3Rh
# bXAgUENBIDIwMTACEzMAAAHlj2rA8z20C6MAAQAAAeUwIgQgv+NFbEdFUXtiK2Oe
# noE0veXZ15AjI6NHIWF0s27pHbEwDQYJKoZIhvcNAQELBQAEggIAXhQFjhgy/1ET
# wcEjkbWeUQMDDYUYvjiiHhwbpgpWpfAUtozxH2zEjY5DACJzFOODJoLfEtZEDKUY
# 5o6qkhU5YfGXOG7y7nkw0scZGad9yuucxAmSTBgmcMGKutluEUnSfyWnvwjVgKle
# DiZMxBA2Utv+wErlYfRLpuOX8dPuiaGYivnHdIFODS8CUgJGQIHG94Lbk5gjsXF4
# 7e9p7DavriYB6XE//OpmwBbMzSLBSACE6aeL7qkfVVV5+m3lFGwZgZxdQPyzFzzi
# A3u8H24CrCUu4L95qINFIIAPiNXZzD+GF7DDh89N69yLVjIAPsLJ1hPAzcbgsgcx
# 8Q4KWXEHkv/nKR0Vk5BC58y18kLEESVTzSCi7e+d9ZWK+eCdCxI3BHyqL6wQqHwD
# Tbx3Y4V9iJKAg4SIfV50DDTRpClr3Qx41J3YJKk7hPREDa7avMVveQrHL9VkIoef
# FKEXYDqsVsFlxUUJgY8xuTzdxSo8rWzB/i74OHdUmeY8o0h5ly1jwVNi6D+Lk8GF
# oacN+9jJKJA9HjsQ9u8VzXh5dtWQq871zOlBtk7BMM77/UqSqAIN5P2Fyim4/yj1
# FWcUHugDdgaqt6wVF9t3s8/DOrFOhDiggdkcHxQarumbY8OcM6lNWugPgMeN4niw
# ++M4MJ8VT+K8MNA3ouU2ArhiCWFTKrY=
# SIG # End signature block
