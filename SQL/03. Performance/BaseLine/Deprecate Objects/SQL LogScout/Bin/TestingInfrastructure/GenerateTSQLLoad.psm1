[System.Diagnostics.Process] $global:sqlcmd_process_tsqlload
[string] $global:TSQLLoadLog
[string] $global:TSQLLoadLogPath


$TSQLLoadCommonFunction = (Get-Module -Name CommonFunctions).Name

    if ($TSQLLoadCommonFunction -ne "CommonFunctions")
        {
            #Since we are in bin and CommonFunctions is in root directory, we need to step out to import module
            #This is so we can use HandleCatchBlock
            $CurrentPath = Get-Location
            [string]$CommonFunctionsModule = (Get-Item $CurrentPath).parent.FullName + "\CommonFunctions.psm1"
            Import-Module -Name $CommonFunctionsModule
        }


function Initialize-TSQLLoadLog
{
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$LogFileName = "TSQLLoadOutput.log",

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Scenario

    )

    try
    {
        $CurrentDirectory = Get-Location
        $global:TSQLLoadLogPath = (Get-Item $CurrentDirectory).parent.FullName + "\TestingInfrastructure\output\"+(Get-Date).ToString('yyyyMMddhhmmss') + '_'+ $Scenario +'_' 
        $global:TSQLLoadLog = $global:TSQLLoadLogPath + $LogFileName
        $LogFileExistsTest = Test-Path $global:TSQLLoadLog
        if ($LogFileExistsTest -eq $False)
        {
            New-Item -Path $global:TSQLLoadLog -ItemType File -Force| Out-Null
            
        }
        else {
            Write-TSQLLoadLog "TSQLLoadLog : Starting New Capture"
        }
    }
	catch
	{
		HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
	}
}


function Write-TSQLLoadLog()
{
    param 
    ( 
        [Parameter(Position=0,Mandatory=$true)]
        [Object]$Message
    )

    try
    {        
        [String]$strMessage = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $strMessage += "	: "
        $strMessage += [string]($Message)
        Add-Content -Path $global:TSQLLoadLog -Value $strMessage
    }
	catch
	{
		HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
	}
    
}




