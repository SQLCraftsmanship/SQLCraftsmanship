param
(
    #servername\instancename is an optional parameter
    [Parameter(Position=0)]
    [string] $ServerName = $env:COMPUTERNAME,
    
    [Parameter(Position=1,Mandatory=$true)]
    [string] $Scenarios = "WRONG_SCENARIO",

    [Parameter(Position=2,Mandatory=$true)]
    [string] $SummaryOutputFile,

    [Parameter(Position=3)]
    [string] $SqlNexusPath,

    [Parameter(Position=4)]
    [string] $SqlNexusDb,

    [Parameter(Position=5)]
    [string] $LogScoutOutputFolder,

    [Parameter(Position=6,Mandatory=$true)]
    [string] $RootFolder,

    [Parameter(Position=7)]
    [bool] $RunTSQLLoad = $false,

    [Parameter(Position=8)]
    [string] $DisableCtrlCasInput = "False"
)

$TSQLLoadModule = (Get-Module -Name TSQLLoadModule).Name

if ($TSQLLoadModule -ne "TSQLLoadModule")
    {
        Import-Module .\GenerateTSQLLoad.psm1
    }

$TSQLLoadCommonFunction = (Get-Module -Name CommonFunctions).Name

if ($TSQLLoadCommonFunction -ne "CommonFunctions")
    {
        #Since we are in bin and CommonFunctions is in root directory, we need to step out to import module
        #This is so we can use HandleCatchBlock
        $CurrentPath = Get-Location
        [string]$CommonFunctionsModule = (Get-Item $CurrentPath).parent.FullName + "\CommonFunctions.psm1"
        Import-Module -Name $CommonFunctionsModule
    }




Write-Output "" | Out-File $SummaryOutputFile -Append
Write-Output "" | Out-File $SummaryOutputFile -Append
Write-Output "********************************************************************" | Out-File $SummaryOutputFile -Append
Write-Output "                      Starting '$Scenarios' test                    " | Out-File $SummaryOutputFile -Append     
Write-Output "                      $(Get-Date -Format "dd MMMM yyyy HH:mm:ss")   " | Out-File $SummaryOutputFile -Append     
Write-Output "                      Server Name: $ServerName                      " | Out-File $SummaryOutputFile -Append
Write-Output "********************************************************************" | Out-File $SummaryOutputFile -Append

Write-Output "********************************************************************" 
Write-Output "                      Starting '$Scenarios' test"                     
Write-Output "                      $(Get-Date -Format "dd MMMM yyyy HH:mm:ss")    "
Write-Output "                      Server Name: $ServerName                      " 
Write-Output "********************************************************************" 

[bool] $script_ret = $true
[int] $return_val = 0

# validate root folder 
$PathFound = Test-Path -Path $RootFolder 
if ($PathFound -eq $false)
{
    Write-Host "Invalid Root directory for testing. Exiting."
    $return_val = 4
    return $return_val
}

# start and stop times for LogScout execution

if ($Scenarios -match "NeverEndingQuery"){
    # NeverEndingQuery scenario needs 60 seconds to run before test starts so we can accumulate 60 seconds of CPU time
    $StartTime = (Get-Date).AddSeconds(60).ToString("yyyy-MM-dd HH:mm:ss")
}
else {
    $StartTime = (Get-Date).AddSeconds(20).ToString("yyyy-MM-dd HH:mm:ss")
}

# stop time is 3 minutes from start time. This is to ensure that we have enough data to analyze 
# also ensures that on some machines where the test runs longer, we don't lose logs due to the test ending prematurely
$StopTime = (Get-Date).AddMinutes(3).ToString("yyyy-MM-dd HH:mm:ss")

# start TSQLLoad execution
if ($RunTSQLLoad -eq $true)
{
    Initialize-TSQLLoadLog -Scenario $Scenarios

    TSQLLoadInsertsAndSelectFunction -ServerName $ServerName
}


##execute a regular SQL LogScout data collection from root folder
Write-Host "Starting LogScout"

