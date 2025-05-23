param
(
    #servername\instnacename is an optional parameter
    [Parameter(Position=0)]
    [string] $ServerName = $env:COMPUTERNAME,
    
    [Parameter(Position=1,Mandatory=$true)]
    [string] $Scenarios = "WRONG_SCENARIO",

    [Parameter(Position=2,Mandatory=$true)]
    [string] $OutputFilename,

    [Parameter(Position=3)]
    [string] $SqlNexusPath,

    [Parameter(Position=4)]
    [string] $SqlNexusDb,

    [Parameter(Position=5)]
    [string] $LogScoutOutputFolder,

    [Parameter(Position=6, Mandatory=$true)]
    [string] $SQLLogScoutRootFolder
)


function GetExclusionsInclusions ([string]$Scenario)
{
    [string] $RetExclusion = ""

    switch ($Scenario) 
    {
        # if there are exceptions for more scenarios in the future, use these
        "Basic" {}
        "Replication" 
        {
            if ($false -eq (CheckLogsForString  -TextToFind "Collecting Replication Metadata"))
            {
                $RetExclusion = "ReplMetaData"
            }
        }
        "AlwaysOn"
        {
            if ($true -eq (CheckLogsForString -TextToFind "HADR is off, skipping data movement and AG Topology" ))
            {
                $RetExclusion = "NoAlwaysOn"
            }
        }
        "NeverEndingQuery"
        {
            if ($true -eq (CheckLogsForString -TextToFind "NeverEndingQuery Exit without collection"))
            {
                $RetExclusion = "NoNeverEndingQuery"

            }
        }
    }

    return $RetExclusion
}

function CheckLogsForString()
{
    param
    (
        [Parameter(Position=0, Mandatory=$true)]
        [string] $TextToFind
    )

    #Search the default log first as there less records than debug log.
    if (Select-String -Path $global:SQLLogScoutLog -Pattern $TextToFind)
    {
        return $true
    }
    #If we didn't find in default log, then check debug log for the provided string.
    elseif (Select-String -Path $global:SQLLogScoutDebugLog -Pattern $TextToFind)
    {
        return $true
    }
    #We didn't find the provided text 
    else
    {
        Write-Output "No ##SQLLogScout logs contains the string provided" | Out-File $global:ReportFileSQLNexus -Append
    }
    
    return $false
}