function TSQLLoadInsertsAndSelectFunction
{
    
    param
    (
        [Parameter(Position=0)]
        [string] $ServerName = $env:COMPUTERNAME
    )

    try 
    {
        
    
        $executable = "sqlcmd.exe"
        
        $neverending_query = "SELECT COUNT_BIG(*) FROM sys.messages a, sys.messages b, sys.messages c OPTION(MAXDOP 8)"

        $query = "SET NOCOUNT ON;

        DECLARE @sql_major_version INT, 
                @sql_major_build INT, 
                @sql NVARCHAR(max), 
                @qds_sql NVARCHAR(MAX)
        
        SELECT  @sql_major_version = (CAST(PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS varchar(20)), 4) AS INT)),
                @sql_major_build = (CAST(PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS varchar(20)), 2) AS INT)) 
       
        -- create some QDS actions 

        IF (@sql_major_version >= 13)
        BEGIN
			SET @qds_sql = 'IF DB_ID(''QDS_TEST_LOGSCOUT'') IS NOT NULL DROP DATABASE QDS_TEST_LOGSCOUT'
            EXEC(@qds_sql)
			
            
            SET @qds_sql = '
            PRINT ''Creating ''''QDS_TEST_LOGSCOUT'''' database''
            CREATE DATABASE QDS_TEST_LOGSCOUT'
            EXEC(@qds_sql)
            
            SET @qds_sql = 'ALTER DATABASE QDS_TEST_LOGSCOUT
            SET QUERY_STORE = ON (OPERATION_MODE = READ_WRITE)'
            EXEC(@qds_sql)

			SET @qds_sql = 'SET NOCOUNT ON;
            USE QDS_TEST_LOGSCOUT;
            SELECT TOP 200 * INTO messagesA FROM sys.messages
            SELECT TOP 100 * INTO messagesB FROM sys.messages
            SELECT TOP 300 * INTO messagesC FROM sys.messages
            
            SELECT TOP 5 a.message_id , b.text 
            FROM messagesA a 
            JOIN messagesB b 
            ON a.message_id = b.message_id 
            AND a.language_id = b.language_id
            RIGHT JOIN messagesC c
            ON b.message_id = c.message_id 
            AND b.language_id = c.language_id
            JOIN sys.messages d
            ON c.message_id = d.message_id 
            AND c.language_id = d.language_id '
			EXEC(@qds_sql)
        END

        
        --Wait for logscout to start up for ScenarioTest
        WAITFOR DELAY '00:00:30';
        USE TEMPDB;
        GO
        
        IF OBJECT_ID('##TestSQLLogscoutTable') IS NOT NULL DROP TABLE ##TestSQLLogscoutTable;
        GO
        
        IF OBJECT_ID('##TestSQLLogscoutProcedure') IS NOT NULL DROP PROCEDURE ##TestSQLLogscoutProcedure;
        GO
        
        CREATE TABLE ##TestSQLLogscoutTable
        ([ID] int, [Description] nvarchar(128));
        GO
        
        INSERT INTO ##TestSQLLogscoutTable
        VALUES (0,'Test insert from SQL_LogScout Testing Infrastructure');
        GO
        
        --This proc usually takes 30 seconds
        CREATE PROCEDURE ##TestSQLLogscoutProcedure
        AS
            BEGIN
            DECLARE @cntr int
            SET @cntr = 0
            WHILE @cntr<1999
                BEGIN
                    WAITFOR DELAY '00:00:00:01'
                    SET @cntr = @cntr+1
                    INSERT INTO ##TestSQLLogscoutTable
                    VALUES ((select max(ID) FROM ##TestSQLLogscoutTable)+1, 'Test insert from SQL_LogScout Testing Infrastructure')
                END
            END
        GO
        
        --Run proc that executes 2000 times	
        EXEC ##TestSQLLogscoutProcedure
        
        
        
        --Run basic select
        SELECT [Description], count(*) [#Inserts]
        FROM ##TestSQLLogscoutTable
        GROUP BY [Description];
        GO
        
        IF OBJECT_ID('##TestSQLLogscoutTable') IS NOT NULL DROP TABLE ##TestSQLLogscoutTable;
        GO
        
        IF OBJECT_ID('##TestSQLLogscoutProcedure') IS NOT NULL DROP PROCEDURE ##TestSQLLogscoutProcedure;
        GO

        DECLARE @sql_major_version INT = (CAST(PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS varchar(20)), 4) AS INT)),
        @qds_sql NVARCHAR(MAX)
        IF (@sql_major_version >= 13)
        BEGIN
            SET @qds_sql = 'USE master;
            IF DB_ID(''QDS_TEST_LOGSCOUT'') IS NOT NULL
            BEGIN
                ALTER DATABASE QDS_TEST_LOGSCOUT SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
                PRINT ''Dropping ''''QDS_TEST_LOGSCOUT'''' database''
                DROP DATABASE QDS_TEST_LOGSCOUT
            END'
            EXEC(@qds_sql)
        END
        "
    
        $sqlcmd_output = $global:TSQLLoadLogPath + "TSQLLoad_SQLCmd.out"
        $sqlcmd_error = $global:TSQLLoadLogPath + "TSQLLoad_SQLCmd.err"


        # Start the process for never ending query execution - run it for 160 seconds and timeout
        $argument_list_never_ending = "-S" + $ServerName + " -E -Hsqllogscout_loadtest -t160 -w8000 -Q`""+ $neverending_query + "`" "
        Write-TSQLLoadLog "TSQLLoadLog : Never-ending argument list - $argument_list_never_ending"

        $sqlcmd_process_never_ending = Start-Process -FilePath $executable -ArgumentList $argument_list_never_ending -WindowStyle Hidden -PassThru -RedirectStandardError $sqlcmd_error
        Write-TSQLLoadLog "TSQLLoadLog : Started Load Script"
        Write-TSQLLoadLog "TSQLLoadLog : Process ID for Never-ending Test Load is: $sqlcmd_process_never_ending"


        # Start the process for the bigger workload
        $argument_list = "-S" + $ServerName + " -E -Hsqllogscout_loadtest -w8000 -Q`""+ $query + "`" "
        Write-TSQLLoadLog "TSQLLoadLog : Argument List - $argument_list"
    
        
        $sqlcmd_process_tsqlload = Start-Process -FilePath $executable -ArgumentList $argument_list -WindowStyle Hidden -PassThru -RedirectStandardOutput $sqlcmd_output
        $global:sqlcmd_process_tsqlload = $sqlcmd_process_tsqlload.Id
                
        Write-TSQLLoadLog "TSQLLoadLog : Process ID for Test Load is: $global:sqlcmd_process_tsqlload"

    }
    
    catch 
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
    }
}





function TSQLLoadCheckWorkloadExited ()
{
    try 
    {
        while ($false -eq $global:sqlcmd_process_tsqlload.HasExited) 
        ##Logically we should never enter this code as this tsql load should have completed before logscout finished. If we are hung for some reason, we need to terminate the process.
        {
                Stop-Process $global:sqlcmd_process_tsqlload
                Write-TSQLLoadLog "TSQLLoadLog : TSQL Load Terminated Due to Long Duration"
        }
        Write-TSQLLoadLog "TSQLLoadLog : Process exited as expected" 
    }

    catch 
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
    }
}

