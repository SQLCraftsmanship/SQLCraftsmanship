Import-Module .\CommonFunctions.psm1

function Get-ClusterVNN ($instance_name)
{
    Write-LogDebug "Inside" $MyInvocation.MyCommand
    
    try 
    {
            
        $vnn = ""

        if (($instance_name -ne "") -and ($null -ne $instance_name))
        {
            $sql_fci_object = Get-ClusterResource | Where-Object {($_.ResourceType -eq "SQL Server")} | get-clusterparameter | Where-Object {($_.Name -eq "InstanceName") -and ($_.Value -eq $instance_name)}
            $vnn_obj = Get-ClusterResource  | Where-Object {($_.ResourceType -eq "SQL Server") -and ($_.OwnerGroup -eq $sql_fci_object.ClusterObject.OwnerGroup.Name)} | get-clusterparameter -Name VirtualServerName | Select-Object Value
            $vnn = $vnn_obj.Value
        }
        else
        {
            Write-LogError "Instance name is empty and it shouldn't be at this point"            
        }
        
        Write-LogDebug "The VNN Matched to Instance = '$instance_name' is  '$vnn' " -DebugLogLevel 2

        return $vnn
    }
    catch 
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
    }
}

function Get-ClusterVnnPlusInstance([string]$instance)
{
    Write-LogDebug "Inside" $MyInvocation.MyCommand
	
    try 
    {
        
        [string]$VirtNetworkNamePlusInstance = ""

        if (($instance -eq "") -or ($null -eq $instance)) 
        {
            Write-LogError "Instance name is empty and it shouldn't be at this point"
        }
        else
        {
            #take the array instance-only names and look it up against the cluster resources and get the VNN that matches that instance. Then populate the NetName array

            $vnn = Get-ClusterVNN ($instance)

            # for default instance
            # DO NOT concatenate instance name
            if ($instance -eq "MSSQLSERVER"){
                Write-LogDebug  "VirtualName+Instance:   " ($vnn) -DebugLogLevel 2

                $VirtNetworkNamePlusInstance = $vnn

                Write-LogDebug "Combined NetName+Instance: '$VirtNetworkNamePlusInstance'" -DebugLogLevel 2
            }
            else
            {
                Write-LogDebug  "VirtualName+Instance:   " ($vnn + "\" + $instance) -DebugLogLevel 2

                $VirtNetworkNamePlusInstance = ($vnn + "\" + $instance)

                Write-LogDebug "Combined NetName+Instance: '$VirtNetworkNamePlusInstance'" -DebugLogLevel 2
            }
        }

        return $VirtNetworkNamePlusInstance    
    }
    catch 
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
    }
}

function Get-HostnamePlusInstance([string]$instance)
{
    Write-LogDebug "inside" $MyInvocation.MyCommand
	
    try 
    {
        
        [string]$NetworkNamePlustInstance = ""
        
        if (($instance -eq "") -or ($null -eq $instance)) 
        {
            Write-LogError "Instance name is empty and it shouldn't be at this point"
        }
        else
        {
            #take the array instance-only names and look it up against the cluster resources and get the VNN that matches that instance. Then populate the NetName array
            $host_name = $global:host_name

            #Write-LogDebug "HostNames+Instance:   " ($host_name + "\" + $instance) -DebugLogLevel 4

            if ($instance -eq "MSSQLSERVER")
            {
                $NetworkNamePlustInstance = $host_name
            }
            else
            {
                $NetworkNamePlustInstance = ($host_name + "\" + $instance)
            }

            Write-LogDebug "Combined HostName+Instance: " $NetworkNamePlustInstance -DebugLogLevel 3
        }

        return $NetworkNamePlustInstance
    }
    catch 
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
    }
}



function IsFailoverClusteredInstance([string]$instanceName)
{
    Write-LogDebug "Inside" $MyInvocation.MyCommand
    try 
    {
    
        if (Get-ClusterResource  | Where-Object {($_.ResourceType -eq "SQL Server")} | get-clusterparameter | Where-Object {($_.Name -eq "InstanceName") -and ($_.Value -eq $instanceName)} )
        {
            Write-LogDebug "The instance '$instanceName' is a SQL FCI " -DebugLogLevel 2
            return $true
        }
        else 
        {
            Write-LogDebug "The instance '$instanceName' is NOT a SQL FCI " -DebugLogLevel 2
            return $false    
        }
    }
    catch 
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
    }
}

