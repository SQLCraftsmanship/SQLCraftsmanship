#Importing required modules

Import-Module .\CommonFunctions.psm1

Import-Module .\InstanceDiscovery.psm1

Import-Module .\LoggingFacility.psm1

function HandleCatchBlock ([string] $function_name, [System.Management.Automation.ErrorRecord] $err_rec, [bool]$exit_logscout = $false)
{
    $error_msg = $err_rec.Exception.Message
    $error_linenum = $err_rec.InvocationInfo.ScriptLineNumber
    $error_offset = $err_rec.InvocationInfo.OffsetInLine
    $error_script = $err_rec.InvocationInfo.ScriptName
    Write-LogError "Function '$function_name' failed with error:  $error_msg (line: $error_linenum, offset: $error_offset, file: $error_script)"    

    Write-Host "Exiting CleanupIncomplete Shutdown script ..."
    exit
}


[string] $global:host_name = $env:COMPUTERNAME
[string] $global:sql_instance_conn_str = ""

Write-Host ""
Write-Host "=============================================================================================================================="
Write-Host "This script is designed to clean up SQL LogScout processes that may have been left behind if SQL LogScout was closed incorrectly`n"
Write-Host "=============================================================================================================================="
Write-Host ""

#print out the instance names

Select-SQLServerForDiagnostics

$sql_instance_conn_str = $global:sql_instance_conn_str

$xevent_session = "xevent_SQLLogScout"
$xevent_target_file = "xevent_LogScout_target"
$xevent_alwayson_session = "SQLLogScout_AlwaysOn_Data_Movement"



try 
{
    Write-Host ""
    Write-Host "Launching cleanup routine for instance '$sql_instance_conn_str'... please wait`n"

    #----------------------
    Write-Host "Executing 'WPR-cancel'. It will stop all WPR traces in case any was found running..."
    $executable = "cmd.exe"
    $argument_list = $argument_list = "/C wpr.exe -cancel " 
    Start-Process -FilePath $executable -ArgumentList $argument_list -WindowStyle Hidden
    #-----------------------------
    Write-Host "Executing 'StorportStop'. It will stop stoport tracing if it was found to be running..."
    $argument_list = "/C logman stop ""storport"" -ets"
    $executable = "cmd.exe"
    Start-Process -FilePath $executable -ArgumentList $argument_list -WindowStyle Hidden
    #-------------------------------------

    $query = "
        declare curSession
        CURSOR for select 'kill ' + cast( session_id as varchar(max)) from sys.dm_exec_sessions where host_name = 'sqllogscout' and program_name='SQLCMD' and session_id <> @@spid
        open curSession
        declare @sql varchar(max)
        fetch next from curSession into @sql
        while @@FETCH_STATUS = 0
        begin
            exec (@sql)
            fetch next from curSession into @sql
        end
        close curSession;
        deallocate curSession;
        " 
         
        $executable = "sqlcmd.exe"
        $argument_list ="-S" + $sql_instance_conn_str +  " -E -Hsqllogscout_cleanup -w8000 -Q`""+ $query + "`" "
        Start-Process -FilePath $executable -ArgumentList $argument_list -WindowStyle Hidden

        #stop perf Xevent
        Write-Host "Executing 'Stop_SQLLogScout_Xevent' session. It will stop the SQLLogScout performance Xevent trace in case it was found to be running" "..."
        $query = "IF HAS_PERMS_BY_NAME(NULL, NULL, 'ALTER ANY EVENT SESSION') = 1 BEGIN ALTER EVENT SESSION [$xevent_session] ON SERVER STATE = STOP; DROP EVENT SESSION [$xevent_session] ON SERVER; END" 
        $executable = "sqlcmd.exe"
        $argument_list = "-S" + $server + " -E -w8000 -Q`"" + $query + "`""
        Start-Process -FilePath $executable -ArgumentList $argument_list -WindowStyle Hidden
        
        
        $query = "IF HAS_PERMS_BY_NAME(NULL, NULL, 'ALTER ANY EVENT SESSION') = 1 BEGIN ALTER EVENT SESSION [$xevent_alwayson_session] ON SERVER STATE = STOP; DROP EVENT SESSION [$xevent_alwayson_session] ON SERVER; END" 
        $executable = "sqlcmd.exe"
        $argument_list = "-S" + $server + " -E -w8000 -Q`"" + $query + "`""
        Start-Process -FilePath $executable -ArgumentList $argument_list -WindowStyle Hidden

        
        $xevent_session = "xevent_SQLLogScout"
        $query = "ALTER EVENT SESSION [$xevent_session] ON SERVER STATE = STOP; DROP EVENT SESSION [$xevent_session] ON SERVER;" 
        $executable = "sqlcmd.exe"
        $argument_list ="-S" + $sql_instance_conn_str +  " -E -w8000 -Q`""+ $query + "`" "
        Start-Process -FilePath $executable -ArgumentList $argument_list -WindowStyle Hidden
    
        #stop always on data movement Xevent
        Write-Host "Executing 'Stop_SQLLogScout_AlwaysOn_Data_Movement'. It will stop the SQLLogScout AlwaysOn Xevent trace in case it was found to be running" "..."
        $xevent_session = "SQLLogScout_AlwaysOn_Data_Movement"
        $query = "ALTER EVENT SESSION [$xevent_session] ON SERVER STATE = STOP; DROP EVENT SESSION [$xevent_session] ON SERVER;" 
        $executable = "sqlcmd.exe"
        $argument_list ="-S" + $sql_instance_conn_str +  " -E -w8000 -Q`""+ $query + "`" "
        Start-Process -FilePath $executable -ArgumentList $argument_list -WindowStyle Hidden

        #disable backup/restore trace flags
        $collector_name = "Disable_BackupRestore_Trace_Flags"
        Write-Host "Executing '$collector_name' It will disable the trace flags they were found to be enabled..."
        $query = "DBCC TRACEOFF(3004,3212,3605,-1)" 
        $executable = "sqlcmd.exe"
        $argument_list ="-S" + $sql_instance_conn_str +  " -E -w8000 -Q`""+ $query + "`" "
        Start-Process -FilePath $executable -ArgumentList $argument_list -WindowStyle Hidden

        #stop perfmon collector
        $collector_name = "PerfmonStop"
        Write-Host "Executing '$collector_name'. It will stop Perfmon started by SQL LogScout in case it was found to be running ..."
        $argument_list = "/C logman stop logscoutperfmon & logman delete logscoutperfmon"
        $executable = "cmd.exe"
        Start-Process -FilePath $executable -ArgumentList $argument_list -WindowStyle Hidden

        # stop network traces 
        # stop logman - wait synchronously for it to finish
        $collector_name = "NetworkTraceStop"
        Write-Host "Executing '$collector_name'. It will stop network tracing initiated by SQLLogScout in case it was found to be running..."
        $executable = "logman"
        $argument_list = "stop -n sqllogscoutndiscap -ets"
        Start-Process -FilePath $executable -ArgumentList $argument_list -WindowStyle Hidden -Wait

        # stop netsh  asynchronously but wait for it to finish in a loop
        $executable = "netsh"
        $argument_list = "trace stop"
        $proc = Start-Process -FilePath $executable -ArgumentList $argument_list -WindowStyle Hidden -PassThru

        if ($null -ne $proc)
        {

            [int]$cntr = 0

            while ($false -eq $proc.HasExited) 
            {
                if ($cntr -gt 0) {
                    Write-Host "Shutting down network tracing may take a few minutes. Please do not close this window ..."
                }
                [void] $proc.WaitForExit(10000)

                $cntr++
            }
        }

    Write-Host "Cleanup script execution completed."
        

}
catch 
{
    HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
}



