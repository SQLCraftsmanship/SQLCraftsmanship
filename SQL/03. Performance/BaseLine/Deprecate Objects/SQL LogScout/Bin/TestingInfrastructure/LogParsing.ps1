$LoggingFacilityModule = Get-Module -Name LoggingFacility | select-object Name

if ($LoggingFacilityModule.Name -ne "LoggingFacility")
{
    Import-Module -Name ..\LoggingFacility.psm1
}

function Search-Log {
<#
    .SYNOPSIS
        Open each log matching filename pattern and look for each string pattern in it.
    .DESCRIPTION
        Open each log matching filename pattern and look for each string pattern in it.
        Writes directly into summary file and detailed file.
    .EXAMPLE
        
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$LogNamePattern = "..\output\internal\##SQLLOGSCOUT_DEBUG.LOG",

    [Parameter()]
    $MessagePatterns = @(
        "\tERROR\t", 
        "Msg\s\d{1,5},\sLevel\s\d{1,3},\sState\s\d{1,2},\s.*Line\s\d+"
        ),

    [Parameter()]
    [string]$SummaryFilename = ".\output\SUMMARY.TXT",

    [Parameter()]
    [string]$DetailedFilename = ".\output\SearchForErrors_Detailed.TXT"
    )

    try {

        $return_val = $true

        #clear contents of the detailed file
        if (Test-Path $DetailedFilename)
        {
            Clear-Content -Path $DetailedFilename
        }

        #search the debug log for errors
        $AllMatches = Select-String -Path $LogNamePattern -Pattern $MessagePatterns

        [System.Text.StringBuilder]$detailedOutput = New-Object -TypeName System.Text.StringBuilder
        [string]$Path = ""

        foreach($Match in $AllMatches){

            #if the Match is for a different filename then print header
            if($Path -ne $Match.Path){
                
                $Path = $Match.Path

                [void]$detailedOutput.AppendLine("")
                [void]$detailedOutput.AppendLine("********************************************************************")
                [void]$detailedOutput.AppendLine(" Found errors in file: $Path")
                [void]$detailedOutput.AppendLine("********************************************************************")
            }
            
            [void]$detailedOutput.AppendLine($Match.LineNumber.ToString() + ": " + $Match.Line)
        }

        #write to the detailed output to file if there is any error found
        if (-not([string]::IsNullOrWhiteSpace($detailedOutput.ToString()))){
            $detailedOutput.ToString() | Out-File $DetailedFilename -Append
        }

        #write summary to file
        $SummaryMsg = "Total Error Pattern Match: " + $AllMatches.Matches.Count.ToString()

        if(0 -eq $AllMatches.Matches.Count)
        {
            $SummaryMsg = ($SummaryMsg + " "*(60 - $SummaryMsg.Length) + "SUCCESS")
        } 
        else 
        {
            # build the full path to the detailed file
            $cwd = (Get-location).Path 
            $detailedFileFullPath = (Join-Path $cwd $DetailedFilename) | Resolve-Path
            
            $SummaryMsg = ($SummaryMsg + " "*(60 - $SummaryMsg.Length) + "ERRORS FOUND! (See '$detailedFileFullPath' for more details)")
            $return_val = $false
        }
        
        Write-Output ($SummaryMsg) | Out-File $SummaryFilename -Append



        if ($return_val -eq $false)
        {
            
            Write-Host "Printing detailed Search-Log test output '$detailedFileFullPath)':`n"
            Get-Content -Path $DetailedFilename | Out-Host
        }
        return $return_val
    }
    catch {
        
        $error_msg = $PSItem.Exception.Message
        $error_linenum = $PSItem.InvocationInfo.ScriptLineNumber
        $error_offset = $PSItem.InvocationInfo.OffsetInLine
        $error_script = $PSItem.InvocationInfo.ScriptName
        Write-LogError "Function '$($MyInvocation.MyCommand)' failed with error:  $error_msg (line: $error_linenum, offset: $error_offset, file: $error_script)"    
        $return_val = $false
    }
}