function Get-SQLServiceNameAndStatus()
{
    Write-LogDebug "Inside" $MyInvocation.MyCommand
   
    try 
    {
        
        $InstanceArray = @()


        #find the actively running SQL Server services
        $sql_services = Get-Service | Where-Object {(($_.Name -match "MSSQL\$") -or ($_.Name -eq "MSSQLSERVER"))} | ForEach-Object {[PSCustomObject]@{Name=$_.Name; Status=$_.Status.ToString()}}
        
        if ($sql_services.Count -eq 0)
        {
            #Insert dummy row in array to keep object type consistent
            [PSCustomObject]$sql_services = @{Name='no_instance_found'; Status='UNKNOWN'}
            Write-LogDebug "No installed SQL Server instances found. Array value: $sql_services" -DebugLogLevel 1
   

            Write-LogInformation "There are currently no installed instances of SQL Server. Would you like to proceed with OS-only log collection?" -ForegroundColor Green
            
            if ($global:gInteractivePrompts -eq "Noisy")
            {
                $ValidInput = "Y","N"
                $ynStr = Read-Host "Proceed with logs collection (Y/N)?>" -CustomLogMessage "no_sql_instance_logs input: "
                $HelpMessage = "Please enter a valid input ($ValidInput)"

                #$AllInput = $ValidInput,$WPR_YesNo,$HelpMessage 
                $AllInput = @()
                $AllInput += , $ValidInput
                $AllInput += , $ynStr
                $AllInput += , $HelpMessage
            
                [string] $confirm = validateUserInput($AllInput)
            }
            elseif ($global:gInteractivePrompts -eq "Quiet") 
            {
                Write-LogDebug "'Quiet' mode enabled" -DebugLogLevel 4
                $confirm = "Y"
            }

            Write-LogDebug "The choice made is '$confirm'"

            if ($confirm -eq "Y")
            {
                $InstanceArray+=$sql_services
            }
            elseif ($confirm -eq "N")
            {
                Write-LogInformation "Aborting collection..."
                exit
            }
            
        }

        else 
        {
            
            foreach ($sqlserver in $sql_services)
            {
                Write-LogDebug "The SQL Server service array in foreach contains $sqlserver" -DebugLogLevel 3

                #in the case of a default instance, just use MSSQLSERVER which is the instance name
                if ($sqlserver.Name -contains "$")
                {
                    Write-LogDebug "The SQL Server service array returned $sqlserver" -DebugLogLevel 3
                    $InstanceArray  += $sqlserver
                }

                #for named instance, strip the part after the "$"
                else
                {
                    Write-LogDebug "The SQL Server service named instance array returned $sqlserver" -DebugLogLevel 3
                    $sqlserver.Name = $sqlserver.Name -replace '.*\$',''
                    $InstanceArray  += $sqlserver
                    Write-LogDebug "The SQL Server service named extracted instance array returned $sqlserver" -DebugLogLevel 3
                }
            }

        }

        Write-LogDebug "The running instances are: $InstanceArray"   -DebugLogLevel 3

        return $InstanceArray
    }
    catch 
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
    }
}