#build command line and arguments
$LogScoutCmd = "`"" + $RootFolder  + "\SQL_LogScout.cmd" + "`"" 
$argument_list =  $Scenarios + " `"" + $ServerName + "`" UsePresentDir DeleteDefaultFolder `"" + $StartTime.ToString() + "`" `"" + $StopTime.ToString() + "`" Quiet " + $DisableCtrlCasInput

#execute LogScout
Start-Process -FilePath $LogScoutCmd -ArgumentList $argument_list -Wait -NoNewWindow

Write-Host "LogScoutCmd: $LogScoutCmd"
Write-Host "Argument_list: $argument_list"

if ($RunTSQLLoad -eq $true)
{

    Write-Host "Verifying T-SQL workload finished"
    TSQLLoadCheckWorkloadExited
}

#run file validation test

$script_ret = ./FilecountandtypeValidation.ps1 -SummaryOutputFile $SummaryOutputFile 2> .\##TestFailures.LOG
..\StdErrorOutputHandling.ps1 -FileName .\##TestFailures.LOG

if ($script_ret -eq $false)
{
    #FilecountandtypeValidation test failed, return a unique, non-zero value
    $return_val = 1
}

#check SQL_LOGSCOUT_DEBUG log for errors
. .\LogParsing.ps1

# $LogNamePattern defaults to "..\output\internal\##SQLLOGSCOUT_DEBUG.LOG"
# $SummaryFilename defaults to ".\output\SUMMARY.TXT"
# $DetailedFilename defaults to ".\output\DETAILED.TXT"
$script_ret = Search-Log -LogNamePattern ($RootFolder + "\output\internal\##SQLLOGSCOUT_DEBUG.LOG")

if ($script_ret -eq $false)
{
    #Search-Log test failed, return a unique, non-zero value
    $return_val = 2
}

#run SQLNexus import and table verficiation test
$script_ret = .\SQLNexus_Test.ps1 -ServerName $ServerName -Scenarios $Scenarios -OutputFilename $SummaryOutputFile -SqlNexusPath $SqlNexusPath -SqlNexusDb $SqlNexusDb -LogScoutOutputFolder $LogScoutOutputFolder -SQLLogScoutRootFolder $RootFolder


if ($script_ret -eq $false)
{
    #SQLNexus test failed, return a non-zero value
    $return_val = 3
}

Write-Host "Scenario_Test return value: $return_val" | Out-Null
return $return_val




# SIG # Begin signature block
# MIIoPAYJKoZIhvcNAQcCoIIoLTCCKCkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCaykm1kXTcQqHT
# WwaooMC2YfF65CHlWmZtlngllE2JS6CCDYUwggYDMIID66ADAgECAhMzAAADri01
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
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIve
# /TENC509A2oMD6Z33hvIkWsYK1imktIxRgs9DRzAMEQGCisGAQQBgjcCAQwxNjA0
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEcgBpodHRwczovL3d3d3cubWljcm9zb2Z0
# LmNvbTANBgkqhkiG9w0BAQEFAASCAQB1Z1EUMykXjk/a2hpHIJHS+xXjP6MdlCNp
# b+c5qL1shjwKjkm0ZALeS1YzC082Cdyxpi4ywmHuJt+PtuKMuqtlgrMoeG3Esfuf
# 8C1Jtw2psC6wEWsY3UXZem9uc3JsM/1X7Cs5jaB0CHCevZ8oKx5vh6n0OWw4gtQy
# cLDnExrPwJLAExRpV2FQ22FJ1SA/IP/cDlUQWYwf7axhnC3m1U5BCaKS4K3T5rZC
# gWApjOVuYeMKvR4NPaBzbI31cPFI1OgSewkCYisrivg165FujRF8AIC8QI9kvto7
# wk1K92k3Ugi4X3xUsvjISUfKd77Q1XhskTmUW8jBmwMZRxJ5wrvQoYIXlTCCF5EG
# CisGAQQBgjcDAwExgheBMIIXfQYJKoZIhvcNAQcCoIIXbjCCF2oCAQMxDzANBglg
# hkgBZQMEAgEFADCCAVEGCyqGSIb3DQEJEAEEoIIBQASCATwwggE4AgEBBgorBgEE
# AYRZCgMBMDEwDQYJYIZIAWUDBAIBBQAEICISIqcj702NQ6hP2BoS2ne/V3dt7yjK
# 3675wwHudRhkAgZlzf7wSLQYEjIwMjQwMjE2MDkwMDUyLjkzWjAEgAIB9KCB0aSB
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
# MQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJBDEiBCBkMB9baCJlCfILqDcq7IXL
# 81n9BxVpE31vfswwQ59HVDCB+gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0EIOU2
# XQ12aob9DeDFXM9UFHeEX74Fv0ABvQMG7qC51nOtMIGYMIGApH4wfDELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAHnLo8vkwtPG+kAAQAAAecwIgQgbSti
# cu2IQX7RV4aVKkhTLeEHcnBUQtthlx7T9gCQju4wDQYJKoZIhvcNAQELBQAEggIA
# Sf8NnxXEhH+bOc3yZ0lZuwQeZ4Smx9f6m5E09ucquvPeRS9m/rfxmvcSohTebLAW
# vLbg6PmdC+ThQ8e7WQkNKljiq428cVtvV+PGJQ0FvOtp5hwINu2yjOSzhw4fO5Dt
# hyUOY+iK5feQ+nHhHWkTobp35YPMEzFpnot3qPU1nC6a2961DdhakKaXR3bF3mxi
# 3aukfUHjTa1aUVwmGkIz+moYutVO0FQU0D+oASLMZRKv6O+JAs/YyNzAXky+2d1x
# XSrr7PmDqd0aKqDrBXDQA/ADD0/2CDahNX49eMN1mwNHIvSKJ0IaMEvmeOKjYzAV
# VCpDHE1u8XAApfLuB5bgvcxlyfshVctFnw7N/DMVq1N06ZG6ImuaN5V//wyeB5Lb
# tnJGfFJrgkhX+zlaQRTHlw4PfAnypdR8P7dRzyWlgN2dlWRPE6sTVCXlPnmpyE5q
# qPewpuojjrAsY0gL3XBLf3t3YDCmXAtajV4OhwW/4+CdpqMGQ9bPvqLBq7pdp3Dc
# vfN0qx+BqOq5loQ4duSug7J1mit8a204gwZ7N9kHFJIyXSTXtGBO5S4Uow3qp+xi
# B3FhviJGWeIJj/mnK0VyyVDy9b/vYqOcjORkJ9yuvgi7CW2sRJMf1IJp234inBGh
# bALtbra75V+vgiIf+Uu7gPvKCCi4whT1oOxWtOVO4uM=
# SIG # End signature block