# SIG # Begin signature block
# MIIoOwYJKoZIhvcNAQcCoIIoLDCCKCgCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBfqBWXxls5gxTW
# KxejIa4qkfyhtAKCQy6zbaPV1Yf/EKCCDYUwggYDMIID66ADAgECAhMzAAADri01
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
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIP4G
# zhOnBhD+7hYQBQkVlk9aoIEmywGMDoy6bP/IMB8iMEQGCisGAQQBgjcCAQwxNjA0
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEcgBpodHRwczovL3d3d3cubWljcm9zb2Z0
# LmNvbTANBgkqhkiG9w0BAQEFAASCAQArZR3nJz8S1bDxz/WYkf9cHWDPsN68/+Ol
# nzH6L5jgdherHVT4UcYYQ0PEtnDe1ZQsIn3N51+8JwTXq3IxXfnWgu/l7m/mAUOo
# 3AHioBkK1DuT7QjO6GBbZu1+7llXO5PIdGtTs6igO2RoSN0ixINdfmSU9EP47qUH
# OKcF0YB8YnfERgoAzt9xnyyC5/8OsCUCSBcv+RKHkDiNY5BPrRGVYnRJfXysKiSx
# jjOVoBi6YBttEVaRI0T9fk/mBU67Y4PwkwK5d6TqQLCPDYe464gmcKxv42wTu2Z1
# lniXasqNDxcXo3ZQoQVrnOrDiYGpl+efTFE3LLWbPTCMViC5A6WBoYIXlDCCF5AG
# CisGAQQBgjcDAwExgheAMIIXfAYJKoZIhvcNAQcCoIIXbTCCF2kCAQMxDzANBglg
# hkgBZQMEAgEFADCCAVIGCyqGSIb3DQEJEAEEoIIBQQSCAT0wggE5AgEBBgorBgEE
# AYRZCgMBMDEwDQYJYIZIAWUDBAIBBQAEICzLs2Iq5fruxFbLnbuuEZfVwmuFlDf8
# xyU4+P84yFJkAgZlzg2aGDQYEzIwMjQwMjE2MDkwMDQ1LjUxNFowBIACAfSggdGk
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
# DQYLKoZIhvcNAQkQAQQwLwYJKoZIhvcNAQkEMSIEIE79RGXk0dJ/U+BDzQQvEofG
# ysALQNO6xaMpe9HQl10hMIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCBvQQgGLzZ
# NIu24bhWSnzAGYmT9P5ECHzjWwb9oM7DGDo7YugwgZgwgYCkfjB8MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQg
# VGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAfPFCkOuA8wdMQABAAAB8zAiBCARq/Me
# 8/FJQF1AP51SMEUGiGSNELHyZG+ViO5Icrc5KzANBgkqhkiG9w0BAQsFAASCAgCa
# HMXwsmp6jufXy1c3DNh7iXyH6bWqN2eI7L0QNMFdxFbTa0WCEBRytrHPFpUOMtYK
# AI/PpxweH7VUizh7iXGElEslpVtJkUWu9Ve2ocojGfWnR+JUiV75CySz/L9MULDc
# kzXN6BzX1OBeN9jiXUW7jnN7SDYt4XIlyD8ZtBHT6CWbfIbuYIU4gBa+FmShHw4D
# 73i8q0C0bAweXW5zz0x91nKFiMUsfSC8BW+RmJEN2K1tmj7ww5QZEoexIu8O6i/0
# i6jBHn08PYGz6xd1x6nhzOms+WePDndDpt5gVslxah6/+i522Ndn8m6zNgob/WNM
# TupOk5m6CMKZl4mrTdDCgW32Amvr/SMX4IvY8J42vAFx+dkmk6Q9Ws6OLOKbUgQo
# wzrLZBWsrxUWV/nLFulF5iMLuBnIdeL5MK3ONxM4a5rMIkUiD9NyvJAL6OJc4y5+
# fToin5Wm9B3dfLpOP1JV6nLEQesvRhHkLoNdKQH9LgTjp1F1fNh4OAP8NXGStKzy
# C6KDgIa8z6tXBoO5xXVgu7AQYNbcT+iuMvAo3rZT/B2MjV/U43FJPMLh+VZ7R345
# OA34JGHVTUy2IraJC5FyS1pzkA4PDZM5HENE94+DRZKCGpMpeFYAiWXVlhwVQy+x
# BwdvG80W6RZV9PLaEghNGmAE2P1OdJnMDYKrR3T5Ow==
# SIG # End signature block
