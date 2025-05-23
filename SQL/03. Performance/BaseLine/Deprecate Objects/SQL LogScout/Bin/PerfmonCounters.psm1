
#======================================== START OF PERFMON COUNTER FILES SECTION




function Get-PerfmonString ([string]$NetNamePlusInstance)
{
    Write-LogDebug "inside" $MyInvocation.MyCommand

    try 
    {

        #if default instance, this function will return the hostname
        $host_name = $global:host_name

        $instance_name = Get-InstanceNameOnly($NetNamePlusInstance)

        #if default instance use "SQLServer", else "MSSQL$InstanceName
        # on a cluster $NetNamePlusInstance would contain the VNN when a default instance 
        if (($instance_name -eq $host_name) -or ($instance_name -eq $NetNamePlusInstance))
        {
            $perfmon_str = "SQLServer"
        }
        else
        {
            $perfmon_str = "MSSQL$"+$instance_name

        }

        Write-LogDebug "Perfmon string is: $perfmon_str" -DebugLogLevel 2

        return $perfmon_str

    }
    catch 
    {
        
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
    }
}


function Update-PerfmonConfigFile([string]$NetNamePlusInstance)
{
    Write-LogDebug "inside" $MyInvocation.MyCommand

    try
    {
        #fetch the location of the copied counter file in the \internal folder. Could write a function in the future if done more than once
        $internal_directory = $global:internal_output_folder
        $perfmonCounterFile = $internal_directory+$global:perfmon_active_counter_file

        Write-LogDebug "New Perfmon counter file location is: " $perfmonCounterFile

        $original_string = 'MSSQL$*:'
        $new_string = Get-PerfmonString ($NetNamePlusInstance) 
        $new_string += ":"
        
        Write-LogDebug "Replacement string is: " $new_string -DebugLogLevel 2

        if (Test-Path -Path $perfmonCounterFile)
        {
            #This does the magic. Loads the file in memory, and replaces the original string with the new built string
            ((Get-Content -path $perfmonCounterFile -Raw ) -replace  [regex]::Escape($original_string), $new_string) | Set-Content -Path $perfmonCounterFile 
        }
        else 
        {
            Write-LogError "The file $perfmonCounterFile does not exist."
        }
    }
    catch 
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
    }
}

function Copy-OriginalLogmanConfig()
{
    #this function makes a copy of the original Perfmon counters LogmanConfig.txt file in the \output\internal directory
    #the file will be used from there
    

    Write-LogDebug "inside" $MyInvocation.MyCommand
    
    $internal_path = $global:internal_output_folder
    $present_directory = $global:present_directory
    $perfmon_file = $global:perfmon_active_counter_file

    $perfmonCounterFile = $present_directory+"\"+$perfmon_file     #"LogmanConfig.txt"
    $destinationPerfmonCounterFile = $internal_path + $perfmon_file   #\output\internal\LogmanConfig.txt
    

    try
    {
        if(Test-Path -Path $internal_path)
        {
            #copy the file to internal path so it can be used from there
            if ($global:gui_mode) 
            {
                [System.Text.StringBuilder]$SB_PerfmonCounter = New-Object -TypeName System.Text.StringBuilder
                foreach($item in $Global:list)
                {
                    if ($item.State -eq $true)
                    { 
                        [void]$SB_PerfmonCounter.Append($item.Value + "`r`n")
                    }
                }
                Add-Content $destinationPerfmonCounterFile $SB_PerfmonCounter
            }
            else
            {
                Copy-Item -Path $perfmonCounterFile -Destination $destinationPerfmonCounterFile -ErrorAction Stop
            }
            Write-LogInformation "$perfmon_file copied to " $destinationPerfmonCounterFile
           
            #file has been copied
            return $true
        }
        else 
        {
            $mycommand = $MyInvocation.MyCommand
            $error_msg = $PSItem.Exception.Message 
            
            $error_linenum = $PSItem.InvocationInfo.ScriptLineNumber
            $error_offset = $PSItem.InvocationInfo.OffsetInLine
            Write-LogError "Function $mycommand failed with error:  $error_msg (line: $error_linenum, $error_offset)"

            #Write-LogError "The file $perfmonCounterFile is not present."
            return $false
        }
        
        
    }

    catch
    {
        $error_msg = $PSItem.Exception.Message 

        if ($error_msg -Match "because it does not exist")
        {
            Write-LogError "The $perfmon_file file does not exist."
        }
        else
        {
            Write-LogError "Copy-Item  cmdlet failed with the following error: " $error_msg 
        }

        return $false
    }
}

