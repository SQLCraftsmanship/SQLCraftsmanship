param
(
    #servername\instancename is an optional parameter since there is code that auto-discovers instances
    [Parameter(Position=0)]
    [string] $ServerName = $env:COMPUTERNAME,

    [Parameter(Position=1)]
    [string] $SqlNexusPath ,

    [Parameter(Position=2)]
    [string] $SqlNexusDb ,

    [Parameter(Position=3)]
    [bool] $DoProcmonTest = $false,

    [Parameter(Position=4)]
    [string] $Scenarios = "All",

    [Parameter(Position=5)]
    [string] $DisableCtrlCasInput = "False"


)

Import-Module -Name ..\CommonFunctions.psm1
Import-Module -Name ..\LoggingFacility.psm1

function CreateTestingInfrastructureDir() 
{
    Write-LogDebug "inside" $MyInvocation.MyCommand -DebugLogLevel 2

    $present_directory = Convert-Path -Path "."   #this gets the current directory called \TestingInfrastructure
    $TestingInfrastructureFolder = $present_directory + "\Output\"
    New-Item -Path $TestingInfrastructureFolder -ItemType Directory -Force | out-null 
    
    return $TestingInfrastructureFolder
}

function Get-LogScoutRootFolder 
{
    # go back to SQL LogScout root folder
    $root_folder = (Get-Item (Get-Location)).Parent.Parent.FullName

    return $root_folder
}