try 
{
    $return_val = $true
    $testingFolder = $SQLLogScoutRootFolder + "\Bin\TestingInfrastructure\"
    $global:ReportFileSQLNexus = $testingFolder + "output\" + (Get-Date).ToString('yyyyMMddhhmmss') + '_'+ $Scenarios +'_SQLNexusOutput.txt'
    $out_string = "SQLNexus '$Scenarios' scenario test:"
    $global:SQLLogScoutLog = $LogScoutOutputFolder + "\internal\##SQLLOGSCOUT.LOG"
    $global:SQLLogScoutDebugLog = $LogScoutOutputFolder + "\internal\##SQLLOGSCOUT_DEBUG.LOG"


    #if SQLNexus.exe path is provided we run the test
    if ($SqlNexusPath -ne "")
    {
        #check if multiple scenarios are provided and exit if so
        if ($Scenarios.Split("+").Count -gt 1)
        {
            $out_string = ($out_string + " "*(60 - $out_string.Length) + "FAILED!!! SQLNexus_Test does not support multiple scenarios (only single scenario).")
            Write-Output $out_string | Out-File $OutputFilename -Append
            return $false
        }

        $sqlnexus_imp_msg =  "Importing logs in SQL database '$SqlNexusDb' using SQLNexus.exe"
        Write-Host $sqlnexus_imp_msg

        Write-Host "SQL LogScout assumes you have already downloaded SQLNexus.exe. If not, please download it here -> https://github.com/Microsoft/SqlNexus/releases "

        $executable = ($SqlNexusPath + "\sqlnexus.exe")
        
        if (Test-Path -Path ($executable))
        {
            $sqlnexus_version = (Get-Item $executable).VersionInfo.ProductVersion
            $sqlnexus_found = "SQLNexus.exe v$sqlnexus_version found. Executing test..."
            Write-Host $sqlnexus_found


            #launch SQLNexus  and wait for it to finish processing -Wait before continuing
            $argument_list = "/S" + '"'+ $ServerName +'"' + " /D" + '"'+ $SqlNexusDb +'"'  + " /E" + " /I" + '"'+ $LogScoutOutputFolder +'"' + " /Q /N"
            Start-Process -FilePath $executable -ArgumentList $argument_list -WindowStyle Hidden -Wait

            
            # check the tables in SQL Nexus-created database and report if some were not imported
            $sqlnexus_scripts = $testingFolder + "sqlnexus_tablecheck_proc.sql" 


            #create the stored procedure
            $executable  = "sqlcmd.exe"
            $argument_list = "-S" + '"'+ $ServerName +'"' + " -d" + '"'+ $SqlNexusDb +'"'  + " -E -Hsqllogscout_sqlnexustest -w8000" + " -i" + '"'+ $sqlnexus_scripts +'"' 
            Start-Process -FilePath $executable -ArgumentList $argument_list -WindowStyle Hidden -Wait

            # check for any exception/exclusion situations
            $ExclusionTag = GetExclusionsInclusions -Scenario $Scenarios

            #execute the stored procedure
            $sqlnexus_query = "exec tempdb.dbo.proc_SqlNexusTableValidation '" + $Scenarios + "', '" + $SqlNexusDb + "', '" +  $ExclusionTag + "'"
            $argument_list2 = "-S" + '"'+ $ServerName +'"' + " -d" + '"'+ $SqlNexusDb +'"'  + " -E -Hsqllogscout_sqlnexustest -w8000" + " -Q" + '"EXIT('+ $sqlnexus_query +')"' + " -o" + '"'+ $global:ReportFileSQLNexus +'"' 
            $proc = Start-Process -FilePath $executable -ArgumentList $argument_list2 -WindowStyle Hidden -Wait -PassThru 

            if ($proc)
            {
                

                if($proc.ExitCode -eq 2002002)
                {
                    #there are tables that are not present. report in summary file
                    $out_string = ($out_string + " "*(60 - $out_string.Length) + "FAILED!!! (Found missing tables; see '$global:ReportFileSQLNexus')")
                    $return_val = $false
                }
                elseif ($proc.ExitCode -eq 1001001)
                {
                    $out_string = ($out_string + " "*(60 - $out_string.Length) + "SUCCESS ")
                    
                }
                else
                {
                    $out_string = ($out_string + " "*(60 - $out_string.Length) + "FAILED!!! Query/script failure of some kind. Exit code = '$($proc.ExitCode)' ")
                    $return_val = $false
                }

                Write-Output $out_string | Out-File $OutputFilename -Append
            }

            #clean up stored procedure

            $sqlnexus_query = 'DROP PROCEDURE dbo.proc_SqlNexusTableValidation ' 
            $executable  = "sqlcmd.exe"
            $argument_list3 = "-S" + '"'+ $ServerName +'"' + " -d" + '"tempdb"'  + " -E -Hsqllogscout_cleanup -w8000" + " -Q" + '"'+ $sqlnexus_query +'"'  
            Start-Process -FilePath $executable -ArgumentList $argument_list3 -WindowStyle Hidden 

        }
        else
        {
            $missing_sqlnexus_err = "The SQLNexus directory '$SqlNexusPath' is invalid or SQLNexus.exe is not present in it." 

            #write to detailed file
            Write-Host $missing_sqlnexus_err -ForegroundColor Red
            Write-Output $missing_sqlnexus_err | Out-File $global:ReportFileSQLNexus -Append

            # write out to the summary file
            $out_string = ($out_string + " "*(60 - $out_string.Length) + "FAILED!!! SQLNexus.exe not found. See '$global:ReportFileSQLNexus'")
            Write-Output $out_string | Out-File $OutputFilename -Append
            $return_val = $false
        }

        #append several message to the datetime_scenario_SQLNexusOutput.txt file
        $storedproc_results = Get-Content -Path  $global:ReportFileSQLNexus
        Set-Content -Path  $global:ReportFileSQLNexus -Value $sqlnexus_imp_msg
        Add-Content -Path  $global:ReportFileSQLNexus -Value $sqlnexus_found
        Add-Content -Path  $global:ReportFileSQLNexus -Value ""
        Add-Content -Path $global:ReportFileSQLNexus -Value $storedproc_results
    }

    # if some error occurred, print the report file to the console (for debugging purposes)
    if ($return_val -eq $false)
    {   Write-Host "Printing detailed SQLNexus test output '$global:ReportFileSQLNexus':`n"
        Get-Content -Path $global:ReportFileSQLNexus | Out-Host
    }

    return $return_val

}
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

