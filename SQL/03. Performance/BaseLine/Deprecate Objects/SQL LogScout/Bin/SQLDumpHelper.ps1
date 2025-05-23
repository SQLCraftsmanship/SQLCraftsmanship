[CmdletBinding()]
param (
    [Parameter(Position=0, Mandatory=$true)]
    [string] $DumpOutputFolder = ".",
    [Parameter(Position=1, Mandatory=$true)]
    [string] $InstanceOnlyName = ""
)

$isInt = $false
$isIntValDcnt = $false
$isIntValDelay = $false
$SSISIdInt = 0
$NumFoler =""
$OneThruFour = "" 
$SqlDumpTypeSelection = ""
$SSASDumpTypeSelection = ""
$SSISDumpTypeSelection = ""
$SQLNumfolder=0
$SQLDumperDir=""
$OutputFolder= $DumpOutputFolder
$DumpType ="0x0120"
$ValidId
$SharedFolderFound=$false
$YesNo =""
$ProductNumber=""
$ProductStr = ""
$PIDInt = 0

#check for administrator rights
#debugging tools like SQLDumper.exe require Admin privileges to generate a memory dump

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
     Write-Warning "Administrator rights are required to generate a memory dump!`nPlease re-run this script as an Administrator!"
     #break
}



#what product would you like to generate a memory dump
while(($ProductNumber -ne "1") -and ($ProductNumber -ne "2") -and ($ProductNumber -ne "3") -and ($ProductNumber -ne "4") -and ($ProductNumber -ne "5"))
{
    Write-Host "Which product would you like to generate a memory dump of?" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "ID   Service/Process"
    Write-Host "--   ----------"
    Write-Host "1    SQL Server"
    Write-Host "2    SSAS (Analysis Services) "
    Write-Host "3    SSIS (Integration Services)"
    Write-Host "4    SSRS (Reporting Services)"
    Write-Host "5    SQL Server Agent"
    Write-Host ""
    $ProductNumber = Read-Host "Enter 1-5>" -CustomLogMessage "Dump Product console input:"

    if (($ProductNumber -ne "1") -and ($ProductNumber -ne "2") -and ($ProductNumber -ne "3") -and ($ProductNumber -ne "4")-and ($ProductNumber -ne "5"))
    {
        Write-Host ""
        Write-Host "Please enter a valid number from list above!"
        Write-Host ""
        Start-Sleep -Milliseconds 300
    }
}

if ($ProductNumber -eq "1")
{
    # $SqlTaskList has to be an array, so wrapped with @() guarantees an array regardless of number of elemets returned
    $SqlTaskList = @(Tasklist /SVC /FI "imagename eq sqlservr*" /FO CSV | ConvertFrom-Csv)
    $ProductStr = "SQL Server"
    
    # Nothing to do here as SQLLogScout already passes service name correct for SQL Server MSSQLSERVER / MSSQL$INSTANCENAME
}
elseif ($ProductNumber -eq "2")
{
    $SqlTaskList = @(Tasklist /SVC /FI "imagename eq msmdsrv*" /FO CSV | ConvertFrom-Csv)
    $ProductStr = "SSAS (Analysis Services)"

    if (-1 -eq $InstanceOnlyName.IndexOf("`$")){ # default SSAS instance
        $InstanceOnlyName = "MSSQLServerOLAPService"
    } else { # named SSAS instance
        $InstanceOnlyName = "MSOLAP`$" + $InstanceOnlyName.Split("`$")[1]
    }
}
elseif ($ProductNumber -eq "3")
{
    $SqlTaskList = @(Tasklist /SVC /FI "imagename eq msdtssrvr*" /FO CSV | ConvertFrom-Csv)
    $ProductStr = "SSIS (Integration Services)"
    
    $InstanceOnlyName = "MsDtsServer<VERSION>"
}
elseif ($ProductNumber -eq "4")
{
    $SqlTaskList = @(Tasklist /SVC /FI "imagename eq reportingservicesservice*" /FO CSV | ConvertFrom-Csv)
    $ProductStr = "SSRS (Reporting Services)"
    
    if (-1 -eq $InstanceOnlyName.IndexOf("`$")){ # default SSRS instance
        $InstanceOnlyName = "ReportServer"
    } else { # named SSRS instance
        $InstanceOnlyName = "ReportServer`$" + $InstanceOnlyName.Split("`$")[1]
    }
}
elseif ($ProductNumber -eq "5")
{
    $SqlTaskList = @(Tasklist /SVC /FI "imagename eq sqlagent*" /FO CSV | ConvertFrom-Csv)
    $ProductStr = "SQL Server Agent"
    
    if (-1 -eq $InstanceOnlyName.IndexOf("`$")){ # default SQLAgent instance
        $InstanceOnlyName = "SQLSERVERAGENT"
    } else { # named SQLAgent instance
        $InstanceOnlyName = "SQLAgent`$" + $InstanceOnlyName.Split("`$")[1]
    }
}