try 
{

    #create the output directory
    $SummaryFilename = 'Summary.txt'
    $TestingOutputFolder = CreateTestingInfrastructureDir
    $root_folder = Get-LogScoutRootFolder
    $LogScoutOutputFolder = $root_folder + "\Output" # go back to SQL LogScout root folder and create \Output

    #check for existence of Summary.txt and if there, rename it
    $LatestSummaryFile = Get-ChildItem -Path $TestingOutputFolder -Filter $SummaryFilename -Recurse |  Sort-Object LastWriteTime -Descending | Select-Object -First 1 | %{$_.FullName} 

    if ($true -eq (Test-Path -Path ($TestingOutputFolder + "\" + $SummaryFilename) ))
    {
        $LatestSummaryFile = Get-ChildItem -Path $TestingOutputFolder -Filter $SummaryFilename -Recurse |  Sort-Object LastWriteTime -Descending | Select-Object -First 1 | %{$_.FullName} 
        $date_summary = ( get-date ).ToString('yyyyMMddhhmmss');
        $ReportPathSummary = $date_summary +'_Old_Summary.txt' 
        Rename-Item -Path $LatestSummaryFile -NewName $ReportPathSummary
    }

    #create new Summary.txt
    New-Item -itemType File -Path $TestingOutputFolder -Name $SummaryFilename | out-null 

    #create the full path to summary file
    $SummaryOutputFilename = ($TestingOutputFolder + "\" + $SummaryFilename)
    
    # append date to file
    Write-Output "                      $(Get-Date)"   |Out-File $SummaryOutputFilename -Append
    
    
    [int] $TestCount = 0
    $temp_return_val = 0
    $return_val = 0

    #Run Tests and send results to a summary file 

    # Individual Scenarios
    if ($Scenarios -in ("Basic", "All"))
    {
        $temp_return_val = .\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "Basic"          -SummaryOutputFile $SummaryOutputFilename -SqlNexusPath $SqlNexusPath -SqlNexusDb $SqlNexusDb -LogScoutOutputFolder $LogScoutOutputFolder -RootFolder $root_folder -DisableCtrlCasInput $DisableCtrlCasInput
        
        #due to PS pipeline, Scenario_Test returns many things in an array. 
        #We need to get the last element of the array - the return value which is sent out last
        $return_val+=$temp_return_val[$temp_return_val.Count-1]

        $TestCount++
    }
    if ($Scenarios -in ("GeneralPerf", "All"))
    {
        $temp_return_val = .\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "GeneralPerf"    -SummaryOutputFile $SummaryOutputFilename -SqlNexusPath $SqlNexusPath -SqlNexusDb $SqlNexusDb -LogScoutOutputFolder $LogScoutOutputFolder -RootFolder $root_folder -RunTSQLLoad $true -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }
    if ($Scenarios -in ("DetailedPerf", "All"))
    {
        $temp_return_val = .\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "DetailedPerf"   -SummaryOutputFile $SummaryOutputFilename -SqlNexusPath $SqlNexusPath -SqlNexusDb $SqlNexusDb -LogScoutOutputFolder $LogScoutOutputFolder -RootFolder $root_folder -RunTSQLLoad $true  -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }
    if ($Scenarios -in ("Replication", "All"))
    {
        $temp_return_val =.\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "Replication"    -SummaryOutputFile $SummaryOutputFilename -SqlNexusPath $SqlNexusPath -SqlNexusDb $SqlNexusDb -LogScoutOutputFolder $LogScoutOutputFolder -RootFolder $root_folder -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }
    if ($Scenarios -in ("AlwaysOn", "All"))
    {
        $temp_return_val =.\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "AlwaysOn"       -SummaryOutputFile $SummaryOutputFilename -SqlNexusPath $SqlNexusPath -SqlNexusDb $SqlNexusDb -LogScoutOutputFolder $LogScoutOutputFolder -RootFolder $root_folder -RunTSQLLoad $true -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }
    if ($Scenarios -in ("NetworkTrace", "All"))
    {
        $temp_return_val =.\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "NetworkTrace"   -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }
    if ($Scenarios -in ("Memory", "All"))
    {
        $temp_return_val =.\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "Memory"         -SummaryOutputFile $SummaryOutputFilename -SqlNexusPath $SqlNexusPath -SqlNexusDb $SqlNexusDb -LogScoutOutputFolder $LogScoutOutputFolder -RootFolder $root_folder  -RunTSQLLoad $true -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }
    if ($Scenarios -in ("Setup", "All"))
    {
        $temp_return_val =.\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "Setup"          -SummaryOutputFile $SummaryOutputFilename -SqlNexusPath $SqlNexusPath -SqlNexusDb $SqlNexusDb -LogScoutOutputFolder $LogScoutOutputFolder -RootFolder $root_folder -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }
    if ($Scenarios -in ("BackupRestore", "All"))
    {
        $temp_return_val =.\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "BackupRestore"  -SummaryOutputFile $SummaryOutputFilename -SqlNexusPath $SqlNexusPath -SqlNexusDb $SqlNexusDb -LogScoutOutputFolder $LogScoutOutputFolder -RootFolder $root_folder -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }   
    if ($Scenarios -in ("IO", "All"))
    {
        $temp_return_val =.\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "IO"             -SummaryOutputFile $SummaryOutputFilename -SqlNexusPath $SqlNexusPath -SqlNexusDb $SqlNexusDb -LogScoutOutputFolder $LogScoutOutputFolder -RootFolder $root_folder -RunTSQLLoad $true -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }
    if ($Scenarios -in ("LightPerf", "All"))
    {
        $temp_return_val =.\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "LightPerf"      -SummaryOutputFile $SummaryOutputFilename -SqlNexusPath $SqlNexusPath -SqlNexusDb $SqlNexusDb -LogScoutOutputFolder $LogScoutOutputFolder -RootFolder $root_folder -RunTSQLLoad $true -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }

    #Process monitor is a bit different 
    if (($Scenarios -eq "ProcessMonitor") -or ($Scenarios -eq "All" -and $DoProcmonTest -eq $true))
    {
        $temp_return_val =.\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "ProcessMonitor" -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }

    if ($Scenarios -in ("ServiceBrokerDBMail", "All"))
    {
        $temp_return_val =.\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "ServiceBrokerDBMail"      -SummaryOutputFile $SummaryOutputFilename -SqlNexusPath $SqlNexusPath -SqlNexusDb $SqlNexusDb -LogScoutOutputFolder $LogScoutOutputFolder -RootFolder $root_folder -RunTSQLLoad $true -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }

    if ($Scenarios -in ("NeverEndingQuery", "All"))
    {
        $temp_return_val =.\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "NeverEndingQuery"      -SummaryOutputFile $SummaryOutputFilename -SqlNexusPath $SqlNexusPath -SqlNexusDb $SqlNexusDb -LogScoutOutputFolder $LogScoutOutputFolder -RootFolder $root_folder -RunTSQLLoad $true -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }

    #combine Basic with a Network others
    if ($Scenarios -in ("Basic+NetworkTrace", "All"))
    {
        $temp_return_val =.\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "Basic+NetworkTrace"           -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }


    # combine scenario with NoBasic
    if ($Scenarios -in ("Basic+NoBasic", "All"))
    {
        $temp_return_val =.\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "Basic+NoBasic"           -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }
    if ($Scenarios -in ("GeneralPerf+NoBasic", "All"))
    {
        $temp_return_val =.\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "GeneralPerf+NoBasic"     -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -RunTSQLLoad $true -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }
    if ($Scenarios -in ("DetailedPerf+NoBasic", "All"))
    {
        $temp_return_val =.\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "DetailedPerf+NoBasic"    -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -RunTSQLLoad $true -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }
    if ($Scenarios -in ("Replication+NoBasic", "All"))
    {
        $temp_return_val = .\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "Replication+NoBasic"     -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }
    if ($Scenarios -in ("AlwaysOn+NoBasic", "All"))
    {
        $temp_return_val = .\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "AlwaysOn+NoBasic"        -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -RunTSQLLoad $true -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }
    if ($Scenarios -in ("Memory+NoBasic", "All"))
    {
        $temp_return_val = .\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "Memory+NoBasic"          -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -RunTSQLLoad $true -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }
    if ($Scenarios -in ("Setup+NoBasic", "All"))
    {
        $temp_return_val = .\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "Setup+NoBasic"           -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }
    if ($Scenarios -in ("BackupRestore+NoBasic", "All"))
    {
        $temp_return_val = .\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "BackupRestore+NoBasic"   -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }
    if ($Scenarios -in ("IO+NoBasic", "All"))
    {
        $temp_return_val = .\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "IO+NoBasic"              -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -RunTSQLLoad $true -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }
    if ($Scenarios -in ("LightPerf+NoBasic", "All"))
    {
        $temp_return_val = .\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "LightPerf+NoBasic"       -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -RunTSQLLoad $true -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }

    # common combination scenarios
    if ($Scenarios -in ("GeneralPerf+Replication", "All"))
    {
        $temp_return_val = .\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "GeneralPerf+Replication"     -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -RunTSQLLoad $true -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1][$temp_return_val.Count-1]
        $TestCount++
    }
    if ($Scenarios -in ("GeneralPerf+AlwaysOn", "All"))
    {
        $temp_return_val = .\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "GeneralPerf+AlwaysOn"        -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -RunTSQLLoad $true -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1][$temp_return_val.Count-1]
        $TestCount++
    }
    if ($Scenarios -in ("GeneralPerf+IO", "All"))
    {
        $temp_return_val = .\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "GeneralPerf+IO"              -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -RunTSQLLoad $true -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1][$temp_return_val.Count-1]
        $TestCount++
    }
    if ($Scenarios -in ("GeneralPerf+NetworkTrace", "All"))
    {
        $temp_return_val = .\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "GeneralPerf+NetworkTrace"    -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -RunTSQLLoad $true -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1][$temp_return_val.Count-1]
        $TestCount++
    }
    if ($Scenarios -in ("DetailedPerf+AlwaysOn", "All"))
    {
        $temp_return_val = .\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "DetailedPerf+AlwaysOn"       -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -RunTSQLLoad $true -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1][$temp_return_val.Count-1]
        $TestCount++
    }
    if ($Scenarios -in ("DetailedPerf+IO", "All"))
    {
        $temp_return_val = .\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "DetailedPerf+IO"             -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -RunTSQLLoad $true -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1][$temp_return_val.Count-1]
        $TestCount++
    }

    if ($Scenarios -in ("DetailedPerf+NetworkTrace", "All"))
    {
        $temp_return_val = .\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "DetailedPerf+NetworkTrace"   -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -RunTSQLLoad $true -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }
    if ($Scenarios -in ("LightPerf+AlwaysOn", "All"))
    {
        $temp_return_val = .\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "LightPerf+AlwaysOn"          -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -RunTSQLLoad $true -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }
    if ($Scenarios -in ("LightPerf+IO", "All"))
    {
        $temp_return_val = .\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "LightPerf+IO"                -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -RunTSQLLoad $true -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }
    if ($Scenarios -in ("LightPerf+BackupRestore", "All"))
    {
        $temp_return_val = .\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "LightPerf+BackupRestore"     -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -RunTSQLLoad $true -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }
    if ($Scenarios -in ("LightPerf+Memory", "All"))
    {
        $temp_return_val = .\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "LightPerf+Memory"            -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -RunTSQLLoad $true -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }
    if ($Scenarios -in ("LightPerf+NetworkTrace", "All"))
    {
        $temp_return_val = .\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "LightPerf+NetworkTrace"      -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -RunTSQLLoad $true -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }

    if ($Scenarios -in ("ServiceBrokerDBMail+GeneralPerf", "All"))
    {
        $temp_return_val =.\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "ServiceBrokerDBMail+GeneralPerf"      -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -RunTSQLLoad $true -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }

    if ($Scenarios -in ("NeverEndingQuery+GeneralPerf", "All"))
    {
        $temp_return_val =.\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "NeverEndingQuery+GeneralPerf"      -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -RunTSQLLoad $true -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }

    #Procmon scenario is a bit different needs the extra parameter $DoProcmonTest
    if (($Scenarios -eq "ProcessMonitor+Setup") -or ( $Scenarios -eq "All" -and $DoProcmonTest -eq $true))
    {
        $temp_return_val = .\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "ProcessMonitor+Setup"        -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        $TestCount++
    }

    if ($Scenarios -eq ("All"))
    {
        # scenarios that don't make sense
        $temp_return_val = .\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "GeneralPerf+DetailedPerf"    -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        
        $temp_return_val = .\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "GeneralPerf+LightPerf"       -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]
        
        $temp_return_val = .\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "DetailedPerf+LightPerf"      -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]

        #stress tests
        $temp_return_val = .\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "DetailedPerf+AlwaysOn+Replication+NetworkTrace+Memory+Setup+BackupRestore+IO"   -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]

        $temp_return_val = .\Scenarios_Test.ps1 -ServerName $ServerName -Scenarios "Basic+GeneralPerf+DetailedPerf+AlwaysOn+Replication+NetworkTrace+Memory+Setup+BackupRestore+IO+LightPerf"  -SummaryOutputFile $SummaryOutputFilename -RootFolder $root_folder -DisableCtrlCasInput $DisableCtrlCasInput
        $return_val+=$temp_return_val[$temp_return_val.Count-1]

        $TestCount = $TestCount + 5
    }

    # append test count to Summary file
    Write-Output "********************************************************************"   |Out-File $SummaryOutputFilename -Append
    Write-Output "Executed a total of $TestCount test(s)."   |Out-File $SummaryOutputFilename -Append
    
    # append overall test status to Summary file
    if ($return_val -eq 0)
    {
        Write-Output "OVERALL STATUS: All tests passed."   |Out-File $SummaryOutputFilename -Append
    }
    else
    {
        Write-Output "OVERALL STATUS: One or more tests failed."   |Out-File $SummaryOutputFilename -Append
    }

    #print the Summary.txt file in console
    Get-Content $SummaryOutputFilename

    #Launch the Summary.txt file for review
    Start-Process $SummaryOutputFilename

    #return the value of the last test
    #use exit so parent can handle the error in cmd prompt (%errorlevel%) or powershell ($LASTEXITCODE)
    # if ($return_val -ne 0) then the last test failed
    exit $return_val
}