function Get-NetNameMatchingInstance()
{
    Write-LogDebug "Inside" $MyInvocation.MyCommand
        
    try
    {
        $NetworkNamePlusInstanceArray = @()
        $isClustered = $false
        #create dummy record in array and delete $NetworkNamePlusInstanceArray
        

        #get the list of instance names and status of the service
        [PSCustomObject]$InstanceNameAndStatusArray = Get-SQLServiceNameAndStatus
        Write-LogDebug "The InstanceNameAndStatusArray is: $InstanceNameAndStatusArray" -DebugLogLevel 3

        foreach ($SQLInstance in $InstanceNameAndStatusArray)
        {
            Write-LogDebug "Instance name and status: '$SQLInstance'" -DebugLogLevel 3

            #special cases - if no SQL instance on the machine, just hard-code a value
            if ($global:sql_instance_conn_str -eq $SQLInstance.Name)
            {
                $NetworkNamePlusInstanceArray+=@([PSCustomObject]@{Name=$SQLInstance.Name;Status='UNKNOWN'})
                Write-LogDebug "No running SQL Server instances on the box so hard coding a value and collecting OS-data" -DebugLogLevel 1
            }

            elseif ($SQLInstance -and ($null -ne $SQLInstance))
            {
                Write-LogDebug "SQLInstance array contains:" $SQLInstance -DebugLogLevel 2

                #build NetName + Instance 

                $isClustered = IsClustered #($InstanceNameAndStatusArray)

                #if this is on a clustered system, then need to check for FCI or AG resources
                if ($isClustered -eq $true)
                {
                
                    #loop through each instance name and check if FCI or not. If FCI, use ClusterVnnPlusInstance, else use HostnamePlusInstance
                    #append each name to the output array $NetworkNamePlusInstanceArray
                   
                        if (IsFailoverClusteredInstance($SQLInstance.Name))
                            {
                                Write-LogDebug "The instance '$SQLInstance' is a SQL FCI" -DebugLogLevel 2
                                $SQLInstance.Name = Get-ClusterVnnPlusInstance($SQLInstance.Name)
                                $LogRec = $SQLInstance.Name
                                Write-LogDebug "The value of SQLInstance.Name $LogRec" -DebugLogLevel 3
                                Write-LogDebug "Temp FCI value is $SQLInstance" -DebugLogLevel 3
                                Write-LogDebug "The value of the array before change is $NetworkNamePlusInstanceArray" -DebugLogLevel 3
                                Write-LogDebug "The data type of the array before change is ($NetworkNamePlusInstanceArray.GetType())" -DebugLogLevel 3
                                Write-LogDebug "The value of the SQLInstance array before change is $SQLInstance" -DebugLogLevel 3
                                
                                #This doesn't work for some reason
                                #$NetworkNamePlusInstanceArray += $SQLInstance
                                
                                $NetworkNamePlusInstanceArray += @([PSCustomObject]$SQLInstance)

                                Write-LogDebug "The value of the SQLInstance array after change is $SQLInstance" -DebugLogLevel 3
                                Write-LogDebug "Result of FCI is $NetworkNamePlusInstanceArray" -DebugLogLevel 3
                            }
                        else
                        {
                            Write-LogDebug "The instance '$SQLInstance' is a not SQL FCI but is clustered" -DebugLogLevel 2
                            $SQLInstance.Name = Get-HostnamePlusInstance($SQLInstance.Name)
                            $NetworkNamePlusInstanceArray += $SQLInstance
                            Write-LogDebug "Result of non-FCI Cluster is $NetworkNamePlusInstanceArray" -DebugLogLevel 3
                        }

                }
                #all local resources so just build array with local instances
                else
                {
                    $TestLog = $SQLInstance.Name
                    Write-LogDebug "Array value is $SQLInstance" -DebugLogLevel 3
                    Write-LogDebug "Array value.name is $TestLog" -DebugLogLevel 3
                    $SQLInstance.Name = Get-HostnamePlusInstance($SQLInstance.Name)
                    Write-LogDebug "Array value after Get-HostnamePlusInstance is $SQLInstance" -DebugLogLevel 3
                    $NetworkNamePlusInstanceArray += $SQLInstance
                }
            }

            else
            {
                Write-LogError "InstanceArrayLocal array is blank or null - no instances populated for some reason"
            }
        }

        Write-LogDebug "The NetworkNamePlusInstanceArray in Get-NetNameMatchingInstance is: $NetworkNamePlusInstanceArray" -DebugLogLevel 3
        return [PSCustomObject]$NetworkNamePlusInstanceArray
    }
    catch 
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
    }

}


