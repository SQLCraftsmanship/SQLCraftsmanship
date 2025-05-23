$CommonFuncModule = (Get-Module -Name CommonFunctions).Name

if ($CommonFuncModule -ne "CommonFunctions")
{
    Import-Module -Name .\CommonFunctions.psm1
}


#=======================================Globals =====================================
[int]$global:DEBUG_LEVEL = 0 # zero to disable, 1 to 5 to enable different levels of debug logging to *CONSOLE*
[string]$global:full_log_file_path = ""
[System.IO.StreamWriter]$global:consoleLogStream
[System.IO.StreamWriter]$global:debugLogStream
[System.IO.StreamWriter]$global:ltDebugLogStream # log-term debug log, this will be stored in $env:TEMP, most recent 15 files are kept
$global:consoleLogBuffer = @()
$global:debugLogBuffer = @()

#=======================================Init    =====================================
#cleanup from previous script runs
#NOT needed when running script from CMD
#but helps when running script in debug from VSCode
if ($Global:consoleLogBuffer) {Remove-Variable -Name "consoleLogBuffer" -Scope "global"}
if ($Global:debugLogBuffer) {Remove-Variable -Name "debugLogBuffer" -Scope "global"}
if ($Global:consoleLogStream)
{
    $Global:consoleLogStream.Flush
    $Global:consoleLogStream.Close
    Remove-Variable -Name "consoleLogStream" -Scope "global"
}
if ($Global:debugLogStream)
{
    $Global:debugLogStream.Flush
    $Global:debugLogStream.Close
    Remove-Variable -Name "debugLogStream" -Scope "global"
}
if ($Global:ltDebugLogStream)
{
    $Global:ltDebugLogStream.Flush
    $Global:ltDebugLogStream.Close
    Remove-Variable -Name "ltDebugLogStream" -Scope "global"
}

function Read-Host
{
<#
    .SYNOPSIS
        Wrapper function to intercept calls to Read-Host and make sure that input is recorded by calling Write-LogInformation.
    .DESCRIPTION
        Wrapper function to intercept calls to Read-Host and make sure that input is recorded by calling Write-LogInformation.
        By intercepting these calls we can ensure that all console reads get recorded into ##SQLLOGSCOUT.LOG.
    .EXAMPLE
        $ret = Read-Host
        $ret = Read-Host "Overwrite? (Y/N)"
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromRemainingArguments)]
    [Object]$Prompt,

    [Parameter()]
    [System.Management.Automation.SwitchParameter]$AsSecureString,

    [Parameter()]
    [string]$CustomLogMessage
    )

    # if CustomLogMessage was not passed as parameter we define a generic log message
    if (-not($PSBoundParameters.ContainsKey("CustomLogMessage"))){
        $CustomLogMessage = "Console Input:"
    }

    if ($AsSecureString) {
        $ret = Microsoft.PowerShell.Utility\Read-Host -Prompt $Prompt -AsSecureString
    } else {
        $ret = Microsoft.PowerShell.Utility\Read-Host -Prompt $Prompt
    }

    if ($ret.GetType() -eq "System.Security.SecureString"){
        Write-LogInformation ($CustomLogMessage + " <SecureString ommitted>")
    } else {
        Write-LogInformation ($CustomLogMessage + " " + $ret)
    }

    #Read-Host is the cause of resetting disableCtrlCAsInput so we need to check reset it after every use.
    
    setDisableCtrlCasInput

    return $ret
}

function Write-Host
{
<#
    .SYNOPSIS
        Wrapper function to intercept calls to Write-Host and make sure those are logged by calling Write-Log*.
    .DESCRIPTION
        Wrapper function to intercept calls to Write-Host and make sure those are logged by calling Write-Log*.
        By intercepting these calls we can ensure that all messages get recorded into ##SQLLOGSCOUT.LOG.
        If foreground message color is yellow it'll invoke Write-LogWarning.
        If foreground message color is red it'll invoke Write-LogError.
        For any other color it will invoke Write-LogInformation.
    .EXAMPLE
        Write-Host "Test"
        Write-Host "Some warning" -ForegroundColor Yellow
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromRemainingArguments)]
    [Object]$Object,

    [Parameter()]
    [System.Management.Automation.SwitchParameter]$NoNewline,
    
    [Parameter()]
    [Object]$Separator,

    [Parameter()]
    [System.ConsoleColor]$ForegroundColor,

    [Parameter()]
    [System.ConsoleColor]$BackgroundColor
    )

    if (-not($PSBoundParameters.ContainsKey("ForegroundColor"))){
        $ForegroundColor = [System.ConsoleColor]::White
    }

    if (-not($PSBoundParameters.ContainsKey("BackgroundColor"))){
        $BackgroundColor = [System.ConsoleColor]::Black
    }

    if ($ForegroundColor -eq [System.ConsoleColor]::Yellow){
        Write-LogWarning $Object
    } elseif ($ForegroundColor -eq [System.ConsoleColor]::Red){
        Write-LogError $Object
    } else {
        Write-LogInformation $Object -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
    }
    #Microsoft.PowerShell.Utility\Write-Host $Object, $NoNewline, $Separator, $ForegroundColor, $BackgroundColor
}