catch {
    $error_msg = $PSItem.Exception.Message
    $error_linenum = $PSItem.InvocationInfo.ScriptLineNumber
    $error_offset = $PSItem.InvocationInfo.OffsetInLine
    $error_script = $PSItem.InvocationInfo.ScriptName
    Write-LogError "Function '$($MyInvocation.MyCommand)' failed with error:  $error_msg (line: $error_linenum, offset: $error_offset, file: $error_script)"    
    exit 999
}
# SIG # Begin signature block
# MIIn0AYJKoZIhvcNAQcCoIInwTCCJ70CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBTPruvSBAZr72F
# nLgoNGuIdANwSBxUBAW2zfPGnF9LYqCCDYUwggYDMIID66ADAgECAhMzAAADri01
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
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCGaEwghmdAgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAOuLTVRyFOPVR0AAAAA
# A64wDQYJYIZIAWUDBAIBBQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIO06
# oPbDOpLpXTa6uXLbHE+AnMJm8EQS7mEevmFuqTyWMEQGCisGAQQBgjcCAQwxNjA0
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEcgBpodHRwczovL3d3d3cubWljcm9zb2Z0
# LmNvbTANBgkqhkiG9w0BAQEFAASCAQCTqAmjEqA7K7qsnMAz8wmSt3d2ALeoXz05
# jp3S/kNvXvhSjq/C2CS28omZiGl2KQl0pr9Vyt45eRaUPxfg6JCB4Pc8kqwJOA+Q
# +Ab0OTI6YXj87ELy1TAbY7W2g7vsVISuhcMLriwCyp/SGix9a41P9PGWCwVj8N+a
# 8YFgejAfc3OYCBneMpCUbFsUD7j4qAdZByQ0Z/gFDLclrqpbIErsQceLRkZOLdEV
# nppAgfHOks5TAD9IAkKBw7x1Xnee1FnBvN2k4qbudWnd3CIWtwG3vwfI/9d9MPV8
# sj73hWGiYqroKOHGk6tQqtQ0L69to6Gilmq/jaRjJKO8D5wKSGKSoYIXKTCCFyUG
# CisGAQQBgjcDAwExghcVMIIXEQYJKoZIhvcNAQcCoIIXAjCCFv4CAQMxDzANBglg
# hkgBZQMEAgEFADCCAVkGCyqGSIb3DQEJEAEEoIIBSASCAUQwggFAAgEBBgorBgEE
# AYRZCgMBMDEwDQYJYIZIAWUDBAIBBQAEIED6TaWY+ZVzEfSQp7uMqqDnRjrizY0y
# lHfZdFkkG07HAgZluqV/bpUYEzIwMjQwMjE2MDkwMDI5LjE2N1owBIACAfSggdik
# gdUwgdIxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xLTArBgNV
# BAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJhdGlvbnMgTGltaXRlZDEmMCQGA1UE
# CxMdVGhhbGVzIFRTUyBFU046RkM0MS00QkQ0LUQyMjAxJTAjBgNVBAMTHE1pY3Jv
# c29mdCBUaW1lLVN0YW1wIFNlcnZpY2WgghF4MIIHJzCCBQ+gAwIBAgITMwAAAeKZ
# mZXx3OMg6wABAAAB4jANBgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJVUzETMBEG
# A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFt
# cCBQQ0EgMjAxMDAeFw0yMzEwMTIxOTA3MjVaFw0yNTAxMTAxOTA3MjVaMIHSMQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNy
# b3NvZnQgSXJlbGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsTHVRoYWxl
# cyBUU1MgRVNOOkZDNDEtNEJENC1EMjIwMSUwIwYDVQQDExxNaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBTZXJ2aWNlMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA
# tWO1mFX6QWZvxwpCmDabOKwOVEj3vwZvZqYa9sCYJ3TglUZ5N79AbMzwptCswOiX
# sMLuNLTcmRys+xaL1alXCwhyRFDwCRfWJ0Eb0eHIKykBq9+6/PnmSGXtus9DHsf3
# 1QluwTfAyamYlqw9amAXTnNmW+lZANQsNwhjKXmVcjgdVnk3oxLFY7zPBaviv3GQ
# yZRezsgLEMmvlrf1JJ48AlEjLOdohzRbNnowVxNHMss3I8ETgqtW/UsV33oU3EDP
# Cd61J4+DzwSZF7OvZPcdMUSWd4lfJBh3phDt4IhzvKWVahjTcISD2CGiun2pQpwF
# R8VxLhcSV/cZIRGeXMmwruz9kY9Th1odPaNYahiFrZAI6aSCM6YEUKpAUXAWaw+t
# mPh5CzNjGrhzgeo+dS7iFPhqqm9Rneog5dt3JTjak0v3dyfSs9NOV45Sw5BuC+VF
# 22EUIF6nF9vqduynd9xlo8F9Nu1dVryctC4wIGrJ+x5u6qdvCP6UdB+oqmK+nJ3s
# oJYAKiPvxdTBirLUfJidK1OZ7hP28rq7Y78pOF9E54keJKDjjKYWP7fghwUSE+iB
# oq802xNWbhBuqmELKSevAHKqisEIsfpuWVG0kwnCa7sZF1NCwjHYcwqqmES2lKbX
# Pe58BJ0+uA+GxAhEWQdka6KEvUmOPgu7cJsCaFrSU6sCAwEAAaOCAUkwggFFMB0G
# A1UdDgQWBBREhA4R2r7tB2yWm0mIJE2leAnaBTAfBgNVHSMEGDAWgBSfpxVdAF5i
# XYP05dJlpxtTNRnpcjBfBgNVHR8EWDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jv
# c29mdC5jb20vcGtpb3BzL2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENB
# JTIwMjAxMCgxKS5jcmwwbAYIKwYBBQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRw
# Oi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRp
# bWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNydDAMBgNVHRMBAf8EAjAAMBYGA1Ud
# JQEB/wQMMAoGCCsGAQUFBwMIMA4GA1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsF
# AAOCAgEA5FREMatVFNue6V+yDZxOzLKHthe+FVTs1kyQhMBBiwUQ9WC9K+ILKWvl
# qneRrvpjPS3/qXG5zMjrDu1eryfhbFRSByPnACGc2iuGcPyWNiptyTft+CBgrf7A
# TAuE/U8YLm29crTFiiZTWdT6Vc7L1lGdKEj8dl0WvDayuC2xtajD04y4ANLmWDui
# StdrZ1oI4afG5oPUg77rkTuq/Y7RbSwaPsBZ06M12l7E+uykvYoRw4x4lWaST87S
# BqeEXPMcCdaO01ad5TXVZDoHG/w6k3V9j3DNCiLJyC844kz3eh3nkQZ5fF8Xxuh8
# tWVQTfMiKShJ537yzrU0M/7H1EzJrabAr9izXF28OVlMed0gqyx+a7e+79r4EV/a
# 4ijJxVO8FCm/92tEkPrx6jjTWaQJEWSbL/4GZCVGvHatqmoC7mTQ16/6JR0FQqZf
# +I5opnvm+5CDuEKIEDnEiblkhcNKVfjvDAVqvf8GBPCe0yr2trpBEB5L+j+5haSa
# +q8TwCrfxCYqBOIGdZJL+5U9xocTICufIWHkb6p4IaYvjgx8ScUSHFzexo+ZeF7o
# yFKAIgYlRkMDvffqdAPx+fjLrnfgt6X4u5PkXlsW3SYvB34fkbEbM5tmab9zekRa
# 0e/W6Dt1L8N+tx3WyfYTiCThbUvWN1EFsr3HCQybBj4Idl4xK8EwggdxMIIFWaAD
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
# 2XBjU02N7oJtpQUQwXEGahC0HVUzWLOhcGbyoYIC1DCCAj0CAQEwggEAoYHYpIHV
# MIHSMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQL
# EyRNaWNyb3NvZnQgSXJlbGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsT
# HVRoYWxlcyBUU1MgRVNOOkZDNDEtNEJENC1EMjIwMSUwIwYDVQQDExxNaWNyb3Nv
# ZnQgVGltZS1TdGFtcCBTZXJ2aWNloiMKAQEwBwYFKw4DAhoDFQAWm5lp+nRuekl0
# iF+IHV3ylOiGb6CBgzCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
# aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
# MA0GCSqGSIb3DQEBBQUAAgUA6XmRWTAiGA8yMDI0MDIxNjE1NDYzM1oYDzIwMjQw
# MjE3MTU0NjMzWjB0MDoGCisGAQQBhFkKBAExLDAqMAoCBQDpeZFZAgEAMAcCAQAC
# AghYMAcCAQACAhFjMAoCBQDpeuLZAgEAMDYGCisGAQQBhFkKBAIxKDAmMAwGCisG
# AQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMBhqAwDQYJKoZIhvcNAQEFBQAD
# gYEAd6zi89EZgsfbd5ydCfDgUdnXsewwX/dVt0fO2mt+jZEfcg7cZoO285kulimD
# yY05A+wnsYRORaFeSdsOd4H1KRxprn2fgFK7D13EBuzfU3BEpA6BJcyoczDbYJaC
# 9DjYSMMJyQ5ad5s9w62zz8BgZmcTYhx0bvoCHG/N5Yrd/kIxggQNMIIECQIBATCB
# kzB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQD
# Ex1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAeKZmZXx3OMg6wAB
# AAAB4jANBglghkgBZQMEAgEFAKCCAUowGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJ
# EAEEMC8GCSqGSIb3DQEJBDEiBCBxbuJ3cKc6f3GdhmSfAg0kKTiLjbozTb9MHokn
# 17IldTCB+gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0EICuJKkoQ/Sa4xsFQRM4O
# gvh3ktToj9uO5whmQ4kIj3//MIGYMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAg
# UENBIDIwMTACEzMAAAHimZmV8dzjIOsAAQAAAeIwIgQgvAKbruc3T7ZAQqiYG5dq
# EDqld41wPmtTDeL3e+g24jwwDQYJKoZIhvcNAQELBQAEggIAn+XIZuIyupk7qiKF
# C7ax7RyV0ohjvJlJX08RPXwXGMifADeqigAFLVAGUWJ47p2FSPn0lzEt+vzf+vU7
# pLeKIxcCyVHM/xjWpNmxFWC0xaAtqkx63ukYYtL2gf6t7qQVnBx8ACGtyA3w+miO
# 2Oh86dEfBvO2HiTdfKYGwcsOXCqbqwq/7j05nfcu0jMPLYQsQKrJ/m/pito/mit8
# Vr9eGzTbX0oUjHxMX5QqjG3rKbX6zAYrojdw1KRiOl37oi8YaaR4p3JhIjLRcwPa
# 16+t0NPv5W0T9KCzk7ruKwX2Q1C87rZRXZcuCo0cMd9T7pXEnykOl24bbXFlbx1c
# 3gX6rdLYRJRpL+ilbWeiLNBXwrAA6G/54pIxPL3+BFwmk4hVZiPZEzsTfDJHPtIZ
# JklXWKI2kcczzZTrcFjNjOBNzBETOTcrY/cYum/I14i6MQNIIz5IkFA/yldhsQjG
# o9lNmDWo/GQvLPeBAScMjlt6guTCBOckjSIaU2HNsw9o39ySF5iJrx0i2fxajcb1
# jWRoJByONPxAkaLJcgbWQn5rUmwJWBeWAYmjKFB1Abi1UlXHNKfgc7gSexfJM3uk
# 1AitkinP1KhTWURwfuQtIMjpHm1V35XhOJc+sYlbrBtwjbk/IWYEFMd52HXhNrMK
# HSd+IUr1qx8stQi9Nu8Gc1N11mQ=
# SIG # End signature block