#Display them to user and let him pick one
function Select-SQLServerForDiagnostics()
{
    Write-LogDebug "Inside" $MyInvocation.MyCommand
    try 
    {
    
        $SqlIdInt = 777
        $isInt = $false
        $ValidId = $false
        $NetNamePlusinstanceArray = @()

        if ($global:instance_independent_collection -eq $true)
        {
            Write-LogDebug "An instance-independent collection is requested. Skipping instance discovery." -DebugLogLevel 1
            return
        }

        #ma Added
        #$global:gui_mode
        [bool]$isInstanceNameSelected = $false
        if (![string]::IsNullOrWhitespace($Global:ComboBoxInstanceName.Text))
        {
            $SqlIdInt = $Global:ComboBoxInstanceName.SelectedIndex
            $isInstanceNameSelected = $true
        } 
       
        #if SQL LogScout did not accept any values for parameter $ServerName 
        if (($true -eq [string]::IsNullOrWhiteSpace($global:gServerName)) -and $global:gServerName.Length -le 1 )
        {
            Write-LogDebug "Server Instance param is blank. Switching to auto-discovery of instances" -DebugLogLevel 3

            $NetNamePlusinstanceArray = Get-NetNameMatchingInstance

            Write-LogDebug "The NetNamePlusinstanceArray in discovery is: $NetNamePlusinstanceArray" -DebugLogLevel 3

            if ($NetNamePlusinstanceArray.Name -eq $global:sql_instance_conn_str) 
            {
                $hard_coded_instance  = $NetNamePlusinstanceArray.Name
                Write-LogDebug "No running SQL Server instances, thus returning the default '$hard_coded_instance' and collecting OS-data only" -DebugLogLevel 3
                return 
            }
            elseif ($NetNamePlusinstanceArray.Name -and ($null -ne $NetNamePlusinstanceArray.Name))
            {
        
                Write-LogDebug "NetNamePlusinstanceArray contains: " $NetNamePlusinstanceArray -DebugLogLevel 3

                #prompt the user to pick from the list

                $Count = $NetNamePlusinstanceArray.Count
                Write-LogDebug "Count of NetNamePlusinstanceArray is $Count" -DebugLogLevel 3
                Write-LogDebug "isInstanceNameSelected is $isInstanceNameSelected" -DebugLogLevel 3

                if ($NetNamePlusinstanceArray.Count -ne 0 -and !$isInstanceNameSelected)
                {
                    Write-LogDebug "NetNamePlusinstanceArray contains more than one instance. Prompting user to select one" -DebugLogLevel 3
                    
                    $instanceIDArray = 0..($NetNamePlusinstanceArray.Length -1)                 




                    # sort the array by instance name
                    #TO DO - sory by property.
                    $NetNamePlusinstanceArray = $NetNamePlusinstanceArray | Sort-Object -Property Name
                    #TO DO - parse the file length out using something like $maxLength = ($array.Name | Measure-Object -Maximum -Property Length).Maximum. Need to calculate spaces based on values.

                    Write-LogDebug "NetNamePlusinstanceArray sorted contains: " $NetNamePlusinstanceArray -DebugLogLevel 4

                    #set spacing for displaying the text
                    
                    #set hard-coded spacing for displaying the text
                    [string] $StaticGap = "".PadRight(3)

                    #GETTING PROMPT TO DISPLAY 
               
                    ## build the ID# header values
                    $IDHeader = "ID#"

                    #get the max length of the ID# values (for 2000 instances on the box the value would be 1999, and length will be 4 characters)
                    [int]$IDMaxLen = ($NetNamePlusinstanceArray.Count | ForEach-Object { [string]$_ } | Measure-Object -Maximum -Property Length).Maximum

                    #if the max value is less than the header length, then set the header be 3 characters long
                    if ($IDMaxLen -le $IDHeader.Length)
                    {
                        [int]$IDMaxLen = $IDHeader.Length
                    }
                    Write-LogDebug "IDMaxLen is $IDMaxLen"

                    # create the header hyphens to go above the ID#
                    [string]$IDMaxHeader = '-' * $IDMaxLen

                    ## build the instance name header values
                    [string]$InstanceNameHeader = "SQL Instance Name"

                    #get the max length of all the instances found the box (running or stopped)
                    [int]$SQLInstanceNameMaxLen = ($NetNamePlusinstanceArray.Name | ForEach-Object {[string]$_}| Measure-Object -Maximum -Property Length).Maximum
                    Write-LogDebug "SQLInstanceNameMaxLen value is $SQLInstanceNameMaxLen"
                   
                    # if longest instance name is less than the defined header length, then pad to the header length and not instance length
                    if ($SQLInstanceNameMaxLen -le ($InstanceNameHeader.Length))
                    {
                        $SQLInstanceNameMaxLen = $InstanceNameHeader.Length
                    }
                    Write-LogDebug "SQLInstanceNameMaxLen is $SQLInstanceNameMaxLen"

                    # prepare the header hyphens to go above the instance name
                    [string]$SQLInstanceNameMaxHeader = '-' * $SQLInstanceNameMaxLen

                    ## build the service status header values
                    $InstanceStatusHeader = "Status"

                    #get the max length of all the service status strings (running or stopped for now)
                    [int]$ServiceStatusMaxLen= ($NetNamePlusinstanceArray.Status | ForEach-Object {[string]$_} | Measure-Object -Maximum -Property Length).Maximum
 
                    if ($ServiceStatusMaxLen -le $InstanceStatusHeader.Length)
                    {
                        $ServiceStatusMaxLen = $InstanceStatusHeader.Length
                    }
                    Write-LogDebug "ServiceStatusMaxLen is $ServiceStatusMaxLen"

                    #prepare the header hyphens to go above service status
                    [string]$ServiceStatusMaxHeader = '-' * $ServiceStatusMaxLen

                    #display the header
                    Write-LogInformation "Discovered the following SQL Server instance(s)`n"
                    Write-LogInformation ""
                    Write-LogInformation "$($IDHeader+$StaticGap+$InstanceNameHeader.PadRight($SQLInstanceNameMaxLen)+$StaticGap+$InstanceStatusHeader.PadRight($ServiceStatusMaxLen))"
                    Write-LogInformation "$($IDMaxHeader+$StaticGap+$SQLInstanceNameMaxHeader+$StaticGap+$ServiceStatusMaxHeader)"
                    
                    
                    #loop through instances and append to cmd display
                    $i = 0
                    foreach ($FoundInstance in $NetNamePlusinstanceArray)
                    {
                        $InstanceName = $FoundInstance.Name
                        $InstanceStatus = $FoundInstance.Status
                        
                        Write-LogDebug "Looping through $i, $InstanceName, $InstanceStatus" -DebugLogLevel 3
                        Write-LogInformation "$($i.ToString().PadRight($IdMaxLen)+$StaticGap+$InstanceName.PadRight($SQLInstanceNameMaxLen)+$StaticGap+$InstanceStatus.PadRight($ServiceStatusMaxWithSpace))"
                        #Write-LogInformation $i "	" $FoundInstance.Name "	" $FoundInstance.Status
                        $i++
                    }

                    #prompt the user to select an instance
                    while(($isInt -eq $false) -or ($ValidId -eq $false))
                    {
                        Write-LogInformation ""
                        Write-LogWarning "Enter the ID of the SQL instance for which you want to collect diagnostic data. Then press Enter" 
                        #Write-LogWarning "Then press Enter" 

                        $SqlIdStr = Read-Host "Enter the ID from list above>" -CustomLogMessage "SQL Instance Console input:"
                        
                        try{
                                $SqlIdInt = [convert]::ToInt32($SqlIdStr)
                                $isInt = $true
                            }

                        catch [FormatException]
                            {
                                Write-LogError "The value entered for ID '",$SqlIdStr,"' is not an integer"
                                continue
                            }
            
                        #validate this ID is in the list discovered 
                        if ($SqlIdInt -in ($instanceIDArray))
                        {
                            $ValidId = $true
                            break;
                        }
                        else 
                        {
                            $ValidId = $false
                            Write-LogError "The numeric instance ID entered '$SqlIdInt' is not in the list"
                        }
                    }   #end of while

                }#end of IF
            }
            else
            {
                Write-LogError "NetNamePlusinstanceArray array is blank or null. Exiting..."
                exit
            }

            $str = "You selected instance '" + $NetNamePlusinstanceArray[$SqlIdInt].Name +"' to collect diagnostic data. "
            Write-LogInformation $str -ForegroundColor Green

            #set the global variable so it can be easily used by multiple collectors
            $global:sql_instance_conn_str = $NetNamePlusinstanceArray[$SqlIdInt].Name
            
            $global:sql_instance_service_status = $NetNamePlusinstanceArray[$SqlIdInt].Status
            Write-LogDebug "The SQL instance service status is updated to $global:sql_instance_service_status"
            #return $NetNamePlusinstanceArray[$SqlIdInt] 

        }
        # if the instance is passed in as a parameter, then use that value. But test if that instance is running/valid
        else 
        {
            Write-LogDebug "Server Instance param is '$($global:gServerName)'. Using this value for data collection" -DebugLogLevel 2
            
            # assign the param passed into the script to the global variable
            # if parameter passed is "." or "(local)", then use the hostname
            
            if (($global:gServerName -eq ".") -or ($global:gServerName -eq "(local)"))
            {
                $global:sql_instance_conn_str = $global:host_name
            }
            elseif (($global:gServerName -like ".\*") -or ($global:gServerName -eq "(local)\*")) 
            {
                $inst_name = Get-InstanceNameOnly ($global:gServerName)
                $global:sql_instance_conn_str = ($global:host_name + "\" + $inst_name)
            }
            else 
            {
                $global:sql_instance_conn_str = $global:gServerName
            }
        
            #Get service status. Since user provided instance name, no instance discovery code invoked
            if (Test-SQLConnection($global:sql_instance_conn_str)) 
            {
                $global:sql_instance_service_status = "Running"
            } 
            else 
            {
                $global:sql_instance_service_status = "UNKNOWN"
            }
        }

    }
    catch 
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
    }
}