if (($SqlTaskList.Count -eq 0))
{
    Write-Host "There are curerntly no running instances of $ProductStr. Exiting..." -ForegroundColor Green
    Start-Sleep -Seconds 2
    return
} elseif (("3" -ne $ProductNumber) -and (($SqlTaskList | Where-Object {$_.Services -like "*$InstanceOnlyName"} | Measure-Object).Count -eq 0)) {

    while (($YesNo -ne "y") -and ($YesNo -ne "n"))
    {
        Write-Host "Instance $InstanceOnlyName is not currently running. Would you like to generate a dump of another $ProductStr instance? (Y/N)" -ForegroundColor Yellow
        $YesNo = Read-Host "(Y/N)> "
    
        $YesNo = $YesNo.ToUpper()
        if (($YesNo -eq "Y") -or ($YesNo -eq "N") )
        {
            break
        }
        else
        {
            Write-Host "Not a valid 'Y' or 'N' response"
        }
    }
    
    if ($YesNo -eq "Y")
    {
        
        Write-LogInformation "Discovered the following $ProductStr Service(s)`n"
        Write-LogInformation ""
        Write-LogInformation "ID	Service Name"
        Write-LogInformation "--	----------------"

        for($i=0; $i -lt $SqlTaskList.Count;$i++)
        {
            Write-LogInformation $i "	" $SqlTaskList[$i].Services
        }
        
        #check input and make sure it is a valid integer
        $isInt = $false
        $ValidId = $false
        while(($isInt -eq $false) -or ($ValidId -eq $false))
        {   
            Write-LogInformation ""
            Write-Host "Please enter the ID for the desired $ProductStr from list above" -ForegroundColor Yellow
            $IdStr = Read-Host ">" -CustomLogMessage "ID choice console input:"
        
            try{
                $IdInt = [convert]::ToInt32($IdStr)
                $isInt = $true
            }
            catch [FormatException]
            {
                Write-Host "The value entered for ID '",$IdStr,"' is not an integer"
            }
            
            if(($IdInt -ge 0) -and ($IdInt -le ($SqlTaskList.Count-1)))
            {
                $ValidId = $true
                $PIDInt = $SqlTaskList[$IdInt].PID
                $InstanceOnlyName = $SqlTaskList[$IdInt].Services
                break;
            }

        }
    } 
}