function Write-Error
{
<#
    .SYNOPSIS
        Wrapper function to intercept calls to Write-Error and make sure those are logged by calling Write-LogError.
    .DESCRIPTION
        Wrapper function to intercept calls to Write-Error and make sure those are logged by calling Write-LogError.
        Once logging is done, this function will call original implementation of Write-Error.
    .EXAMPLE
        Preferred ==> Write-Error -Exception $_.Exception
        Write-Error "My custom error"
        Write-Error -ErrorRecord $_.Exception.ErrorRecord
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0, ParameterSetName = "NoException", Mandatory, ValueFromPipeline)]
    [Parameter(ParameterSetName = "WithException")]
    [Alias("Msg")]
    [string]$Message,

    [Parameter(ParameterSetName = "WithException", Mandatory)]
    [Exception]$Exception,

    [Parameter(ParameterSetName = "ErrorRecord", Mandatory)]
    [System.Management.Automation.ErrorRecord]$ErrorRecord,

    [Parameter(ParameterSetName = "NoException")]
    [Parameter(ParameterSetName = "WithException")]
    [System.Management.Automation.ErrorCategory]$Category = [System.Management.Automation.ErrorCategory]::NotSpecified,

    [Parameter(ParameterSetName = "NoException")]
    [Parameter(ParameterSetName = "WithException")]
    [string]$ErrorId = [string].Empty,

    [Parameter(ParameterSetName = "NoException")]
    [Parameter(ParameterSetName = "WithException")]
    [object]$TargetObject = $null,

    [Parameter()]
    [string]$RecommendedAction = [string].Empty,

    [Parameter()]
    [Alias("Activity")]
    [string]$CategoryActivity = [string].Empty,

    [Parameter()]
    [Alias("Reason")]
    [string]$CategoryReason = [string].Empty,

    [Parameter()]
    [Alias("TargetName")]
    [string]$CategoryTargetName = [string].Empty,

    [Parameter()]
    [Alias("TargetType")]
    [string]$CategoryTargetType = [string].Empty
    )


    switch ($PsCmdlet.ParameterSetName)
    {
        "NoException"
        {
            Write-LogError "Error with no exception"
            Write-LogError "Message: " $Message
            Write-LogError "Category: " $Category            
        }
        
        "WithException"
        {
            if("" -eq $Message) {$Message = $Exception.Message}
            if($null -eq $ErrorRecord) {$ErrorRecord = $Exception.ErrorRecord}

            Write-LogError "Error with Exception information"
            Write-LogError "Exception: " $Exception
            Write-LogError "ScriptLineNumber: " $ErrorRecord.InvocationInfo.ScriptLineNumber "OffsetInLine: " $ErrorRecord.InvocationInfo.OffsetInLine
            Write-LogError "Line: " $ErrorRecord.InvocationInfo.Line
            Write-LogError "ScriptStackTrace: " $ErrorRecord.ScriptStackTrace
            Write-LogError "Message: " $Message
            Write-LogError "Category: " $Category
        }
        
        "ErrorRecord"
        {
            if($null -eq $Exception) {$Exception = $ErrorRecord.Exception}
            if("" -eq $Message) {$Message = $Exception.Message}
            
            Write-LogError "Error with Error Record information"
            Write-LogError "Exception: " $Exception
            Write-LogError "ScriptLineNumber: " $ErrorRecord.InvocationInfo.ScriptLineNumber "OffsetInLine: " $ErrorRecord.InvocationInfo.OffsetInLine
            Write-LogError "Line: " $ErrorRecord.InvocationInfo.Line
            Write-LogError "ScriptStackTrace: " $ErrorRecord.ScriptStackTrace
            Write-LogError "Message: " $Message
            Write-LogError "Category: " $Category
        }
    }

    if("" -ne $ErrorId) {Write-LogError "ErrorId: " $ErrorId}
    if($null -ne $TargetObject) {Write-LogError "TargetObject: " $TargetObject}
    if("" -ne $RecommendedAction) {Write-LogError "RecommendedAction: " $RecommendedAction}
    if("" -ne $CategoryActivity) {Write-LogError "CategoryActivity: " $CategoryActivity}
    if("" -ne $CategoryReason) {Write-LogError "CategoryReason: " $CategoryReason}
    if("" -ne $CategoryTargetName) {Write-LogError "CategoryTargetName: " $CategoryTargetName}
    if("" -ne $CategoryTargetType) {Write-LogError "CategoryTargetType: " $CategoryTargetType}
    
    switch ($PsCmdlet.ParameterSetName)
    {
        "NoException"
        {
            Microsoft.PowerShell.Utility\Write-Error -Message $Message -Category $Category -ErrorId $ErrorId -TargetObject $TargetObject -RecommendedAction $RecommendedAction `
            -CategoryActivity $CategoryActivity -CategoryReason $CategoryReason -CategoryTargetName $CategoryTargetName -CategoryTargetType $CategoryTargetType
        }
        
        "WithException"
        {
            Microsoft.PowerShell.Utility\Write-Error -Exception $Exception -Message $Message -Category $Category -ErrorId $ErrorId -TargetObject $TargetObject `
            -RecommendedAction $RecommendedAction -CategoryActivity $CategoryActivity -CategoryReason $CategoryReason -CategoryTargetName $CategoryTargetName -CategoryTargetType $CategoryTargetType
        }
        
        "ErrorRecord"
        {
            Microsoft.PowerShell.Utility\Write-Error -ErrorRecord $ErrorRecord -RecommendedAction $RecommendedAction -CategoryActivity $CategoryActivity -CategoryReason $CategoryReason `
            -CategoryTargetName $CategoryTargetName -CategoryTargetType $CategoryTargetType
        }
    }
}
function Format-LogMessage()
{
<#
    .SYNOPSIS
        Format-LogMessage handles complex objects that need to be formatted before writing to the log
    .DESCRIPTION
        Format-LogMessage handles complex objects that need to be formatted before writing to the log
        To prevent writing "System.Collections.Generic.List`1[System.Object]" to the log
    .PARAMETER Message
        Object containing string, list, or list of lists
#>
[CmdletBinding()]
param ( 
    [Parameter(Mandatory)] 
    [ValidateNotNull()]
    [Object]$Message
    )

    [String]$strMessage = ""
    [String]$MessageType = $Message.GetType()

    if (($MessageType -eq "System.Collections.Generic.List[System.Object]") -or
        ($MessageType -eq "System.Collections.ArrayList"))
    {
        foreach ($item in $Message) {
            
            [String]$itemType = $item.GetType()
            
            #if item is a list we recurse
            #if not we cast to string and concatenate
            if(($itemType -eq "System.Collections.Generic.List[System.Object]") -or
                ($itemType -eq "System.Collections.ArrayList"))
            {
                $strMessage += (Format-LogMessage($item)) + " "
            } else {
                $strMessage += [String]$item + " "
            } 
        }
    } elseif (($MessageType -eq "string") -or ($MessageType -eq "System.String")) {
        $strMessage += [String]$Message + " "
    } else {
        # calls native Write-Host implementation to avoid indirect recursion scenario
        Microsoft.PowerShell.Utility\Write-Host "Unexpected MessageType $MessageType" -ForegroundColor Red
        Microsoft.PowerShell.Utility\Write-Error "Unexpected MessageType $MessageType"
    }
    
    return $strMessage
    
}

function Initialize-Log()
{
<#
    .SYNOPSIS
        Initialize-Log creates the log file in right directory and sets global reference to StreamWriter object

    .DESCRIPTION
        Initialize-Log creates the log file in right directory and sets global reference to StreamWriter object

    .EXAMPLE
        Initialize-Log
        Initialize-Log "C:\temp\" "mylog.txt"
        Initialize-Log -LogFileName "mylog.txt" # creates the log in current folder
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$LogFilePath = "./",

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$LogFileName = "##SQLLOGSCOUT_CONSOLE.LOG"

    )

    #Safe to call Write-LogDebug because we will buffer the log entries while log is not initialized
    Write-LogDebug "inside" $MyInvocation.MyCommand
    
    try
    {
        # if $global:consoleLogStream does not exists it means the log has not been initialized yet
        if ( -not(Get-Variable -Name logstream -Scope global -ErrorAction SilentlyContinue) ){
            
            #create a new folder if not already there - TODO: perhaps check if there Test-Path(), and only then create a new one
            New-Item -Path $LogFilePath -ItemType Directory -Force | out-null 
            
            #create the file and keep a reference to StreamWriter
            $full_log_file_path = $LogFilePath + $LogFileName
            Write-LogInformation "Creating log file $full_log_file_path"
            $global:consoleLogStream = New-Object -TypeName System.IO.StreamWriter -ArgumentList ($full_log_file_path, $false, [System.Text.Encoding]::ASCII)

            if ($LogFileName -like "*CONSOLE*"){
                # if the log file name contains the word CONSOLE we just replace by DEBUG
                $LogFileName = ($LogFileName -replace "CONSOLE", "DEBUG")
            } else {
                # otherwise just append _DEBUG.LOG to the name
                $LogFileName = $LogFileName.Split(".")[0]+"_DEBUG.LOG"
            }

            $full_log_file_path = $LogFilePath + $LogFileName
            Write-LogInformation "Creating debug log file $full_log_file_path"
            $global:debugLogStream = New-Object -TypeName System.IO.StreamWriter -ArgumentList ($full_log_file_path, $false, [System.Text.Encoding]::ASCII)
            
            # before we create the long-term debug log
            # we prune these files leaving only the 9 most recent ones
            # after that we create the 10th
            Write-LogDebug "Pruning older SQL LogScout DEBUG Logs in $env:TEMP" -DebugLogLevel 1
            $LogFileName = ($LogFileName -replace "_DEBUG.LOG", ("_DEBUG_*.LOG"))
            $FilesToDelete = (Get-ChildItem -Path ($env:TEMP + "\" + $LogFileName) | Sort-Object -Property LastWriteTime -Descending | Select-Object -Skip 9)
            $NumFilesToDelete = $FilesToDelete.Count

            Write-LogDebug "Found $NumFilesToDelete older SQL LogScout DEBUG Logs" -DebugLogLevel 2

            # if we have files to delete
            if ($NumFilesToDelete -gt 0) {
                $FilesToDelete | ForEach-Object {
                    $FullFileName = $_.FullName
                    Write-LogDebug "Attempting to remove file: $FullFileName" -DebugLogLevel 5
                    try {
                        Remove-Item $_
                    } catch {
                        Write-Error -Exception $_.Exception
                    }
                }
            }

            # determine the name of the long-term debug log
            $LogFileName = ($LogFileName -replace "_DEBUG_\*.LOG", ("_DEBUG_" + @(Get-Date -Format  "yyyyMMddTHHmmssffff") + ".LOG"))
            
            # create the long-term debug log and keep a reference to it
            $full_log_file_path = $env:TEMP + "\" + $LogFileName
            Write-LogInformation "Creating long term debug log file $full_log_file_path"
            $global:ltDebugLogStream = New-Object -TypeName System.IO.StreamWriter -ArgumentList ($full_log_file_path, $false, [System.Text.Encoding]::ASCII)
            
            #if we buffered log messages while log was not initialized, now we need to write them
            if ($null -ne $global:consoleLogBuffer){
                foreach ($Message in $global:consoleLogBuffer) {
                    $global:consoleLogStream.WriteLine([String]$Message)
                }
                $global:consoleLogStream.Flush()
            }

            if ($null -ne $global:debugLogBuffer){
                foreach ($Message in $global:debugLogBuffer) {
                    $global:debugLogStream.WriteLine([String]$Message)
                    $global:ltDebugLogStream.WriteLine([String]$Message)
                }
                $global:debugLogStream.Flush()
                $global:ltDebugLogStream.Flush()
            }

            Write-LogInformation "Log initialization complete!"

        } else { #if the log has already been initialized then throw an error
            Write-LogError "Attempt to initialize log already initialized!"
        }
    }
    catch
    {
		#Write-Error -Exception $_.Exception
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem  -exit_logscout $true
    }

}

function Write-Log()
{
<#
    .SYNOPSIS
        Write-Log will write message to log file and console

    .DESCRIPTION
        Write-Log will write message to log file and console.
        Should NOT be called directly, use wrapper functions such as Write-LogInformation, Write-LogWarning, Write-LogError, Write-LogDebug

    .PARAMETER Message
        Message string to be logged

    .PARAMETER ForegroundColor
        Color of the message to be displayed in console

    .EXAMPLE
        Should NOT be called directly, use wrapper functions such as Write-LogInformation, Write-LogWarning, Write-LogError, Write-LogDebug        
#>
    [CmdletBinding()]
    param ( 
        [Parameter(Mandatory,ValueFromRemainingArguments)] 
        [ValidateNotNull()]
        [Object]$Message,

        [Parameter(Mandatory)]
        [ValidateSet("INFO", "WARN", "ERROR", "DEBUG1", "DEBUG2", "DEBUG3", "DEBUG4", "DEBUG5")]
        [String]$LogType,

        [Parameter()]
        [ValidateNotNull()]
        [System.ConsoleColor]$ForegroundColor,

        [Parameter()]
        [ValidateNotNull()]
        [System.ConsoleColor]$BackgroundColor
    )

    try
    {
        [String]$strMessage = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $strMessage += "	"
        $strMessage += $LogType
        $strMessage += "	"
        $strMessage += Format-LogMessage($Message)
        
        # all non-debug messages are now logged to console log
        if ($LogType -in("INFO", "WARN", "ERROR")) {

            if ($null -ne $global:consoleLogStream)
            {
                #if log was initialized we just write $Message to it
                $stream = [System.IO.StreamWriter]$global:consoleLogStream
                $stream.WriteLine($strMessage)
                $stream.Flush() #this is necessary to ensure all log is written in the event of Powershell being forcefuly terminated
            } else {
                #because we may call Write-Log before log has been initialized, I will buffer the contents then dump to log on initialization
                
                $global:consoleLogBuffer += ,$strMessage
            }
        }

        # log both debug and non-debug messages to debug log
        if (($null -ne $global:debugLogStream) -and ($null -ne $global:ltDebugLogStream))
        {
            #if log was initialized we just write $Message to it
            $stream = [System.IO.StreamWriter]$global:debugLogStream
            $stream.WriteLine($strMessage)
            $stream.Flush() #this is necessary to ensure all log is written in the event of Powershell being forcefuly terminated

            #then repeat for long term debug log as well
            $stream = [System.IO.StreamWriter]$global:ltDebugLogStream
            $stream.WriteLine($strMessage)
            $stream.Flush() #this is necessary to ensure all log is written in the event of Powershell being forcefuly terminated

        } else {
            #because we may call Write-Log before log has been initialized, I will buffer the contents then dump to log on initialization
            
            $global:debugLogBuffer += ,$strMessage
        }
        
        if ($LogType -like "DEBUG*"){
            $dbgLevel = [int][string]($LogType[5])
        } else {
            $dbgLevel = 0
        }

        if (($LogType -in("INFO", "WARN", "ERROR")) -or
            ($dbgLevel -le $global:DEBUG_LEVEL)) {
            #Write-Host $strMessage -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
            if (($null -eq $ForegroundColor) -and ($null -eq $BackgroundColor)) { #both colors null
                Microsoft.PowerShell.Utility\Write-Host $strMessage
            } elseif (($null -ne $ForegroundColor) -and ($null -eq $BackgroundColor)) { #only foreground
                Microsoft.PowerShell.Utility\Write-Host $strMessage -ForegroundColor $ForegroundColor
            } elseif (($null -eq $ForegroundColor) -and ($null -ne $BackgroundColor)) { #only bacground
                Microsoft.PowerShell.Utility\Write-Host $strMessage -BackgroundColor $BackgroundColor
            } elseif (($null -ne $ForegroundColor) -and ($null -ne $BackgroundColor)) { #both colors not null
                Microsoft.PowerShell.Utility\Write-Host $strMessage -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
            }
        }
    }
	catch
	{
		HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
	}
    
}

function Write-LogInformation()
{
<#
    .SYNOPSIS
        Write-LogInformation is a wrapper to Write-Log standardizing console color output

    .DESCRIPTION
        Write-LogInformation is a wrapper to Write-Log standardizing console color output

    .PARAMETER Message
        Message string to be logged

    .EXAMPLE
        Write-LogInformation "Log Initialized. No user action required."
#>
[CmdletBinding()]
param ( 
        [Parameter(Position=0,Mandatory,ValueFromRemainingArguments)] 
        [ValidateNotNull()]
        [Object]$Message,

        [Parameter()]
        [ValidateNotNull()]
        [System.ConsoleColor]$ForegroundColor,

        [Parameter()]
        [ValidateNotNull()]
        [System.ConsoleColor]$BackgroundColor
    )

    try 
    {
        if (($null -eq $ForegroundColor) -and ($null -eq $BackgroundColor)) { #both colors null
            Write-Log -Message $Message -LogType "INFO"
        } elseif (($null -ne $ForegroundColor) -and ($null -eq $BackgroundColor)) { #only foreground
            Write-Log -Message $Message -LogType "INFO" -ForegroundColor $ForegroundColor
        } elseif (($null -eq $ForegroundColor) -and ($null -ne $BackgroundColor)) { #only bacground
            Write-Log -Message $Message -LogType "INFO" -BackgroundColor $BackgroundColor
        } elseif (($null -ne $ForegroundColor) -and ($null -ne $BackgroundColor)) { #both colors not null
            Write-Log -Message $Message -LogType "INFO" -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
        }
    }
    catch 
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
    }
    
}

function Write-LogWarning()
{
<#
    .SYNOPSIS
        Write-LogWarning is a wrapper to Write-Log standardizing console color output

    .DESCRIPTION
        Write-LogWarning is a wrapper to Write-Log standardizing console color output

    .PARAMETER Message
        Message string to be logged

    .EXAMPLE
        Write-LogWarning "Sample warning."
#>
[CmdletBinding()]
param ( 
        [Parameter(Mandatory,ValueFromRemainingArguments)] 
        [ValidateNotNull()]
        [Object]$Message
    )

    Write-Log -Message $Message -LogType "WARN" -ForegroundColor Yellow
}

function Write-LogError()
{
<#
    .SYNOPSIS
        Write-LogError is a wrapper to Write-Log standardizing console color output

    .DESCRIPTION
        Write-LogError is a wrapper to Write-Log standardizing console color output

    .PARAMETER Message
        Message string to be logged

    .EXAMPLE
        Write-LogError "Error connecting to SQL Server instance"
#>
[CmdletBinding()]
param ( 
        [Parameter(Mandatory,ValueFromRemainingArguments)] 
        [ValidateNotNull()]
        [Object]$Message
    )

    Write-Log -Message $Message -LogType "ERROR" -ForegroundColor Red -BackgroundColor Black
}

function Write-LogDebug()
{
<#
    .SYNOPSIS
        Write-LogDebug is a wrapper to Write-Log standardizing console color output
        Logging of debug messages will be skip if debug logging is disabled.

    .DESCRIPTION
        Write-LogDebug is a wrapper to Write-Log standardizing console color output
        Logging of debug messages will be skip if debug logging is disabled.

    .PARAMETER Message
        Message string to be logged

    .PARAMETER DebugLogLevel
        Optional - Level of the debug message ranging from 1 to 5.
        When ommitted Level 1 is assumed.

    .EXAMPLE
        Write-LogDebug "Inside" $MyInvocation.MyCommand -DebugLogLevel 2
#>
[CmdletBinding()]
    param ( 
        [Parameter(Position=0,Mandatory,ValueFromRemainingArguments)] 
        [ValidateNotNull()]
        $Message,

        [Parameter()]
        [ValidateRange(1,5)]
        [Int]$DebugLogLevel
    )

    #when $DebugLogLevel is not specified we assume it is level 1
    #this is to avoid having to refactor all calls to Write-LogDebug because of new parameter
    if(($null -eq $DebugLogLevel) -or (0 -eq $DebugLogLevel)) {$DebugLogLevel = 1}

    try
    {

        #log message if debug logging is enabled and
        #debuglevel of the message is less than or equal to global level
        #otherwise we just skip calling Write-Log
        # if(($global:DEBUG_LEVEL -gt 0) -and ($DebugLogLevel -le $global:DEBUG_LEVEL))
        # {
            Write-Log -Message $Message -LogType "DEBUG$DebugLogLevel" -ForegroundColor Magenta
            return #return here so we don't log messages twice if both debug flags are enabled
        # }
        
    } 
    
    catch 
    {
        HandleCatchBlock -function_name $($MyInvocation.MyCommand) -err_rec $PSItem
    }
}

# SIG # Begin signature block
# MIIoPgYJKoZIhvcNAQcCoIIoLzCCKCsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBcbd74OPGZ/l+E
# DOAV6yESDzY+aJSm6a07KyNcwp1BGKCCDYUwggYDMIID66ADAgECAhMzAAADri01
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
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAAw
# ZOJL4ZDua9gqf/2kMDnKq0W9WKewgWO/YUzvMeWQMEQGCisGAQQBgjcCAQwxNjA0
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEcgBpodHRwczovL3d3d3cubWljcm9zb2Z0
# LmNvbTANBgkqhkiG9w0BAQEFAASCAQCanxXybBQFWcJ2jOxl8L2kNbfRPwP47n/X
# R2lVx7Ttg191HEWf4zeQodIktEniPpOXPwIA2c/XMpBeI+5q+mKsfIFx9p8I9OVu
# cHGPgqQcVdXWN9XqzfPAkJbj6za4MII/gxGkg4/zQx2A7NqQ/ejrLeMWoQm1+DXA
# MweXHdJUfHs0dBu7w1n1KgL3ru7PuyZ+iaS2wRKBMjgoo+PHpXNKE5p1GomLA3Mi
# HbhFVBgGzRHgPE7B+jYh+LfIA63wIXlGeVefKLOQvUH22MzAYw3yjWlEwgdmKxmi
# SmR3whmw2/i3phCSG0qbb67PhlHVb53Oei6Zoh1UHlh7RqHJB9BzoYIXlzCCF5MG
# CisGAQQBgjcDAwExgheDMIIXfwYJKoZIhvcNAQcCoIIXcDCCF2wCAQMxDzANBglg
# hkgBZQMEAgEFADCCAVIGCyqGSIb3DQEJEAEEoIIBQQSCAT0wggE5AgEBBgorBgEE
# AYRZCgMBMDEwDQYJYIZIAWUDBAIBBQAEINnqYBHsC3hxsIz/qv2RZwHTJSGiaSo/
# JxzpethTzuIIAgZlzgV2+v0YEzIwMjQwMjE2MDkwMDQwLjEwOVowBIACAfSggdGk
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
# CQMxDQYLKoZIhvcNAQkQAQQwLwYJKoZIhvcNAQkEMSIEIOoRlB8BCFpnSRH2RrCd
# ovRuB3QllbKkp2Yc66cJrqLfMIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCBvQQg
# zrdrvl9pA+F/xIENO2TYNJSAht2LNezPvqHUl2EsLPgwgZgwgYCkfjB8MQswCQYD
# VQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEe
# MBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3Nv
# ZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAevgGGy1tu847QABAAAB6zAiBCB1
# hOajD+4rIhZVH8EsSDCdCVVKoJPF+xne8d4QdcKZ0TANBgkqhkiG9w0BAQsFAASC
# AgCatg4o8Q+2bwX91GWifaN5V19MNpJXxeNaXHhQBp61Qfbgx80lmw6H+S43NxFu
# Bnhqn0e/eoZQBoHPoZChR5+xjr8LaoDe1eB9k45a6xqNfC9MiHlCpi0LbY+S0lFB
# 3QCHz6Syk9B+L3pq4rqrnIj3/wLoLi2N1rvDo/aIvVTZULBFLqEnSvuBEUEIuXGb
# BOJsqLDzpYBwLzU9JjyX1r3QNaedXNa0DkxbrFijtFEKncmMdpmZi9DVlFJBDatz
# khEruxw+q6ExaR1QojKbWO2FQd9cbHESKAEnabfBd60dbiU/OGoGQHAs5W0ir+pq
# k6U4WVg+bsPyzCQ2gs4LfPtEebTWJADEKeQgp9UUJv55G2aSrsGlIiypnubNOAXd
# CqXp0wspjI4aou1awWXg5XsjKbB3B6rTAs1MaW4UAbwx+d4Hkoab8DFYnbGozWZD
# +y+H/qNMxt4qm1yIl5zUcIFW7Z42LcYkZLliV44INZ0qd9u1dw/gXAwAh/akda9O
# EKFf61dW7/f628/B2zcZAMztyoqVuzeaivzM+84vsSslf67eoKh6THjTIP804+PG
# C/RzrlBgG56ZY0X/IfegA4c/pUwV5jrh1D80aIh6N3yI0qwFfBRTkyLSlZWA0jwC
# V5kHHort21CaFGHiA/jRQqJheuFzdaAxGBVl+aUHq4mVbQ==
# SIG # End signature block