function Set-NoInstanceToHostName()
{
    Write-LogDebug "inside" $MyInvocation.MyCommand
    try 
    {
        if ($global:sql_instance_conn_str -eq $NO_INSTANCE_NAME)
        {
            $global:sql_instance_conn_str = $global:host_name
        }
    }
    catch 
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
        return
    }
    
}
# SIG # Begin signature block
# MIIoPgYJKoZIhvcNAQcCoIIoLzCCKCsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBYBTofzbWXo2TY
# fFjfRbvIHOOCNBxx3JVCFQhvRwb07aCCDYUwggYDMIID66ADAgECAhMzAAADri01
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
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPFO
# NCGw5Vncf/gcMtBmdsHVkDcNk2FUYfrsTGunzggEMEQGCisGAQQBgjcCAQwxNjA0
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEcgBpodHRwczovL3d3d3cubWljcm9zb2Z0
# LmNvbTANBgkqhkiG9w0BAQEFAASCAQBognrFLVhYj2Jee7Nj379l7bP8an4SmsaZ
# Djax/eIdIkLxEY5LWgku/LDhys45eh2JmfKx3YQdmN5uz4cBe0ouEvx4el7mOCuj
# oXYQEdBTod/EuBGsSeHU+TnAnZG/zHvWEDllzzJSqZdu30zRqhBZDCBtjNKoo2Pp
# 6znIcnPi55WBLiMwzK2RzCXKup9bQHn9yMW6w4j7SnRhHgnoX7+cVwLaC2FbiR1Y
# ZksvjGzoRr3S09zkjEtMne5HKzeHnLl81eABqfq5lZyLn+O/dDKtKT+SOZtWJJj7
# aUACZ/d8Az/3BwXw6nBZQu6VVqNfDmjfwm9HqEKEssskF7QmwH7KoYIXlzCCF5MG
# CisGAQQBgjcDAwExgheDMIIXfwYJKoZIhvcNAQcCoIIXcDCCF2wCAQMxDzANBglg
# hkgBZQMEAgEFADCCAVIGCyqGSIb3DQEJEAEEoIIBQQSCAT0wggE5AgEBBgorBgEE
# AYRZCgMBMDEwDQYJYIZIAWUDBAIBBQAEICF9hvWJnkyEbtADq25fOvUeIrT/bhPW
# +hwn2pOuY3UgAgZlzgV2+p0YEzIwMjQwMjE2MDkwMDM4LjAyNFowBIACAfSggdGk
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
# CQMxDQYLKoZIhvcNAQkQAQQwLwYJKoZIhvcNAQkEMSIEIOldHetuEv5tI8Dp2dlV
# w7IgjRcjz6pBn2C4H4BYTr4MMIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCBvQQg
# zrdrvl9pA+F/xIENO2TYNJSAht2LNezPvqHUl2EsLPgwgZgwgYCkfjB8MQswCQYD
# VQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEe
# MBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3Nv
# ZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAevgGGy1tu847QABAAAB6zAiBCB1
# hOajD+4rIhZVH8EsSDCdCVVKoJPF+xne8d4QdcKZ0TANBgkqhkiG9w0BAQsFAASC
# AgAhS6EpRQ6tdl7CMEHRja1ow4Kyoko40L7ZgIQCqS6wIc9I0on7xrTDVxq1xPWf
# 272M3A8HD3VA3CIP+bXxm8PrKQtUND6Qs9wFpH6hfZVEhowb62bi+iFL/UWuNcWI
# Q4/NeRvE5U3zWMEvbLp0TQS20GdY7/d+kPyR0pI6W7vDK/EkmQNMrskrgNY+nh69
# uH7gZbEPOMqmy/VSAEa1uZKJ0FNe776FY8GNOXhjd0YkhBjptviHkgelIBQhTpIe
# Zr8FUeBmRzc+hIOz7CEc6yumNZI5GpMpgyekvRBVe9NGyIeMftewqF/DywscrDLv
# 4g2n1DpB+KPerWWY2e7w6YOc/ch2gOXmbyBrW5O/+yKQs46kcdgJfHPbJdaVRIBV
# V/kCsmgSTeT0iZhImXdLGxGpcnNbMcuNTeAAghkTWp1GhrYr8yuQR+M8MTiPp3jj
# 9BVd/BtSqBkamtKFnCpMKo6563WzE96Aohj7YqrThs+9YTkmbq18QqPPAsaQf9Lk
# oet6Jhxd8ESkK1oesMtDMtGDlQbkJipWwUk2CW+dKqkWXCjuuviztlcIJcfk5Ond
# 4619FwRlez10LHdi9E2ZTL68OWbyBd4o8GAreM3LPgpzgO9tut9/6Inf97Yf1Zr0
# cDqkkzdiBlrM6CDzWOkln65+YPIw4rLSv/xIyCxPcpqL+w==
# SIG # End signature block