# SIG # Begin signature block
# MIIn0AYJKoZIhvcNAQcCoIInwTCCJ70CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC0qNbH+pIWhX+w
# z6PUO/aKWIzdGaJymONoLqK+erTTF6CCDYUwggYDMIID66ADAgECAhMzAAADri01
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
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEIW
# bVE2s2/0AtT9chSlCto3BSsz3m/yY2gS27SgWvI5MEQGCisGAQQBgjcCAQwxNjA0
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEcgBpodHRwczovL3d3d3cubWljcm9zb2Z0
# LmNvbTANBgkqhkiG9w0BAQEFAASCAQB3P17LzQLgJclf2r9u+d9l01/fI1UA34G7
# zILjNa8gWi4kfFGdV1YQkC57gZ8TMQYzvjK6lz7wlS13iCZ1+EXqWg3fg4CYOgW/
# jj22qFwNiT9bZUIl1zTSx4yY7eVZw5Oo0/YLIwyXtRvUT/9a242rgzp5dH3wHQNx
# 7cKnZp/K5hzS9Gesgy+0DBaONh8aSw0Y7rZcqe9yWgHinoiHbwJJcYDm8BMRjYjn
# M6WY1d3Ie7ozaAIkx619YGjI0GXf6EVOoxrTZtRZ34WM26rdsjDwmoonpwa6hpgw
# GbKYOD+gALAor0dOuXV+ipOzR4vCLdA1zX8T8d6MmY5dDb0LZ+EwoYIXKTCCFyUG
# CisGAQQBgjcDAwExghcVMIIXEQYJKoZIhvcNAQcCoIIXAjCCFv4CAQMxDzANBglg
# hkgBZQMEAgEFADCCAVkGCyqGSIb3DQEJEAEEoIIBSASCAUQwggFAAgEBBgorBgEE
# AYRZCgMBMDEwDQYJYIZIAWUDBAIBBQAEILNPkT8Eoxjfqkx0UtHhAmvTcY0KxAXa
# tfGK1S4h805OAgZluqJZZHwYEzIwMjQwMjE2MDkwMDIyLjI4MVowBIACAfSggdik
# gdUwgdIxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xLTArBgNV
# BAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJhdGlvbnMgTGltaXRlZDEmMCQGA1UE
# CxMdVGhhbGVzIFRTUyBFU046MTc5RS00QkIwLTgyNDYxJTAjBgNVBAMTHE1pY3Jv
# c29mdCBUaW1lLVN0YW1wIFNlcnZpY2WgghF4MIIHJzCCBQ+gAwIBAgITMwAAAeDU
# /B8TFR9+XQABAAAB4DANBgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJVUzETMBEG
# A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFt
# cCBQQ0EgMjAxMDAeFw0yMzEwMTIxOTA3MTlaFw0yNTAxMTAxOTA3MTlaMIHSMQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNy
# b3NvZnQgSXJlbGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsTHVRoYWxl
# cyBUU1MgRVNOOjE3OUUtNEJCMC04MjQ2MSUwIwYDVQQDExxNaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBTZXJ2aWNlMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA
# rIec86HFu9EBOcaNv/p+4GGHdkvOi0DECB0tpn/OREVR15IrPI23e2qiswrsYO9x
# d0qz6ogxRu96eUf7Dneyw9rqtg/vrRm4WsAGt+x6t/SQVrI1dXPBPuNqsk4SOcUw
# Gn7KL67BDZOcm7FzNx4bkUMesgjqwXoXzv2U/rJ1jQEFmRn23f17+y81GJ4DmBSe
# /9hwz9sgxj9BiZ30XQH55sViL48fgCRdqE2QWArzk4hpGsMa+GfE5r/nMYvs6KKL
# v4n39AeR0kaV+dF9tDdBcz/n+6YE4obgmgVjWeJnlFUfk9PT64KPByqFNue9S18r
# 437IHZv2sRm+nZO/hnBjMR30D1Wxgy5mIJJtoUyTvsvBVuSWmfDhodYlcmQRiYm/
# FFtxOETwVDI6hWRK4pzk5Znb5Yz+PnShuUDS0JTncBq69Q5lGhAGHz2ccr6bmk5c
# pd1gwn5x64tgXyHnL9xctAw6aosnPmXswuobBTTMdX4wQ7wvUWjbMQRDiIvgFfxi
# ScpeiccZBpxIJotmi3aTIlVGwVLGfQ+U+8dWnRh2wIzN16LD2MBnsr2zVbGxkYQG
# sr+huKlfq7GMSnJQD2ZtU+WOVvdHgxYjQTbEj80zoXgBzwJ5rHdhYtP5pYJl6qIg
# wvHLJZmD6LUpjxkTMx41MoIQjnAXXDGqvpPX8xCj7y0CAwEAAaOCAUkwggFFMB0G
# A1UdDgQWBBRwXhc/bp1X7xK6ygDVddDZMNKZ0jAfBgNVHSMEGDAWgBSfpxVdAF5i
# XYP05dJlpxtTNRnpcjBfBgNVHR8EWDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jv
# c29mdC5jb20vcGtpb3BzL2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENB
# JTIwMjAxMCgxKS5jcmwwbAYIKwYBBQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRw
# Oi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRp
# bWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNydDAMBgNVHRMBAf8EAjAAMBYGA1Ud
# JQEB/wQMMAoGCCsGAQUFBwMIMA4GA1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsF
# AAOCAgEAwBPODpH8DSV07syobEPVUmOLnJUDWEdvQdzRiO2/taTFDyLB9+W6VflS
# zri0Pf7c1PUmSmFbNoBZ/bAp0DDflHG1AbWI43ccRnRfbed17gqD9Z9vHmsQeRn1
# vMqdH/Y3kDXr7D/WlvAnN19FyclPdwvJrCv+RiMxZ3rc4/QaWrvS5rhZQT8+jmlT
# utBFtYShCjNjbiECo5zC5FyboJvQkF5M4J5EGe0QqCMp6nilFpC3tv2+6xP3tZ4l
# x9pWiyaY+2xmxrCCekiNsFrnm0d+6TS8ORm1sheNTiavl2ez12dqcF0FLY9jc3eE
# h8I8Q6zOq7AcuR+QVn/1vHDz95EmV22i6QejXpp8T8Co/+yaYYmHllHSmaBbpBxf
# 7rWt2LmQMlPMIVqgzJjNRLRIRvKsNn+nYo64oBg2eCWOI6WWVy3S4lXPZqB9zMaO
# OwqLYBLVZpe86GBk2YbDjZIUHWpqWhrwpq7H1DYccsTyB57/muA6fH3NJt9VRzsh
# xE2h2rpHu/5HP4/pcq06DIKpb/6uE+an+fsWrYEZNGRzL/+GZLfanqrKCWvYrg6g
# kMlfEWzqXBzwPzqqVR4aNTKjuFXLlW/ID7LSYacQC4Dzm2w5xQ+XPBYXmy/4Hl/P
# fk5bdfhKmTlKI26WcsVE8zlcKxIeq9xsLxHerCPbDV68+FnEO40wggdxMIIFWaAD
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
# HVRoYWxlcyBUU1MgRVNOOjE3OUUtNEJCMC04MjQ2MSUwIwYDVQQDExxNaWNyb3Nv
# ZnQgVGltZS1TdGFtcCBTZXJ2aWNloiMKAQEwBwYFKw4DAhoDFQBt89HV8FfofFh/
# I/HzNjMlTl8hDKCBgzCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
# aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
# MA0GCSqGSIb3DQEBBQUAAgUA6XmOvDAiGA8yMDI0MDIxNjE1MzUyNFoYDzIwMjQw
# MjE3MTUzNTI0WjB0MDoGCisGAQQBhFkKBAExLDAqMAoCBQDpeY68AgEAMAcCAQAC
# Ahi4MAcCAQACAhI2MAoCBQDpeuA8AgEAMDYGCisGAQQBhFkKBAIxKDAmMAwGCisG
# AQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMBhqAwDQYJKoZIhvcNAQEFBQAD
# gYEAMRAKa+FZyMDs+yOldvZOg10ChnBq5B4U53ufNPgttQ+EJVLds6FN7wvlOO+G
# 658hcYvm6FkZMGXeEwcNa+WvAKt4H5pRNm/WL5XVuH2jpe6vaTh6QIbQ1PnDGQtH
# BODpmvyZ3nnjKkH9sjONM0ZOXmTSiXUMHlAGBJFnzfH0zIoxggQNMIIECQIBATCB
# kzB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQD
# Ex1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAeDU/B8TFR9+XQAB
# AAAB4DANBglghkgBZQMEAgEFAKCCAUowGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJ
# EAEEMC8GCSqGSIb3DQEJBDEiBCCbb5ZLfy7QfVnx435ps3GFZuh6Zs660csqTKQB
# YOCa8jCB+gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0EIOPuUr/yOeVtOM+9zvsM
# IJJvhNkClj2cmbnCGwr/aQrBMIGYMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAg
# UENBIDIwMTACEzMAAAHg1PwfExUffl0AAQAAAeAwIgQgsD1tFn0n89JQYq0aESWT
# jg97iEnB26mR7cYQ5ndR+MAwDQYJKoZIhvcNAQELBQAEggIAasdeuW84pceBVKy7
# T2uFGMyMCEZDch4bUD9ZnIpfeCTjq//k1wLCYwSZ4+0rSHZ9CM9waR9mel4W/mbS
# 2mY3+AXS07qxozhyxaoIVSP+9j7AnelUvwEyd21EHmlAHuHZxgXkQZPP+0bUtbVo
# bsuNUivM7x4HaAI1rcDbvFtWaHeeUelw9afb3x7TxtqrHo3/Q+WUl5uRcmylop1W
# 5Dx2Yt5JKshvyGk0tPRDWIXXbukLYOQBwtaLVsHg4PGfq6Vij/J7Nciszspnuf7O
# bO6ZxLEn6VwpDttfT0dBGPGMEtLdIMX9gibg0HxGhij+P/3vLtbpRGAL0445zdPk
# FDHsWuPUfTfH/JUiI+ZDIu3LPClUo/D9TyTsi2y3k4UKquINNIlZKzDaI5FwDKhm
# UI80t2IJ2UmJICGtaZyshWHtGpf9vD7CHBafjxYOeEV+OGBCrsg7IRWmEG8v2F04
# IoLZ3a+sAjfd5J2IhzsSVb/Ut1ekoftAyAaWjBxHRrutkcf+y+AkInb4maBzhnbw
# TxwcGWh2IQ3QS3LPBeCv4ekc8jbtIm+tekJkTb6GDA08OM2vwYM6RhJd7iy9trrp
# hRiCoM13LrB16BaibvATQm/xMLNp61GrIYyzeCG9oeRFHG6J1RJcDdLNHQ+8ZMuZ
# XzwHcNhNJw/34scmRX7bar+C1os=
# SIG # End signature block