# SIG # Begin signature block
# MIIoPQYJKoZIhvcNAQcCoIIoLjCCKCoCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB6SFbMQ/j86sjM
# uoWzxAZKR6AmUWX+319uQvrFgPxQSaCCDYUwggYDMIID66ADAgECAhMzAAADri01
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
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIH2F
# ZukrwCexjlyPblqT/Wv24x5EmAGbi6Lt2dycHDt9MEQGCisGAQQBgjcCAQwxNjA0
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEcgBpodHRwczovL3d3d3cubWljcm9zb2Z0
# LmNvbTANBgkqhkiG9w0BAQEFAASCAQAJZLEumnj/f7kXDCD/jrtu0BbBJJLtqvsE
# bDhQ+TI+w5bSPXWwqZQ3ZsWKTmazdjeFyHoasGZTp0qqm1ofa4UGZsZwm3rLeX4S
# nX9iNXIqIA3Ias5MO4sTrqL6K6uVqWmgxL7B4fsMjpEzvObntBlKgS2nPfLhfk/U
# P0BcLw9hM+VvNR1dfKaZ2iqvX3acTv5/gxq0evZBYaC14HB/kflJQos9zzwUhSEH
# IUBVgIlMUFs1Tmcei2l27dLStyCe27t+PbY0YNS/ybPgL5YcH0l7et2w5MIRqOZy
# FCrgcRrqSjr0X5Xir5GACpHLqNK7lEH+tGhVCegZD6+pS7L1qWusoYIXljCCF5IG
# CisGAQQBgjcDAwExgheCMIIXfgYJKoZIhvcNAQcCoIIXbzCCF2sCAQMxDzANBglg
# hkgBZQMEAgEFADCCAVIGCyqGSIb3DQEJEAEEoIIBQQSCAT0wggE5AgEBBgorBgEE
# AYRZCgMBMDEwDQYJYIZIAWUDBAIBBQAEILaWIqt5O8GQWUGeNSTzjPTQkvJQUmEY
# z8J2I/FuCHiEAgZlzf7wTBoYEzIwMjQwMjE2MDkwMTAzLjE2N1owBIACAfSggdGk
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
# AzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQgdJPCWY33m8zpzJqQxREt
# T6ufavt7z959XwxoVQBb1/EwgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCDl
# Nl0NdmqG/Q3gxVzPVBR3hF++Bb9AAb0DBu6gudZzrTCBmDCBgKR+MHwxCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
# HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29m
# dCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB5y6PL5MLTxvpAAEAAAHnMCIEIG0r
# YnLtiEF+0VeGlSpIUy3hB3JwVELbYZce0/YAkI7uMA0GCSqGSIb3DQEBCwUABIIC
# AHzlHENYfhBWRiUmReMu1Tcu9Lqn8ql6l8Xa7ZBzaAZwAu/JhiEU6WQuDgmHc4CJ
# 9m/w1RIOaXe52qobhQT6MF4x/Ief4OQj8Z+1+/kvaottl2uSBgf/8MtssutbrmO1
# vXsS74oMT4VM0V6ksdFtW3p6FCWoHu1/QokgZrNH7INd3gmQk4qi+YvnLxUQKYnT
# kHTpi+xZ4sKghchcaDBJsWC0/te8C5FqThCQoXllFUSRH6XMC8yf3Wz4cudK5ZtI
# vWryvrRFmMaP57iNWHmjrXN6z87O1YUxOpQ54OYApt9kDf0y5/vgQ0L5DBKePBn1
# 1nzGBBwz006bzkZvMXbEGZCAZCeYRtlHOx8/vF1ADB69/6P6TxUutX+3brMQ3zfu
# nFQ0rhqa7/TFng+zZW/orKhglVK8m6XmZ6UCU5za1q136jEQrTjNpAY3jZGi3d8+
# ca+7nHAeGEVqxPkG6+aTNYVfFXWYEMc19sveyN2DRjTF1PxXiSuYZMP/9zdC5QRl
# /kcg9ZbbqBHVO/hRMRk5Yu386rS9nQxUWGX3rAXnS/250K5eyifaEnmUbFF1vdVr
# cTlIaqbiU6LMRIx2+Ct/CeSpTDJukLcCga/5WjCrY325bYRcsYTcvvHiyROZQj/z
# B5JNWENckWq/P0jjFl6hkP0qIU7LfWMPv/U9KLRaC6Jz
# SIG # End signature block