# if we still don't have a PID to dump
if (0 -eq $PIDInt)
{
    # for anything other than SSIS
    if (-not ($InstanceOnlyName.StartsWith("MsDtsServer", [System.StringComparison]::CurrentCultureIgnoreCase)))
    {
        Write-Host "$ProductStr service name = '$InstanceOnlyName'"
        $PIDStr = $SqlTaskList | Where-Object {$_.Services -like "*$InstanceOnlyName"} | Select-Object PID
        Write-Host "Service ProcessID = '$($PIDStr.PID)'"
        $PIDInt = [convert]::ToInt32($PIDStr.PID)
    
        Write-LogDebug "Using PID = '$PIDInt' for generating a $ProductStr memory dump" -DebugLogLevel 1
        Write-Host ""

    } else {

        #if multiple SSIS processes, get the user to input PID for desired SQL Server
        if ($SqlTaskList.Count -gt 1) 
        {
            Write-Host "More than one $ProductStr instance found." 

            #$SqlTaskList | Select-Object  PID, "Image name", Services |Out-Host 
            $SSISServices = Tasklist /SVC /FI "imagename eq msdtssrvr*" /FO CSV | ConvertFrom-Csv | Sort-Object -Property services
            
            Write-LogInformation "Discovered the following SSIS Service(s)`n"
            Write-LogInformation ""
            Write-LogInformation "ID	Service Name"
            Write-LogInformation "--	----------------"

            for($i=0; $i -lt $SSISServices.Count;$i++)
            {
                Write-LogInformation $i "	" $SSISServices[$i].Services
            }
            
            #check input and make sure it is a valid integer
            $isInt = $false
            $ValidId = $false
            while(($isInt -eq $false) -or ($ValidId -eq $false))
            {   
                Write-LogInformation ""
                Write-Host "Please enter the ID for the desired SSIS from list above" -ForegroundColor Yellow
                $SSISIdStr = Read-Host ">" -CustomLogMessage "ID choice console input:"
            
                try{
                        $SSISIdInt = [convert]::ToInt32($SSISIdStr)
                        $isInt = $true
                    }

                catch [FormatException]
                    {
                        Write-Host "The value entered for ID '",$SSISIdStr,"' is not an integer"
                    }
                
                if(($SSISIdInt -ge 0) -and ($SSISIdInt -le ($SSISServices.Count-1)))
                {
                    $ValidId = $true
                    $PIDInt = $SSISServices[$SSISIdInt].PID
                    break;
                }

            }   

        
            Write-Host "Using PID=$PIDInt for generating a $ProductStr memory dump" -ForegroundColor Green
            Write-Host ""
            
        }
        else #if only one SSSIS on the box, go here
        {
            $SqlTaskList | Select-Object PID, "Image name", Services |Out-Host
            $PIDInt = [convert]::ToInt32($SqlTaskList.PID)
        
            Write-Host "Using PID=", $PIDInt, " for generating a $ProductStr memory dump" -ForegroundColor Green
            Write-Host ""
        }
    }
}

#dump type
if ($ProductNumber -eq "1")  #SQL Server memory dump
{
    #ask what type of SQL Server memory dump 
    while(($SqlDumpTypeSelection  -ne "1") -and ($SqlDumpTypeSelection -ne "2") -And ($SqlDumpTypeSelection -ne "3") -And ($SqlDumpTypeSelection -ne "4" ))
    {
        Write-Host "Which type of memory dump would you like to generate?`n" -ForegroundColor Yellow
        Write-Host "ID   Dump Type"
        Write-Host "--   ---------"
        Write-Host "1    Mini-dump"
        Write-Host "2    Mini-dump with referenced memory (Recommended)" 
        Write-Host "3    Filtered dump  (Not Recommended)"
        Write-Host "4    Full dump      (Do Not Use on Production systems!)"
        Write-Host ""
        $SqlDumpTypeSelection = Read-Host "Enter 1-4>" -CustomLogMessage "Dump type console input:"

        if (($SqlDumpTypeSelection -ne "1") -and ($SqlDumpTypeSelection -ne "2") -And ($SqlDumpTypeSelection -ne "3") -And ($SqlDumpTypeSelection -ne "4" ))
        {
            Write-Host ""
            Write-Host "Please enter a valid type of memory dump!"
            Write-Host ""
            Start-Sleep -Milliseconds 300
        }
    }

    Write-Host ""

    switch ($SqlDumpTypeSelection)
    {
        "1" {$DumpType="0x0120";break}
        "2" {$DumpType="0x0128";break}
        "3" {$DumpType="0x8100";break}
        "4" {$DumpType="0x01100";break}
        default {"0x0120"; break}

    }


    Write-LogDebug "SQL Version: $SqlVersion" -DebugLogLevel 1

    [string]$CompressDumpFlag = ""

    
    # if the version is between SQL 2019, CU23 (16000004075) and  16000000000 (SQL 2022)  
    # or if greater than or equal to 2022 CU8 (16000004075), then we can create a compressed dump -zdmp flag

    #if (($SqlDumpTypeSelection -in ("3", "4")) -and  ((($SqlVersion -ge 15000004335) -and ($SqlVersion -lt 16000000000)) -or ($SqlVersion -ge 16000004075)) )
    if (($SqlDumpTypeSelection -in ("3", "4")) -and  (checkSQLVersion -VersionsList @("2022RTMCU8", "2019RTMCU23") -eq $true) ) 
    {
        
        Write-Host "Starting with SQL Server 2019 CU23 and SQL Server 2022 CU8, you can create a compressed full or filter memory dump."
        Write-Host "Would you like to create compressed memory dumps?" 
        
        while (($isCompressedDump -ne "Y") -and ($isCompressedDump -ne "N"))
        {
        
            $isCompressedDump = Read-Host "Create a compressed memory dump? (Y/N)" -CustomLogMessage "Compressed Dump console input:"
            $isCompressedDump = $isCompressedDump.ToUpper()

            if ($isCompressedDump -eq "Y")
            {
                $CompressDumpFlag = "-zdmp"
            }
            elseif ($isCompressedDump -eq "N")
            {
                $CompressDumpFlag = ""
            }
            else 
            {
                Write-Host "Not a valid 'Y' or 'N' response"
            }
        }
    }
    else {
        Write-Host "WARNING: Filtered and Full dumps are not recommended for production systems. They might cause performance issues and should only be used when directed by Microsoft Support." -ForegroundColor Yellow
        Write-Host ""
    }



}
elseif ($ProductNumber -eq "2")  #SSAS dump 
{

    #ask what type of SSAS memory dump 
    while(($SSASDumpTypeSelection  -ne "1") -and ($SSASDumpTypeSelection -ne "2"))
    {
        Write-Host "Which type of memory dump would you like to generate?" -ForegroundColor Yellow
        Write-Host "1) Mini-dump"
        Write-Host "2) Full dump  (Do Not Use on Production systems!)" -ForegroundColor Red
        Write-Host ""
        $SSASDumpTypeSelection = Read-Host "Enter 1-2>" -CustomLogMessage "SSAS Dump Type console input:"

        if (($SSASDumpTypeSelection -ne "1") -and ($SSASDumpTypeSelection -ne "2"))
        {
            Write-Host ""
            Write-Host "Please enter a valid type of memory dump!"
            Write-Host ""
            Start-Sleep -Milliseconds 300
        }
    }

    Write-Host ""

    switch ($SSASDumpTypeSelection)
    {
        "1" {$DumpType="0x0";break}
        "2" {$DumpType="0x34";break}
        default {"0x0120"; break}

    }
}