function PrepareCountersFile()
{
    Write-LogDebug "Inside" $MyInvocation.MyCommand

    try 
    {
        
        #if we are not calling a Perfmon scenario, return and don't proceed
        if ($global:perfmon_scenario_enabled -eq $false)
        {
            Write-LogWarning "No Perfmon-collection scenario is selected. Perfmon counters file will not be created"
            return
        }

        if (($global:sql_instance_conn_str -ne "") -and ($null -ne $global:sql_instance_conn_str) )
        {
            [string] $SQLServerName = $global:sql_instance_conn_str
        }
        else 
        {
            Write-LogError "SQL instance name is empty.Exiting..."    
            exit
        }

        if (Copy-OriginalLogmanConfig)
        {
            Write-LogDebug "Perfmon Counters file was copied. It is safe to update it in new location" -DebugLogLevel 2
            Update-PerfmonConfigFile($SQLServerName)
        }
        #restoration of original file is in the Stop-DiagCollectors
    }
    catch {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
    }
}


#======================================== END OF PERFMON COUNTER FILES SECTION
# SIG # Begin signature block
# MIIoOwYJKoZIhvcNAQcCoIIoLDCCKCgCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDdZiF8AKMuPvk/
# xvwBfiGMF98bElAvuY/D3USCYgAk+6CCDYUwggYDMIID66ADAgECAhMzAAADri01
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
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCGgwwghoIAgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAOuLTVRyFOPVR0AAAAA
# A64wDQYJYIZIAWUDBAIBBQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILmT
# 6rSJW1gAcIYn9zGsL6WWQ3mphXwciWk7obg/uJreMEQGCisGAQQBgjcCAQwxNjA0
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEcgBpodHRwczovL3d3d3cubWljcm9zb2Z0
# LmNvbTANBgkqhkiG9w0BAQEFAASCAQDvz5cHYSY3sBJyCeDpzkAWWGIqY6rm0v4z
# u5kEnpYIRb7b+3/Nq57qbhX2043C1q/M4daXzMbaTBDdeg1b+YA1nrODB4BkS3U8
# Uf7TvBHsWzigSrOjzXeK3xL5l2Phz0olEl9HNmzCtV/zp56TFXpZja0lFxZ0x6X2
# f/IWar0uiJwj9Ta877dAN70bdO0UYk3jOWRsTpgbcj8E8XdA8xWez3wSJzS7eAN0
# 1tzRfXaqIadnkoeGgRudkdf9cYYfhPlA/RyhEFB1iNpL8E392HqXby8m2UmplL51
# MfQpHCpRVbyf8I9FqCrAAT0Wep5TpctHllsOA0gkA/9EtmQ+xkaloYIXlDCCF5AG
# CisGAQQBgjcDAwExgheAMIIXfAYJKoZIhvcNAQcCoIIXbTCCF2kCAQMxDzANBglg
# hkgBZQMEAgEFADCCAVIGCyqGSIb3DQEJEAEEoIIBQQSCAT0wggE5AgEBBgorBgEE
# AYRZCgMBMDEwDQYJYIZIAWUDBAIBBQAEIPGMX717za28Yfx3TzoEui9sBo7KdhSl
# 1r1+7KkZ4tL0AgZlzg2aGPEYEzIwMjQwMjE2MDkwMDQ4LjUxNlowBIACAfSggdGk
# gc4wgcsxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNV
# BAsTHE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGll
# bGQgVFNTIEVTTjo4RDAwLTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRp
# bWUtU3RhbXAgU2VydmljZaCCEeowggcgMIIFCKADAgECAhMzAAAB88UKQ64DzB0x
# AAEAAAHzMA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
# YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAy
# MDEwMB4XDTIzMTIwNjE4NDYwMloXDTI1MDMwNTE4NDYwMlowgcsxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBB
# bWVyaWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjo4RDAw
# LTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vydmlj
# ZTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAP6fptrhK4H2JI7lYyFu
# eCpgBv7Pch/M2lkhZL+yB9eGUtiYaexS2sZfc5VyD7ySsl2LG41Qw7tkA6oJmxdS
# M7PzNyfVpQPkPavY+HNUqMe2K9YaAaPjHnCpZ7VCi/e8zPxYewqx9p0iVaN8EydU
# pWiY7JtDv7aNzhp/OPZclBBKYT2NBGgGiAPCaplqR5icjHQSY665w+vrvhPr9hpM
# +IhiUZ/5dXa7qhAcCQwbnrFg9CKSK1COM1YcAN8GpsERqqmlqy3GlE1ziJ3ZLXFV
# DFxAZeOcCB55Vts9sCgQuFvD7PdV61HC4QUlHNPqFtYSC/P0sxg9JuKgcvzD5mJa
# jfG7DdHt8myp7umqyePC+eI/ux8TW61+LuTQ1Bkym+I6z//bf0fp4Dog5W0XzDrq
# KkTvURitxI2s4aVObm6qr6zI7W51k54ozTFjvbw1wYMWqeO4U9sQSbr561kp+1T2
# PEsJLOpc5U7N2oDw7ldrcTjWPezsyVMXhDsFitCZunGqFO9+4iVjAjYDN47c6K9x
# 7MnAGPYVCBOJUdpy8xAOBIDsTm/K1qTT4wsGbQBxbgg96vwDiA4YP2hKmubIC7Un
# rAWQGt/ZKOf6J42roXHS1aPwimDe5C9y6DfuNJp0XqrWtQRqg8hqNkIZWT6jnCfq
# u35zB0nf1ERTjdpYLCfQL5fHAgMBAAGjggFJMIIBRTAdBgNVHQ4EFgQUw2QV9qUR
# UQyMDcCmhTH2oOsNCiQwHwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIw
# XwYDVR0fBFgwVjBUoFKgUIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9w
# cy9jcmwvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3Js
# MGwGCCsGAQUFBwEBBGAwXjBcBggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3Nv
# ZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENB
# JTIwMjAxMCgxKS5jcnQwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEF
# BQcDCDAOBgNVHQ8BAf8EBAMCB4AwDQYJKoZIhvcNAQELBQADggIBAN/EHI/80f7v
# 29zeWI7hzudcz9QoVwCbnDrUXFHE/EJdFeWI2NnuwOo0/QPNRMFT21LkOqSpFKIh
# XXmPurx7p6WDz9wPdu/Sxbgaj0AwviWEDkwGDfDMp2KF8nQT8cipwdfXWbC1ulOI
# LayABSHv45mdv1PAkTulsQE8lBTHG4KJLn+vSzZBWKkGaL/wwRbZ4iLiYn68cjkM
# JoAaihPgDXn/ug2P3PLNEAFNQgI02tLX0p+vIQ3l2HmSo4bhCBxr3DovsIv5K65N
# mLRJnxmrrmIraFDwgwA5XF7AKkPiVkvo0OxU1LAE1c5SWzE4A7cbTA1P5wG6D8cP
# jcHsTah1V+zofYRgJnFRLWuBF4Z3a6pDGBDbCsy5NvnKQ76p37ieFp//1I3eB62i
# a1CfkjOF8KStpPUqdkXxMjfJ7Vnemd6vQKf+nXkfvA3AOQECJn7aLP01QR5gt8wa
# b28SsNUENEyMawT8eqpjtBNJO0O9Tv7NnBE8aOJhhQVdP5WCR90eIWkrDjZeybQx
# 8vlo5rfUXIIzXv+k9MgpNGIqwMXfvRLAjBkCNXOIP/1CEQUG72miMVQs5m/O4vmJ
# IQkhyqilUDB1s12uhmLYc3yd8OPMlrwIxORB5J9CxCkqvzc6EGYTcwXazPyCp7eW
# hzTkNbwk29nfbwmmzcskIAu3StA8lic7MIIHcTCCBVmgAwIBAgITMwAAABXF52ue
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
# BmoQtB1VM1izoXBm8qGCA00wggI1AgEBMIH5oYHRpIHOMIHLMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1l
# cmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046OEQwMC0w
# NUUwLUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2Wi
# IwoBATAHBgUrDgMCGgMVAG76BizYtGFrmkU7v2DcuR/ApGcooIGDMIGApH4wfDEL
# MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
# bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWlj
# cm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwDQYJKoZIhvcNAQELBQACBQDpeTTG
# MCIYDzIwMjQwMjE2MDExMTM0WhgPMjAyNDAyMTcwMTExMzRaMHQwOgYKKwYBBAGE
# WQoEATEsMCowCgIFAOl5NMYCAQAwBwIBAAICCSAwBwIBAAICE1YwCgIFAOl6hkYC
# AQAwNgYKKwYBBAGEWQoEAjEoMCYwDAYKKwYBBAGEWQoDAqAKMAgCAQACAwehIKEK
# MAgCAQACAwGGoDANBgkqhkiG9w0BAQsFAAOCAQEAZhoWvgA5c4I6o4szyPWG2dac
# 6bfNYLc1B3Zgj1YRrEfMKJX5Gi+8fDP+pW3gPiBtmPKGAFywWAoKsKUcqu8/B6pq
# D1akHegksx78WQXfoWo6N+jgswPHH2pZHHjRmi7WYaoAJrAL6oCP2J+1gN6TeZeG
# NRMA7L/nKnjeffJFbmHnIXtmx2xPPJsXDp4ENwk0UZdmwHo58ssYOglWZNtaj19k
# roZYxbVRe8Od4IsEQk29hNIkk6bt9/4g4r1QF5myMWJpdbwWvY6V9zMpkAJvVSl8
# vxtkobtLT6yyOzVerxYvdo+mqtXGFvA0SvZ62KUxqvVg5soY59MSVF1yUwjp6jGC
# BA0wggQJAgEBMIGTMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9u
# MRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
# b24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB
# 88UKQ64DzB0xAAEAAAHzMA0GCWCGSAFlAwQCAQUAoIIBSjAaBgkqhkiG9w0BCQMx
# DQYLKoZIhvcNAQkQAQQwLwYJKoZIhvcNAQkEMSIEIJoNk+aHESx0+bpxM6Nvva4i
# TX22HLsSqnxbg6OWCi6nMIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCBvQQgGLzZ
# NIu24bhWSnzAGYmT9P5ECHzjWwb9oM7DGDo7YugwgZgwgYCkfjB8MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQg
# VGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAfPFCkOuA8wdMQABAAAB8zAiBCARq/Me
# 8/FJQF1AP51SMEUGiGSNELHyZG+ViO5Icrc5KzANBgkqhkiG9w0BAQsFAASCAgDT
# oSlS9+KcEUcIf0AFtuOXrKztJSYyFreImQHtTrx2UoTdBio7RpQbulPBROxll9/6
# PPI8SizsiY4eSUyymckcbaYeSdoFieL2gPh3tSXFBgZVKVfWwSwdRg0a2fIah2/E
# gyNvHxqboHgCFE/7XWUFAOXn+PunR0q47spvwxn+tDr6PweUJLUeBPbk8mUwvPcZ
# RqekUG2iLzeP4naprfW0DKe6e04Ivx9KUn7FYRz7rCkpJEjaXQExPcResOe5304O
# KiFsdAZfFCdmY3t+yBBX8n1FKjZ5rHyOU/+nUThl03Vswkax0T8XFve8k9r8rakQ
# F/CmK3aE4cBMtrHPKssJPrG6sq3EppvPb3iBO8462+QBxlnT1GfN/0PKOOk+rG0z
# mZMXQjlP3FscLVmXt0JwEAaHQveBXf0GPMhVrzW5FDKyHfgF8iafn+gXYxg7r8s+
# SisUyyXmDBx86/qYYa7c8QQk1lly07mWWBAHNFPWy0w1o0ddyG2+yZGvrffYa9eB
# uL5zQBnV+OdUneTYFOPY4+rgZHIETcH+l4YbpYUFmWETWFT3Fog1J10EVpAUJ++y
# fwYxQYdCTdfwkLaExgwOPGXluQjfeEfWMMjleQj5I8kaSGhsgDXGzas8OvOAansU
# DoR8cL7XiZj6qEXQe6l2WvkK1eGklFzvcRLQDkZ2Uw==
# SIG # End signature block