# SIG # Begin signature block
# MIIoPQYJKoZIhvcNAQcCoIIoLjCCKCoCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB4AtAi1Gqd02ZH
# 2ojZUaDShCc2Ike7OTnmTUKgvqqc56CCDYUwggYDMIID66ADAgECAhMzAAADri01
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
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMEF
# rvw5uASrL4v+qJM1ptEt53L1B0sunl16GEbUC6xTMEQGCisGAQQBgjcCAQwxNjA0
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEcgBpodHRwczovL3d3d3cubWljcm9zb2Z0
# LmNvbTANBgkqhkiG9w0BAQEFAASCAQBKtbCwq/h3naP8js36EJln8gLBW9lJu3kI
# eE2TAuErIj7GAeIzZqf2HVLiwm1z7mWzMRyh3yqiu+IiAz7wJRzN92fklisMe/w9
# 4cxCtRAWsoMXpLDCqoM7WZYVFyJEjkr2zMes3NyPVV28e500lk9K1fPFry0i+QYR
# nHGHc279zDNsOtLWGguBjUoavZNPO0ncslO44qt7DyLN0yRZn3GfugiCStoQszOu
# grAklH/3uT8r4qpC0kys1FawaXIoxeuCVoTPUv6SV42TEj9+zwahMMIRcXi9xZvn
# YHB+D0ZAaXMdx+Jm7bnt4KUI7i20CvtpZWkBx1whPnBkAUBxqrZloYIXljCCF5IG
# CisGAQQBgjcDAwExgheCMIIXfgYJKoZIhvcNAQcCoIIXbzCCF2sCAQMxDzANBglg
# hkgBZQMEAgEFADCCAVIGCyqGSIb3DQEJEAEEoIIBQQSCAT0wggE5AgEBBgorBgEE
# AYRZCgMBMDEwDQYJYIZIAWUDBAIBBQAEIP0aPVrsNbEt5Ae5dIlBQjhdLhnC29YY
# y/+VKbvcjFMJAgZlzf7wRBUYEzIwMjQwMjE2MDkwMDM1LjE2OVowBIACAfSggdGk
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
# AzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQgr/XOKp2DuKzl6oK/MNG0
# AGGfSlJlxZrYxkisqhwQGoIwgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCDl
# Nl0NdmqG/Q3gxVzPVBR3hF++Bb9AAb0DBu6gudZzrTCBmDCBgKR+MHwxCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
# HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29m
# dCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB5y6PL5MLTxvpAAEAAAHnMCIEIG0r
# YnLtiEF+0VeGlSpIUy3hB3JwVELbYZce0/YAkI7uMA0GCSqGSIb3DQEBCwUABIIC
# AKnkP4+pJ3IJ/BNQqpgDP2Pjt2iWmTXWES3ylwtd2mSZuP2J9sjJ+0V+ppU3lFk7
# dhRFXQWkIJ0pa7cDuYbXKEp4LbqrN5Gh2fAFq1fjsxWAAloFrCWo9OTDUras6esL
# kygC4ZgUsqHI0r6+p7WWjyacQ02W08aVrfhU+S2/2c0ewZNnSQ5gp2ukM0V4tQ0W
# whRY5XdYxmFkBzEyTj0VGtX8Qom21J/2FauwA1di2sN3YUZL+xQQ68pyRbjwS8Eu
# ltfFb3owT2UuK65pI0g2fbiU/C2NAAS2Xv160x6mCqKywRaHkEkz/3CWSJ94z5CN
# eqQ7ge+MJuMZX38QduuTyRs1oa/qXj3tlWQr3g2H8NNSCI9sUVmzxbA0ENs8Ins6
# m+PMC7m4mGGLFA2rcMVa1/pdj6S2dKAFWNyATngDQFsn8LsTb5y+B5wxmBi/09f8
# wCyelBJUjha/2sIIoSXctdgcEr5Fgmcb+dndb7MshavWxf1DdDrQH+H6cb3wVWx3
# 7YFfLuUrQOtNaPTGrcTY4OVYfhpKJJT1M/MgsLFQ3ZIyTmT3zctyzItPUYFCeq65
# WA4ugDFjsHnH6n+SyG9DbU06wKinvg5n+UQfMLAjeXLOJfkNVg+FUwr1lfawPgTB
# ABeHLGJqDQMaS6s/jyoTaV85hrWhhXmCtIdE6H/OeNnM
# SIG # End signature block