elseif ($ProductNumber -eq "3" -or $ProductNumber -eq "4" -or $ProductNumber -eq "5")  #SSIS/SSRS/SQL Agent dump
{

    #ask what type of SSIS memory dump 
    while(($SSISDumpTypeSelection   -ne "1") -and ($SSISDumpTypeSelection  -ne "2"))
    {
        Write-Host "Which type of memory dump would you like to generate?" -ForegroundColor Yellow
        Write-Host "1) Mini-dump"
        Write-Host "2) Full dump" 
        Write-Host ""
        $SSISDumpTypeSelection = Read-Host "Enter 1-2>" -CustomLogMessage "SSIS Dump Type console input:"

        if (($SSISDumpTypeSelection  -ne "1") -and ($SSISDumpTypeSelection  -ne "2"))
        {
            Write-Host ""
            Write-Host "Please enter a valid type of memory dump!"
            Write-Host ""
            Start-Sleep -Milliseconds 300
        }
    }

    Write-Host ""

    switch ($SSISDumpTypeSelection)
    {
        "1" {$DumpType="0x0";break}
        "2" {$DumpType="0x34";break}
        default {"0x0120"; break}

    }
}


# Sqldumper.exe PID 0 0x0128 0 c:\temp
#output folder
while($OutputFolder -eq "" -or !(Test-Path -Path $OutputFolder))
{
    Write-Host ""
    Write-Host "Where would your like the memory dump stored (output folder)?" -ForegroundColor Yellow
    $OutputFolder = Read-Host "Enter an output folder with no quotes (e.g. C:\MyTempFolder or C:\My Folder)" -CustomLogMessage "Dump Output Folder console input:"
    if ($OutputFolder -eq "" -or !(Test-Path -Path $OutputFolder))
    {
        Write-Host "'" $OutputFolder "' is not a valid folder. Please, enter a valid folder location" -ForegroundColor Yellow
    }
}

