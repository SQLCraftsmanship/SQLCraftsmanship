## Copyright (c) Microsoft Corporation.
## Licensed under the MIT license.

function Confirm-FileAttributes
{
<#
    .SYNOPSIS
        Checks the file attributes against the expected attributes in $expectedFileAttributes array.
    .DESCRIPTION
        Goal is to make sure that non-Powershell scripts were not inadvertently changed.
        Currently checks for changes to file size and hash.
        Will return $false if any attribute mismatch is found.
    .EXAMPLE
        $ret = Confirm-FileAttributes
#>

    Write-LogDebug "inside" $MyInvocation.MyCommand

    Write-LogInformation "Validating attributes for non-Powershell script files"

    $validAttributes = $true #this will be set to $false if any mismatch is found, then returned to caller

    $pwdir = (Get-Location).Path
    $parentdir = (Get-Item (Get-Location)).Parent.FullName

    $expectedFileAttributes = @(
         [PSCustomObject]@{Algorithm = "SHA512"; Hash = "76DBE5D92A6ADBBAD8D7DCAAC5BD582DF5E87D6B7899882BB0D7489C557352219795106EBD3014BC76E07332FA899CE1B58B273AE5836B34653D4C545BBF89A4"; FileName = $pwdir + "\AlwaysOnDiagScript.sql"; FileSize = 21298}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "4E2E0C0018B1AE4E6402D5D985B71E03E8AECBB9DA3145E63758343AEAC234E3D4988739CCE1AC034DDA7CE77482B27FB5C2A7A4E266E9C283F90593A1B562A2"; FileName = $pwdir + "\ChangeDataCapture.sql"; FileSize = 4672}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "073C0BBAB692A88387AF355A0CEC7A069B7F6C442A8DABF4EFC46E54ACEC7B569B866778A66FE1ADEBF8AD4F30EF3EAF7EF32DD436BC023CD4BC3AD52923AB9F"; FileName = $pwdir + "\Change_Tracking.sql"; FileSize = 5110}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "7E4BF16CD162F767D92AB5EE2FCBC0107DB43068A9EA45C68C2E1DD078C1FA15E9A10CEB63B9D8AEA237F4A2D96E7E5CE34AC30C2CEF304056D9FB287DF67971"; FileName = $pwdir + "\HighCPU_perfstats.sql"; FileSize = 6649}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "D9FA1C31F90188779B00552755059A0E3747F768AA55DEBE702D039D7F942F7C4EA746EE7DE7AC02D0685DDFEED22854EB85B3268594D0A18F1147CA9C20D55A"; FileName = $pwdir + "\High_IO_Perfstats.sql"; FileSize = 9554}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "824A41667D5DAA02729BB469E97701A41A09462EBBEDD2F5851061DC25465DC4422AD52DEDE1B5321FB55D485FDA6DBEE3B6429B303361078ACE3EF0581A8230"; FileName = $pwdir + "\linked_server_config.sql"; FileSize = 1184}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "B97914C0D8B53261A6C9CE93D6E306FE36A97FCE2F632C76FB180F2D1A2EC12510095CE35413D349386FD96B0F8EE54256EEE0AD9DA43CB0D386205D63F7EB20"; FileName = $pwdir + "\MiscDiagInfo.sql"; FileSize = 17791}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "218F71ECDA1075B4D2B5785A94EF43569306BBDB026C163DFEAF33F960F802D13C65F1BC103CC2978F497A2EF5EA972EE89940C807188FC7366E11A1C30DB2D9"; FileName = $pwdir + "\MSDiagProcs.sql"; FileSize = 194123}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "9789564CA007738B53D6CE21E6065A3D57D3E5A85DE85D32EC1456ED5A79CB1FA0265351FE402D266D6E90E31761DCED208AAA98EDA8BBC24AC25CF7819287D5"; FileName = $pwdir + "\QueryStore.sql"; FileSize = 4870}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "7216F9591ECB3C38BD962C146E57800687244B1C0E8450157E21CF5922BBBF92BB8431A814E0F5DF68933623DD76F9E4486A5D20162F58C232B8116920C252C7"; FileName = $pwdir + "\ProfilerTraces.sql"; FileSize = 3601}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "42BE545BC8D902A9D43146ACFC8D6A164242B567996C992D57CFBC6660B4E08051E7E687E2D140DAE5B17A8EEE652CFBD3904EC385702A2B8B666A980AE3C982"; FileName = $pwdir + "\Repl_Metadata_Collector.sql"; FileSize = 23414}
	    ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "3089C42E8B2A1F4DE4EDD172C4D43F978147DB875D25989662C36286C755F46C462CF8AB1A163083B8BBB4973F97AC333752D5CFBDE2BBEFDDA1556CBC884485"; FileName = $pwdir + "\SQL_Server_PerfStats_Snapshot.sql"; FileSize = 36982}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "275BF48FF8C495B6BA9217D2E5A3F7A7D1A7BDFF32AF035A2E9A03AF18773522816C6484B6F463C123B78572EF586CE846D9C1C36917E398A20E094D3836C58C"; FileName = $pwdir + "\SQL_Server_PerfStats.sql"; FileSize = 73276}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "98DD9089860E83AD5116AFC88E8A58EF18F3BC99FE68AC4E37765AF3442D58D2DC3C6826E860C0F0604B2C4733F33396F0894C2ACA9E905346D7C4D5A4854185"; FileName = $parentdir + "\SQL_LogScout.cmd"; FileSize = 2564}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "FC0FA00B999C9A6BF8CD55033A530C35D47F95CEE0156D540C77480E91180C7B9DBD303D5B73208D2C783D1FE628BF88AC845A4A452DD2FE3563E15E35A91BBD"; FileName = $pwdir + "\SQL_Server_Mem_Stats.sql"; FileSize = 35326}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "96CD13704AD380D61BC763479C1509F5B6EFCC678558AE8EACE1869C4BCD1B80767115D109402E9FDF52C144CFD5D33AAFFF23FE6CFFDF62CD99590B37D5D6CF"; FileName = $pwdir + "\SSB_DbMail_Diag.sql"; FileSize = 12477}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "2269D31F61959F08646C3E8B595191A110A8B559DEE43A60A5267B52A04F6A895E808CF2EC7C21B212BCAF9DD5AF3C25101B3C0FB91E8C1D6A2D1E42C9567FEC"; FileName = $pwdir + "\TempDB_and_Tran_Analysis.sql"; FileSize = 19749}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "26FB26FBC977B8DD1D853CBE3ABD9FFAA87743CF7048F5E6549858422749B9BD8D6F2CA1AFE35C3A703407E252D8F3CDC887460D2400E69063E99E9E76D4AFFB"; FileName = $pwdir + "\xevent_AlwaysOn_Data_Movement.sql"; FileSize = 23164}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "4EE3B0EE6CEA79CA9611489C2A351A7CCB27D3D5AD2691BE6380BF9C2D6270EE0CFC639B584A2307856384E7AA3B08462BCEA288D954786576DAFC4346670376"; FileName = $pwdir + "\xevent_backup_restore.sql"; FileSize = 1178}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "DE42C1F05E42FF67BBE576EA8B8ADF443DD2D889CBE34F50F4320BE3DC793AF88F5DE13FDC46147CA69535691CC78ADB89463602F5364ED332F6F09A254B7948"; FileName = $pwdir + "\xevent_core.sql"; FileSize = 8134}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "9E09DC85282A3870A339B4928AE1E3D4ECE34B5346DA9E52BD18712A6E3D07241D80083C4A18206BBBA4D2971F13BC937CE6062C76FD83189D66B8704B0CBA1A"; FileName = $pwdir + "\xevent_detailed.sql"; FileSize = 25312}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "2C5A3942093AC02FDE94626B327F6073056E4C14DA8AA13FE69404EFBABDF935B8622BA77316F630A2B313B7CE1EF20BC5A0A37E69FE38FFFCD794C16D82A71C"; FileName = $pwdir + "\xevent_general.sql"; FileSize = 20705}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "F643167BBC7C3BAAA3A9916A5A83C951DEC49A11DF7335E231D778F02C5271C934A3EDBEE8DC01B7F0624B54C8AB37576289441C8A1867F02620F4B6328CCBAC"; FileName = $pwdir + "\xevent_servicebroker_dbmail.sql"; FileSize = 39706}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "BF31CC80FDA7ED1DD52C88AE797B1FA186770DF005F3428D09785AD2307D6C059B71E5D8AF4EBF6A6AE60FF730519F25CEA934604BDD37CE8060BB38788CB497"; FileName = $pwdir + "\NeverEndingQuery_perfstats.sql"; FileSize = 6866}
    )
    # global array to keep a System.IO.FileStream object for each of the non-Powershell files
    # files are opened with Read sharing before being hashed
    # files are kept opened until SQL LogScout terminates preventing changes to them
    [System.Collections.ArrayList]$Global:hashedFiles = New-Object -TypeName System.Collections.ArrayList

    foreach ($efa in $expectedFileAttributes) {

        try{
            Write-LogDebug "Attempting to open file with read sharing: " $efa.FileName

            # open the file with read sharing and add to array
            [void]$Global:hashedFiles.Add(
                [System.IO.File]::Open(
                    $efa.FileName,
                    [System.IO.FileMode]::Open,
                    [System.IO.FileAccess]::Read,
                    [System.IO.FileShare]::Read
                    ))

        } catch {
            $validAttributes = $false
            Write-LogError "Error opening file with read sharing: " $efa.FileName
            Write-LogError $_
            return $validAttributes
        }

        Write-LogDebug "Validating attributes for file " $efa.FileName

        try {
            $file = Get-ChildItem -Path $efa.FileName

            if ($null -eq $file){
                throw "`$file is `$null"
            }
        }
        catch {
            $validAttributes = $false
            Write-LogError ""
            Write-LogError "Could not get properties from file " $efa.FileName
            Write-LogError $_
            Write-LogError ""
            return $validAttributes
        }

        try {
            $fileHash = Get-FileHash -Algorithm $efa.Algorithm -Path $efa.FileName

            if ($null -eq $fileHash){
                throw "`$fileHash is `$null"
            }

        }
        catch {
            $validAttributes = $false
            Write-LogError ""
            Write-LogError "Could not get hash from file " $efa.FileName
            Write-LogError $_
            Write-LogError ""
            return $validAttributes
        }

        if(($file.Length -ne $efa.FileSize) -or ($fileHash.Hash -ne $efa.Hash))
        {
            $validAttributes = $false
            Write-LogError ""
            Write-LogError "Attribute mismatch for file: " $efa.FileName
            Write-LogError ""
            Write-LogError "Expected File Size: " $efa.FileSize
            Write-LogError "  Actual File Size: " $file.Length
            Write-LogError ""
            Write-LogError "Expected File " $efa.Algorithm " Hash: " $efa.Hash
            Write-LogError "   Actual File " $fileHash.Algorithm " Hash: " $fileHash.Hash
            Write-LogError ""

        } else {
            Write-LogDebug "Actual File Size matches Expected File Size: " $efa.FileSize " bytes" -DebugLogLevel 2
            Write-LogDebug "Actual Hash matches Expected Hash (" $efa.Algorithm "): " $efa.Hash -DebugLogLevel 2
        }

        if (-not($validAttributes)){
            # we found a file with mismatching attributes, therefore backout indicating failure
            return $validAttributes
        }

    }

    return $validAttributes
}

