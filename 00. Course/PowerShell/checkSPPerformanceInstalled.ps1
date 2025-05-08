<# ##################################################################################################################################################
    Date        : 24/03/2025
    Owner       : DMT DBA Group
    Function    : Check performance Stored Procedure installed on DBA database
	Improvement : 
# ##################################################################################################################################################>

<# ##################################################################################################################################################
    Section Install module
# ##################################################################################################################################################>

#region InstallModule
#Install SqlServer Module
Function InstallSqlServerModule {
	param (
		[string] $parServerName = $SQLServerName
	)

	try {
		Install-Module -Name SqlServer -AllowClobber
		Import-Module -Name SqlServer
		Write-Host "### SqlServer module was installed and imported successfully on [$parServerName]." -ForegroundColor Green
	}
	catch {
		Write-Host "### SqlServer Module installation failed on [$parServerName]. Please contact the Administrator'." -ForegroundColor Red
		exit 1
	}
}
#endregion InstallModule

#region Create conn to the SQL
Function ExecuteSqlCommand {
	param
	( 
		[Parameter(Position=0, Mandatory=$true)]  [string] $parSQLScript,
		[Parameter(Position=2, Mandatory=$false)] [string] $parServerName = ".",
		[Parameter(Position=3, Mandatory=$false)] [string] $databaseName = "DBA",
		[Parameter(Position=4, Mandatory=$false)] [string] $parDomainName = $parDomainName,
		[Parameter(Position=5)] [string] $parUserName = $varUserName
	)

	# If Domain is CLIENT and User is INM\cT12317
	if ($parDomainName -eq 'CLIENT') {
		$uid = 'CLIENT\svcDMTSQLUpgrade'
		$varPwd = 'ecaPa2pdtS(6<}m7'

		$connCLIENT = New-Object System.Data.SqlClient.SqlConnection("Server=$parServerName;DataBase=$databaseName;User ID=$uid;Password =$varPwd;")
		$sqlCommandCLIENT = New-Object System.Data.SqlClient.SqlCommand
		$sqlCommandCLIENT.Connection = $connCLIENT
		$sqlCommandCLIENT.CommandType = [System.Data.CommandType]'Text'
		$sqlCommandCLIENT.CommandTimeout = 300

		try
		{
			$connCLIENT.Open() | out-null         
			$sqlCommandCLIENT.CommandText = $parSQLScript
			$sqlCommandCLIENT.ExecuteNonQuery() | Out-Null
			$strResult = "Command(s) completed successfully."
			
		}
		catch [System.Exception]
		{
			$strResult = $_
		}
		finally
		{
			if ($connCLIENT.State -ne [System.Data.ConnectionState]'Closed')
			{
				$connCLIENT.Close()
				$connCLIENT.Dispose()
			}
		} return $strResult
	} 
	# If Domain is INMAR
	elseif ($parDomainName -eq 'INMAR') 
	{
			# Command for INMAR
			$connINMAR = New-Object System.Data.SqlClient.SqlConnection("Server=$parServerName;DataBase=$databaseName;Integrated Security=SSPI;")
			$sqlCommandINMAR = New-Object System.Data.SqlClient.SqlCommand
			$sqlCommandINMAR.Connection = $connINMAR
			$sqlCommandINMAR.CommandType = [System.Data.CommandType]'Text'
			$sqlCommandINMAR.CommandTimeout = 300
	
			try
			{
				$connINMAR.Open() | out-null         
				$sqlCommandINMAR.CommandText = $parSQLScript
				$sqlCommandINMAR.ExecuteNonQuery() | Out-Null
				$strResult = "Command(s) completed successfully."
			}
			catch [System.Exception]
			{
				$strResult = $_
			}
			finally
			{
				if ($connINMAR.State -ne [System.Data.ConnectionState]'Closed')
				{
					$connINMAR.Close()
					$connINMAR.Dispose()
				}
			} return $strResult			
	}
}
#endregion Create conn to the SQL

#region CheckPerformanceSPInstalled
Function CheckPerformanceSPInstalled {
    param (
        [string]$parServerName
    )

    # List of stored procedures to check
    $storedProcedures = @(
        'sp_Blitz', 'sp_BlitzAnalysis', 'sp_BlitzBackups', 'sp_BlitzCache',
        'sp_BlitzFirst', 'sp_BlitzIndex', 'sp_BlitzLock', 'sp_BlitzQueryStore',
        'sp_BlitzWho', 'sp_whoisactive'
    )

    # Check if SQL Server module is installed
    if (-not (Get-Module -Name SqlServer -ListAvailable)) {
        Write-Host "### The SqlServer module is not installed. Please install it using 'Install-Module -Name SqlServer' ###" -ForegroundColor Red
        exit
    }

    # Check if the DBA database exists
    $queryCheckDB = "SELECT COUNT(*) FROM sys.databases WHERE name = 'DBA'"
    $dbExists = Invoke-Sqlcmd -ServerInstance $parServerName -Query $queryCheckDB -ErrorAction Stop

    if ($dbExists.Column1 -eq 0) {
        Write-Host "### The 'DBA' database does not exist on server '$parServerName'. Execution stopped ###" -ForegroundColor Red
        exit
    }

    # Message the DBA db exists.
    Write-Host "### The 'DBA' database exists. Checking stored procedures... ###" -ForegroundColor Green

    # Query to check for stored procedures in DBA database
    $queryCheckSP = @"
SELECT name FROM DBA.sys.procedures
WHERE name IN ('$(($storedProcedures -join "','"))')
"@

    $existingSPs = Invoke-Sqlcmd -ServerInstance $parServerName -Database "DBA" -Query $queryCheckSP -ErrorAction Stop
    $existingSPNames = $existingSPs.name

    # Compare the existing stored procedures with the required list
    $missingSPs = $storedProcedures | Where-Object { $_ -notin $existingSPNames }

    if ($missingSPs.Count -gt 0) {
        Write-Host "### The following stored procedures are missing in DBA database: $($missingSPs -join ', ') ###" -ForegroundColor Red
        exit
    } else {
        Write-Host "### All required stored procedures exist in the DBA database ###" -ForegroundColor Green
    }
}
#endregion CheckPerformanceSPInstalled

# ##############################################################################################
# Section Main (Update and Install functions)
# ##############################################################################################

#region Main
	# Request SQL Server
	$SQLServerName  = Read-Host -Prompt "Please introduce the SQL Server Name"

    # InstalldbatoolsModule
	InstalldbatoolsModule -parServerName $SQLServerName

    # CheckPerformanceSPInstalled
    CheckPerformanceSPInstalled -parServerName $SQLServerName
#endregion Main