#strip the last character of the Output folder if it is a backslash "\". Else Sqldumper.exe will fail
if ($OutputFolder.Substring($OutputFolder.Length-1) -eq "\")
{
    $OutputFolder = $OutputFolder.Substring(0, $OutputFolder.Length-1)
    Write-LogDebug "Stripped the last '\' from output folder name. Now folder name is  $OutputFolder" -DebugLogLevel 1
}

#find the highest version of SQLDumper.exe on the machine
$NumFolder = Get-ChildItem -Path "c:\Program Files\microsoft sql server\1*" -Directory | Select-Object @{name = "DirNameInt"; expression={[int]($_.Name)}}, Name, Mode | Sort-Object DirNameInt -Descending

for($j=0;($j -lt $NumFolder.Count); $j++)
{
    $SQLNumfolder = $NumFolder.DirNameInt[$j]   #start with the highest value from sorted folder names - latest version of dumper
    $SQLDumperDir = "c:\Program Files\microsoft sql server\"+$SQLNumfolder.ToString()+"\Shared\"
    $TestPathDumperDir = $SQLDumperDir+"sqldumper.exe" 
    
    $TestPathResult = Test-Path -Path $SQLDumperDir 
    
    if ($TestPathResult -eq $true)
    {
        break;
    }
 }

#build the SQLDumper.exe command e.g. (Sqldumper.exe 1096 0 0x0128 0 c:\temp\)

$cmd = "$([char]34)"+$SQLDumperDir + "sqldumper.exe$([char]34)"
$arglist = $PIDInt.ToString() + " 0 " +$DumpType +" 0 $([char]34)" + $OutputFolder + "$([char]34) " + $CompressDumpFlag
Write-Host "Command for dump generation: ", $cmd, $arglist -ForegroundColor Green

#do-we-want-multiple-dumps section
Write-Host ""
Write-Host "This utility can generate multiple memory dumps, at a certain interval"
Write-Host "Would you like to collect multiple memory dumps?" -ForegroundColor Yellow

#validate Y/N input
$YesNo = $null # reset the variable because it could be assigned at this point
while (($YesNo -ne "y") -and ($YesNo -ne "n"))
{
    $YesNo = Read-Host "Enter Y or N>" -CustomLogMessage "Multiple Dumps Choice console input:"

    if (($YesNo -eq "y") -or ($YesNo -eq "n") )
    {
        break
    }
    else
    {
        Write-Host "Not a valid 'Y' or 'N' response"
    }
}


#get input on how many dumps and at what interval
if ($YesNo -eq "y")
{
    [int]$DumpCountInt=0
    while(1 -ge $DumpCountInt)
    {
        Write-Host "How many dumps would you like to generate for this $ProductStr" -ForegroundColor Yellow
        $DumpCountStr = Read-Host ">" -CustomLogMessage "Dump Count console input:"

        try
        {
            $DumpCountInt = [convert]::ToInt32($DumpCountStr)

            if(1 -ge $DumpCountInt)
            {
                Write-Host "Please enter a number greater than one." -ForegroundColor Red
            }
        }
        catch [FormatException]
        {
                Write-Host "The value entered for dump count '",$DumpCountStr,"' is not an integer" -ForegroundColor Red
        }
        
    }

    [int]$DelayIntervalInt=0
    while(0 -ge $DelayIntervalInt)
    {
        Write-Host "How frequently (in seconds) would you like to generate the memory dumps?" -ForegroundColor Yellow
        $DelayIntervalStr = Read-Host ">" -CustomLogMessage "Dump Frequency console input:"

        try
        {
            $DelayIntervalInt = [convert]::ToInt32($DelayIntervalStr)
            if(0 -ge $DelayIntervalInt)
            {
                Write-Host "Please enter a number greater than zero." -ForegroundColor Red
            }
        }
        catch [FormatException]
        {
            Write-Host "The value entered for frequency (in seconds) '",$DelayIntervalStr,"' is not an integer" -ForegroundColor Red
        }
    }

    Write-Host "The configuration is ready. Press <Enter> key to proceed..."
    Read-Host -Prompt "<Enter> to proceed"

    Write-Host "Generating $DumpCountInt memory dumps at a $DelayIntervalStr-second interval" -ForegroundColor Green

    #loop to generate multiple dumps    
    $cntr = 0

    while($true)
    {
        Start-Process -FilePath $cmd -Wait -Verb runAs -ArgumentList $arglist 
        $cntr++

        Write-Host "Generated $cntr memory dump(s)." -ForegroundColor Green

        if ($cntr -ge $DumpCountInt)
            {
                break
            }
        Start-Sleep -S $DelayIntervalInt
    }

    #print what files exist in the output folder
    Write-Host ""
    Write-Host "Here are all the memory dumps in the output folder '$OutputFolder'" -ForegroundColor Green
    #$MemoryDumps = $OutputFolder + "\SQLDmpr*"
    $dumps_string = Get-ChildItem -Path ($OutputFolder + "\SQLDmpr*") | Out-String
    Write-Host $dumps_string

    Write-Host "Process complete"
}

else #produce just a single dump
{
    Write-Host "The configuration is ready. Press <Enter> key to proceed..."
    Read-Host -Prompt "<Enter> to proceed"
    
    Start-Process -FilePath $cmd -Wait -Verb runAs -ArgumentList $arglist 

    #print what files exist in the output folder
    Write-Host ""
    Write-Host "Here are all the memory dumps in the output folder '$OutputFolder'" -ForegroundColor Green
    $MemoryDumps = $OutputFolder + "\SQLDmpr*"
    Get-ChildItem -Path $MemoryDumps

    Write-Host ""
    Write-Host "Process complete"
}

Write-Host "For errors and completion status, review SQLDUMPER_ERRORLOG.log created by SQLDumper.exe in the output folder '$OutputFolder'. `Or if SQLDumper.exe failed look in the folder from which you are running this script"

# SIG # Begin signature block
# MIIoPQYJKoZIhvcNAQcCoIIoLjCCKCoCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAYTD0YhAY4VkGn
# 9yK29rU09Oiov0Eat005YBqFvJcRAKCCDYUwggYDMIID66ADAgECAhMzAAADri01
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
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICw1
# 3THBwjmPcrKj2FDcOcBH0FSNgV+4T6L6SLC0I6CGMEQGCisGAQQBgjcCAQwxNjA0
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEcgBpodHRwczovL3d3d3cubWljcm9zb2Z0
# LmNvbTANBgkqhkiG9w0BAQEFAASCAQBum8hcjX6hmZ956WRfjYQ2SN4k3QZ6cB9h
# gsv9LPiVgx2aYaMHohIQi6RQHMBYXAyPUrq446zoY6WxnKRs6UZ3811znEAWZR4i
# 9OQfE7i38l0cfUADabyt1MyapIl55UFHuBXOEk+asJRgLLqGTQ0qeOdVHls8WpDZ
# 4TfhfeNNNzrWfw5SuchOmo+gShAWuPVqWUPFy4McxspNlxm64Vpooepv9opkpX9f
# y07s8P6MxfKgZEqcz2fMyVqX55yhieL59k6yd7Jja/tKqu7AQy2tpz5a/ePONGap
# I3VKybUY1EodFY/R86BMrcJ7LOgWEfSJ/WzCSs6v6C2J6JgfcSiIoYIXljCCF5IG
# CisGAQQBgjcDAwExgheCMIIXfgYJKoZIhvcNAQcCoIIXbzCCF2sCAQMxDzANBglg
# hkgBZQMEAgEFADCCAVIGCyqGSIb3DQEJEAEEoIIBQQSCAT0wggE5AgEBBgorBgEE
# AYRZCgMBMDEwDQYJYIZIAWUDBAIBBQAEILIMVzD+f07CQCXd7BdzyC5uP2z2UGMy
# CxK3F4g1zNZFAgZlzf7wSf4YEzIwMjQwMjE2MDkwMDU2LjY2OVowBIACAfSggdGk
# gc4wgcsxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNV
# BAsTHE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGll
# bGQgVFNTIEVTTjo5MjAwLTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRp
# bWUtU3RhbXAgU2VydmljZaCCEewwggcgMIIFCKADAgECAhMzAAAB5y6PL5MLTxvp
# AAEAAAHnMA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
# YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAy
# MDEwMB4XDTIzMTIwNjE4NDUxOVoXDTI1MDMwNTE4NDUxOVowgcsxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBB
# bWVyaWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjo5MjAw
# LTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vydmlj
# ZTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAMJXny/gi5Drn1c8zUO1
# pYy/38dFQLmR2IQXz1gE/r9GfuSOoyRnkRJ6Z/kSWLgIu1BVJ59GkXWPtLkssqKw
# xY4ZFotxpVsZN9yYjW8xEnW3MzAI0igKr+/LxYfxB1XUH8Bvmwr5D3Ii/MbDjtN9
# c8TxGWtq7Ar976dafAy3TrRqQRmIknPVWHUuFJgpqI/1nbcRmYYRMJaKCQpty4Ce
# G+HfKsxrz24F9p4dBkQcZCp2yQzjwQFxZJZ2mJJIGIDHKEdSRuSeX08/O0H9JTHN
# FmNTNYeD1t/WapnRwiIBYLQSMrs42GVB8pJEdUsos0+mXf/5QvheNzRi92pzzyA4
# tSv/zhP3/Ermvza6W9GnYDz9qv1wbhbvrnS4poDFECaAviEqAhfn/RogCxvKok5r
# o4gZIX1r4N9eXUulA80pHv3axwXu2MPlarAi6J9L1hSIcy9EuOMqTRJIJX+alcLQ
# Gg+STlqx/GuslsKwl48dI4RuWknNGbNo/o4xfBFytvtNcVA6xOQq6qRa+9gg+9XM
# LrxQz4yyQs+V3V6p044wrtJtt/a0ZJl/f6I7BZAxxZcH2DDmArcAhgrTxaQkm7LM
# +p+K2C5t1EKZiv0JWw065b7AcNgaFyIkMXYuSuOQVSNRxdIgl31/ayxiK1n0K6sZ
# XvgFBx+vGO+TUvyO+03ua6UjAgMBAAGjggFJMIIBRTAdBgNVHQ4EFgQUz/7gmICf
# Njh2kR/9mWuHUrvej1gwHwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIw
# XwYDVR0fBFgwVjBUoFKgUIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9w
# cy9jcmwvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3Js
# MGwGCCsGAQUFBwEBBGAwXjBcBggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3Nv
# ZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENB
# JTIwMjAxMCgxKS5jcnQwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEF
# BQcDCDAOBgNVHQ8BAf8EBAMCB4AwDQYJKoZIhvcNAQELBQADggIBAHSh8NuT6WVa
# LVwLqex+J7km2nT2jpvoBEKm+0M+rYoU/6GL5Q00/ssZyIq5ySpcKYFMUiF8F4ZL
# G+TrJyiR1CvfzXmkQ5phZOce9DT7yErLzqvUXit8G7igcHlxPLTxPiiGsb85gb8H
# +A2fPQ6Xq/u7+oSPPjzNdnpmXEobJnAqYplZoF3YNgTDMql0uQHGzoDp6dZlHSNj
# 6rkV1tXjmCEZMqBKvkQIA6csPieMnB+MirSZFlbANlChe0lJpUdK7aUdAvdgcQWK
# S6dtRMl818EMsvsa/6xOZGINmTLk4DGgsbaBpN+6IVt+mZJ89yCXkI5TN8xCfOkp
# 9fr4WQjRBA2+4+lawNTyxH66eLZWYOjuuaomuibiKGBU10tox81Sq8EvlmJIrXOZ
# oQsEn1r5g6MTmmZJqtbmwZufuJWQXZb0lAg4fq0ZYsUlLkezfrNqGSgeHyIP3rct
# 4aNmqQW6wppRbvbIyP/LFN4YQM6givfmTBfGvVS77OS6vbL4W41jShmOmnOn3kBb
# WV6E/TFo76gFXVd+9oK6v8Hk9UCnbHOuiwwRRwDCkmmKj5Vh8i58aPuZ5dwZBhYD
# xSavwroC6j4mWPwh4VLqVK8qGpCmZ0HMAwao85Aq3U7DdlfF6Eru8CKKbdmIAuUz
# QrnjqTSxmvF1k+CmbPs7zD2Acu7JkBB7MIIHcTCCBVmgAwIBAgITMwAAABXF52ue
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
# BmoQtB1VM1izoXBm8qGCA08wggI3AgEBMIH5oYHRpIHOMIHLMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1l
# cmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046OTIwMC0w
# NUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2Wi
# IwoBATAHBgUrDgMCGgMVALNyBOcZqxLB792u75w97U0X+/BDoIGDMIGApH4wfDEL
# MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
# bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWlj
# cm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwDQYJKoZIhvcNAQELBQACBQDpeH0/
# MCIYDzIwMjQwMjE1MTIwODMxWhgPMjAyNDAyMTYxMjA4MzFaMHYwPAYKKwYBBAGE
# WQoEATEuMCwwCgIFAOl4fT8CAQAwCQIBAAIBcQIB/zAHAgEAAgISWDAKAgUA6XnO
# vwIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMCoAowCAIBAAIDB6Eg
# oQowCAIBAAIDAYagMA0GCSqGSIb3DQEBCwUAA4IBAQBpetfGu27vWf3H7pp3n/Xe
# GOdakl2L2YlEoGAI9nqy9xsY6cgrZtcn0tHPtNfnidmB1nqBgIhN81OjmZLvCiOb
# EdXW0s93LM3Nu/eGdUAUhwl5GD29orD0u2cHMjzS4E2sP+P7bwnDtguHpeUcp8tX
# Mgr5eOdZ5GGQQKOZjrxyrEK4xFcsLfRgy+ciZV8DYFzwEqZpLZYnO35CyJthYo2m
# zKPmghVmW4xxRa3IkreLl3mQDqY3qscC3ZiYcJumHF35HWjqV5uRPI9rHhD6B5Q2
# RANgojfDxKFfYlOYjkoyJpf2YgtvGnNDQ/bHwEx6wsYmTHWLZNasoyTPpDqTZSHP
# MYIEDTCCBAkCAQEwgZMwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0
# b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
# dGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMA
# AAHnLo8vkwtPG+kAAQAAAecwDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJ
# AzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQgNI0RpodMTjjPUQeKjI8v
# IKdg61enGzGqxWOHmP9caj8wgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCDl
# Nl0NdmqG/Q3gxVzPVBR3hF++Bb9AAb0DBu6gudZzrTCBmDCBgKR+MHwxCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
# HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29m
# dCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB5y6PL5MLTxvpAAEAAAHnMCIEIG0r
# YnLtiEF+0VeGlSpIUy3hB3JwVELbYZce0/YAkI7uMA0GCSqGSIb3DQEBCwUABIIC
# ACb7VuWYUsofvmyFqpFAL8tNMabnaSwzPEc3PLwf0nKACmz5PfeSEjUcBzSmlUEQ
# RblzmCxpGhqVXO8dXA/3aHp9gXdq//fgU/TsKcusm3bB9Xq5DMTiWihk0gnzKFM3
# ToEbBk+4J5Zg/+U1hStlsBgnjssnkBNJpgTbixZvh0OaPobFeg+piSFdJDG6yUrw
# Q4yN6UCDkz4ikrQoMqWqHU2SNNUbLUqSjO8FuAhlHluhklt1CjSbomZcQR4w4Lhn
# tNEtuT6sg4Bnklm8uuYbTXQOu0QfdbOUna49rI7yG1cZidLZp5g5u+83awQyA+RV
# KoThTpaQ+229kAl1d35Ke/fbllOORSgOcbhgNqsTEXi/9vnshf8X/nyXBmsZIFdn
# OkKH8Ez/QsKI5bPM0u5ouyXLv/KDG4VVgCqH0I8lPAHzKYlJSSwTgQvJEIecvHOl
# NUybgzyZpAseRTNI8WkycQPodx6cFiEfTkMLQVchOzcDl1S4/VydADKIQM1kakjx
# 1bXufugEgFfRcO9Ixqqw/C15eOtuYZoOgZ9RGot+Cq7xwBhZSw9aS+tNNsfVS6yf
# AHTWJoFgGej+A1sh/EB/t80fCMwX71SRsCXPuCsTda9E3ehH1trF7KArxdmn3gUg
# mIMjPYhrGa4HkWHTS24TEPNKyMCQz+cgMTMbIPCNiuc2
# SIG # End signature block