function Get-FileAttributes([string] $file_name = ""){
<#
    .SYNOPSIS
        Display string for $expectedFileAttributes.
    .DESCRIPTION
        This is to be used only when some script is changed and we need to refresh the file attributes in Confirm-FileAttributes.ps1
    .EXAMPLE
        Import-Module -Name .\Confirm-FileAttributes.psm1
        Get-FileAttributes #all files
        Get-FileAttributes "xevent_core.sql" #for a single file
#>

    [int]$fileCount = 0
    [System.Text.StringBuilder]$sb = New-Object -TypeName System.Text.StringBuilder

    [void]$sb.AppendLine("`$expectedFileAttributes = @(")

    foreach($file in (Get-ChildItem -Path . -File -Filter $file_name -Recurse)){

        # Powershell files are signed, therefore no need to hash-compare them
        # "Get-ChildItem -Exclude *.ps1 -File" yields zero results, therefore we skip .PS1 files with the following IF
        if ((".sql" -eq $file.Extension) -or (".cmd" -eq $file.Extension) -or (".bat" -eq $file.Extension))
        {

            $fileCount++

            # append TAB+space for first file (identation)
            # append TAB+comma for 2nd file onwards
            if($fileCount -gt 1){
                [void]$sb.Append("`t,")
            } else {
                [void]$sb.Append("`t ")
            }

            $fileHash = Get-FileHash -Algorithm SHA512 -Path $file.FullName

            $algorithm = $fileHash.Algorithm
            $hash = $fileHash.Hash

            if($file.Name -eq "SQL_LogScout.cmd")
            {
                $fileName = "`$parentdir `+ `"`\" + $file.Name + "`""
            }
            else 
            {
                $fileName = "`$pwdir `+ `"`\" + $file.Name + "`""
            }
            
            $fileSize = [string]$file.Length

            [void]$sb.AppendLine("[PSCustomObject]@{Algorithm = `"$algorithm`"; Hash = `"$hash`"; FileName = $fileName; FileSize = $fileSize}")

        }

    }

    [void]$sb.AppendLine(")")

    Write-Host $sb.ToString()
}

# SIG # Begin signature block
# MIIn0AYJKoZIhvcNAQcCoIInwTCCJ70CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDChN5eNo1s40Kn
# Gpa1P6XW+jWo/I+psFrwr7eCDyg4v6CCDYUwggYDMIID66ADAgECAhMzAAADri01
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
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOzq
# tQUu9fZCrsUoZL/8KDDx3dkrZ2izAUARMlH9OEV5MEQGCisGAQQBgjcCAQwxNjA0
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEcgBpodHRwczovL3d3d3cubWljcm9zb2Z0
# LmNvbTANBgkqhkiG9w0BAQEFAASCAQDy1MFzenjnX7XtKXuEQZtVaaQoTO+B8xE/
# ++AoYRGbdOCOusVOCFcouuIg9DV7rSOB6vN51//WOcUWc4htCdtK2gCe31r5yYCW
# 27MIDp8dATJ1Dzx9+t0kGHSWwyVCx9d7+/rOu/79NdpsXHyXR4tuJk7m8EFe2dIL
# Nww6CidCCksnECexwFgUe7YPIap0iVXxjHJX4QxhaldlECuY7e8OVR5iZt79MUBv
# Viswkkxi+TLhjEVtVMZgbsEtEAJGev1ROorzSjuK+p6K9PrfYNBu7oXNYxE6JDOE
# 4xmhcCU0JE2KRoahod5nt2jWWNuFIRx4Cv+l+3Zl5ZbDyXZAlIfNoYIXKTCCFyUG
# CisGAQQBgjcDAwExghcVMIIXEQYJKoZIhvcNAQcCoIIXAjCCFv4CAQMxDzANBglg
# hkgBZQMEAgEFADCCAVkGCyqGSIb3DQEJEAEEoIIBSASCAUQwggFAAgEBBgorBgEE
# AYRZCgMBMDEwDQYJYIZIAWUDBAIBBQAEIEaS41zFKretputvz+4Uhw8dV1rbDqHi
# d5pSt93DDeAjAgZlup2uJJYYEzIwMjQwMjE2MDkwMDI2LjU2NFowBIACAfSggdik
# gdUwgdIxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xLTArBgNV
# BAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJhdGlvbnMgTGltaXRlZDEmMCQGA1UE
# CxMdVGhhbGVzIFRTUyBFU046MkFENC00QjkyLUZBMDExJTAjBgNVBAMTHE1pY3Jv
# c29mdCBUaW1lLVN0YW1wIFNlcnZpY2WgghF4MIIHJzCCBQ+gAwIBAgITMwAAAd6e
# SJ6WnyhEPQABAAAB3jANBgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJVUzETMBEG
# A1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
# cm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFt
# cCBQQ0EgMjAxMDAeFw0yMzEwMTIxOTA3MTJaFw0yNTAxMTAxOTA3MTJaMIHSMQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNy
# b3NvZnQgSXJlbGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsTHVRoYWxl
# cyBUU1MgRVNOOjJBRDQtNEI5Mi1GQTAxMSUwIwYDVQQDExxNaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBTZXJ2aWNlMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA
# tIH0HIX1QgOEDrEWs6eLD/GwOXyxKL2s4I5dJI7hUxCOc0YCjlUfHSKKMwQwf0tj
# ZJQgGRVBLQyXqRH5NqCRQ9toSnCOFDWamuFGAlP+OVKeJzjZUMCjR6fgkjrGdegC
# hagrJJjz9E4gp2mmGAjs4lvhceTU/exfak1nfYsNjWS1yErX+FbI+VuVpcAdG7QT
# fKe/CtLz9tyisA07oOO7KzJL3NSav7DcfcAS9KCzZF64uPamQFx9bVQ8IW50t3sg
# 9nZELih1BwQ+djXaPKlg+dLrJkCzSkumrQpEVTIHXHrHo5Tvey52Ic43XqYTSXos
# tP06YajRL3gHGDc3/doTp9RudWh6ZVzsWQUu6bwqRlxtDtw4dIBYYnF0K+jk61S1
# F1Kp/zkWSUJcgiSDiybucz1OS1RV87SSnqTHubKyAPRCvHHr/mhqqfA5NYs3Mr4E
# KLUbudQPWm165e9Cnx8TUqlOOcb/U4l56HAo00+Ma33xXQGaiBlN7dLEGQ545DIs
# D77kfKD8vryl74Otmhk9cloZT+IGIWYv66X86Ld3zfMsAeUdCYf9UY0F9HA/6LG+
# qHKT8R5vC5dUlj6tPJ9tF+6H2fQBoyGE3HGDq0YrJlLgQASIPGsX2YBkTLx7yt/p
# 2Uohfl3dpAuj18N1rVlM7D5cBwC+Pb83cMtUZmUeceUCAwEAAaOCAUkwggFFMB0G
# A1UdDgQWBBRrMCZvGx5pqmB3HMrw6z6do9ASyDAfBgNVHSMEGDAWgBSfpxVdAF5i
# XYP05dJlpxtTNRnpcjBfBgNVHR8EWDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jv
# c29mdC5jb20vcGtpb3BzL2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENB
# JTIwMjAxMCgxKS5jcmwwbAYIKwYBBQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRw
# Oi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRp
# bWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNydDAMBgNVHRMBAf8EAjAAMBYGA1Ud
# JQEB/wQMMAoGCCsGAQUFBwMIMA4GA1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsF
# AAOCAgEA4pTAexcNpwY69QiCzkcOA+zQtnWrIdLoLrB8qUtoPfq1l9ta3XH4YyJr
# NK7L4azGJUfOSExb4WoryCu4tBY3+w4Jf58ZSBP0tPbVxEilxmPj9kUi/C2QFywL
# PVcRSxdg5IlQ+K1jsTxtuV2aaFhnb2n5dCkhywb+r5iOSoFb2bDSu7Ux/ExNCz0x
# MOIPbyABUas8Dc3KSJIKG92pLtVf78twTP1RvO2j/DbxYDwc4IeoFNsNEeaI/swi
# P5JCYj1UhrJiwgZGO96WY1rQ69tT0IlLP818wSB/Y0cxlRhbwqpYSMiM98cgrFaU
# 0xiG5Z9ZFIdkIrIgA0DRokviygdC3PNnYyc1+NhjznXAdiMaDBSP+GUtGBA7lLfR
# nHvwaoEp/KWnblo5Yn+o+EL4NczaBdqMhduX6OkZxUA3C0UW6MIlF1lt4fVH5DjU
# WOAGDibc5MUMai3kNK5WRCCOS7uk5U+2V0TjpCUOD/ZaE+lNDFcfriw/UZ+QDBS2
# 3qutkz88LBEbqCKtiadNEsuyJwGGhguH4QQWNW+JcAZOTqme7yPH/hY9a7SOzPvI
# XODzb8UyoKT3Arcu/IsDIMc34XFscDG2DBp3ugtA8zRYYRF0HW6Y8IiJixJ/+Pv0
# Sod2g3BBhE5Wb5lfXRFfefptGYCeyR42GLTCdVp5WiAsx0YP6eowggdxMIIFWaAD
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
# HVRoYWxlcyBUU1MgRVNOOjJBRDQtNEI5Mi1GQTAxMSUwIwYDVQQDExxNaWNyb3Nv
# ZnQgVGltZS1TdGFtcCBTZXJ2aWNloiMKAQEwBwYFKw4DAhoDFQBooFKKzLjLzqmX
# xfLbYIlkTETa86CBgzCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
# aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
# MA0GCSqGSIb3DQEBBQUAAgUA6XmKxzAiGA8yMDI0MDIxNjE1MTgzMVoYDzIwMjQw
# MjE3MTUxODMxWjB0MDoGCisGAQQBhFkKBAExLDAqMAoCBQDpeYrHAgEAMAcCAQAC
# AhwYMAcCAQACAhP/MAoCBQDpetxHAgEAMDYGCisGAQQBhFkKBAIxKDAmMAwGCisG
# AQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMBhqAwDQYJKoZIhvcNAQEFBQAD
# gYEAZQ22dQ/zacCcWzoIcWSNZmBsO0YQMPCFIcfED8HxIW3du33QNuLkvfB7yVcv
# Drx4bRV6ry5hxKoUcuCCbq0jCs0DqOfDrM7NL1ubSyE4ttA8JfxxdVFy6FHuGhEo
# SOxmRrQT5ab/baCXb7j8BG3HW9gbo5N5JF4VOWYW88TW9/cxggQNMIIECQIBATCB
# kzB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQD
# Ex1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAd6eSJ6WnyhEPQAB
# AAAB3jANBglghkgBZQMEAgEFAKCCAUowGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJ
# EAEEMC8GCSqGSIb3DQEJBDEiBCCqT8DzaA13nSYo2KzrO5NwXo7bOniW8gjt0nVc
# s8zUiDCB+gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0EII4+I58NwV4QEEkCf+YL
# cyCtPnD9TbPzUtgPjgdzfh17MIGYMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAg
# UENBIDIwMTACEzMAAAHenkielp8oRD0AAQAAAd4wIgQguVLyScLaRhlo9Hg8gid1
# lkNe882F50Dda1tBlQd1sogwDQYJKoZIhvcNAQELBQAEggIAc8FofMJcKho9Dw3F
# iS2zwPjbpl5YbY+cpH5d2XUYfaN5qFixt9SWNNd0uhsIG3+v9PhOK1svnuufI159
# wiFYdke3v/D6cmRH0EYNPGMgXVRWTYRWkmNyG+ZPpc4wWT7pT9L7sDnAFKC1aSSX
# 0HCOMymO25b8fvW/BP4mrxWxj+/yGK7Pu4TFHcj1PiPC/NZCt0Rip5HWcSbH+Uaz
# iMYxJQxESoHXQgydGPnsZbgWMCOZVhaF7chYvf1JYkqJiX6r0lqVEmwGjBqjsgU/
# QMPCU9SbUP5Y3nwrDhxFibmBEp0xRMsbtEXpn4tBKznhlXY/40D19FZfyi+oJnvX
# n85P5ZEEld2MplHb6+hWEQ5bfEDcblBHXMbvlSkJh+4a587LpGk51UfcPSM/spig
# FVeQCxtp8vIUFoqbJUrMnadS6LQ0AaNH2v5GEoDTqaFwP7HQkKz4HcHsuCyWbJ+q
# Qt4uMhbnk6rgHFcskkVS2jQEwdSvxyEuUfX93tqiXLeN82FkMJjg2GnqIV1hLedz
# 88t1i9YejB7UhvlK3zM7zPeKiYR21/UWb+pseYxFL94lg4HYhS/TCqXrL76UjYDp
# idT4BUx/ZW5FyuLNvb+3Yx1bqI5ctMFHks6OhRPJgTYvM7NW07X8xBAzGrqNeVeV
# tQu0Qw9lpHTys9jS6eYJcQT4zSI=
# SIG # End signature block
