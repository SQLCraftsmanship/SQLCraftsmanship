
/******************************************************************************************************************************
Date	: 10/05/2022
Owner	: SQL DBAs
Descrip.: This stored procedure was created to check all SQL Server properties
Ref		: https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16
Exec	: EXECUTE [dbo].[CheckSQLServerConfigurationProperties]
******************************************************************************************************************************/

DROP PROCEDURE IF EXISTS [dbo].[CheckSQLServerConfigurationProperties]
GO

CREATE PROC [dbo].[CheckSQLServerConfigurationProperties]
AS
BEGIN

	DROP TABLE IF EXISTS #tmpConfigurationProperties

	CREATE TABLE #tmpConfigurationProperties
	(
		  Id			INT IDENTITY (1,1) NOT NULL 
		, ServerName	SYSNAME  NULL
		, Date			DATETIME NULL
		, PropertyName	NVARCHAR(125)
		, Minimum		BIGINT
		, Maximum		BIGINT
		, ConfigValue	NVARCHAR(125)
		, RunValue		NVARCHAR(125)
		, PropertiDescription NVARCHAR(MAX)
		, URL			NVARCHAR(255)
	)

	DECLARE @ServerName SYSNAME = CONVERT(NVARCHAR,SERVERPROPERTY('ServerName'))
		  , @Date	DATETIME	= GETDATE()


	BEGIN TRY 
		INSERT INTO #tmpConfigurationProperties
		SELECT *
		FROM (
					  SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'BuildClrVersion')			    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('BuildClrVersion')) AS ConfigValue, 0 AS RunValue, 'Version of the Microsoft.NET Framework common language runtime (CLR) that was used while building the instance of SQL Server.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'Collation')				    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('Collation')), 0 AS RunValue, 'Name of the default collation for the server.'  AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'CollationID')				    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('CollationID')), 0 AS RunValue, 'ID of the SQL Server collation.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'ComparisonStyle')			    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('ComparisonStyle')), 0 AS RunValue, 'Windows comparison style of the collation.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'ComputerNamePhysicalNetBIOS') AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('ComputerNamePhysicalNetBIOS')), 0 AS RunValue, 'NetBIOS name of the local computer on which the instance of SQL Server is currently runnin' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'Edition')					    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('Edition')), 0 AS RunValue, 'Installed product edition of the instance of SQL Server. Use the value of this property to determine the features and the limits, such as Compute Capacity Limits by Edition of SQL Server. 64-bit versions of the Database Engine append (64-bit) to the version.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'EditionID')				    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('EditionID')), 0 AS RunValue, 'EditionID represents the installed product edition of the instance of SQL Server. Use the value of this property to determine features and limits, such as Compute Capacity Limits by Edition of SQL Server.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'EngineEdition')			    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('EngineEdition')), 0 AS RunValue, 'Database Engine edition of the instance of SQL Server installed on the server.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'FilestreamConfiguredLevel')   AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('FilestreamConfiguredLevel')), 0 AS RunValue, 'The configured level of FILESTREAM access. For more information, see filestream access level.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'FilestreamEffectiveLevel')    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('FilestreamEffectiveLevel')), 0 AS RunValue, 'The effective level of FILESTREAM access. This value can be different than the FilestreamConfiguredLevel if the level has changed and either an instance restart or a computer restart is pending. For more information, see filestream access level.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'FilestreamShareName')		    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('FilestreamShareName')), 0 AS RunValue, 'The name of the share used by FILESTREAM.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'HadrManagerStatus')		    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('HadrManagerStatus')), 0 AS RunValue, 'Indicates whether the Always On availability groups manager has started.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'InstanceDefaultBackupPath')	AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('InstanceDefaultBackupPath')), 0 AS RunValue, 'Name of the default path to the instance backup files.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'InstanceDefaultDataPath')	    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('InstanceDefaultDataPath')), 0 AS RunValue, 'Name of the default path to the instance data files.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'InstanceDefaultLogPath')	    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('InstanceDefaultLogPath')), 0 AS RunValue, 'Name of the default path to the instance log files.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'InstanceName')				AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('InstanceName')), 0 AS RunValue, 'Name of the instance to which the user is connected. Returns NULL if the instance name is the default instance, if the input is not valid, or error.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'IsAdvancedAnalyticsInstalled')AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('IsAdvancedAnalyticsInstalled')), 0 AS RunValue, 'Returns 1 if the Advanced Analytics feature was installed during setup; 0 if Advanced Analytics was not installed.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'IsBigDataCluster')			AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('IsBigDataCluster')), 0 AS RunValue, 'Introduced in SQL Server 2019 (15.x) beginning with CU4. Returns 1 if the instance is SQL Server Big Data Cluster; 0 if not.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'IsClustered')				    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('IsClustered')), 0 AS RunValue, 'Server instance is configured in a failover cluster.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'IsExternalAuthenticationOnly')AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('IsExternalAuthenticationOnly')), 0 AS RunValue, 'Applies to: Azure SQL Database and Azure SQL Managed Instance. Returns whether Azure AD-only authentication is enabled.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'IsFullTextInstalled')		    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('IsFullTextInstalled')), 0 AS RunValue, 'The full-text and semantic indexing components are installed on the current instance of SQL Server.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'IsHadrEnabled')			    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('IsHadrEnabled')), 0 AS RunValue, 'Always On availability groups is enabled on this server instance.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'IsIntegratedSecurityOnly')    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('IsIntegratedSecurityOnly')), 0 AS RunValue, 'Server is in integrated security mode.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'IsLocalDB')				    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('IsLocalDB')), 0 AS RunValue, 'Server is an instance of SQL Server Express LocalDB.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'IsPolyBaseInstalled')		    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('IsPolyBaseInstalled')), 0 AS RunValue, 'Returns whether the server instance has the PolyBase feature installed.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'IsSingleUser')			    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('IsSingleUser')), 0 AS RunValue, '	Server is in single-user mode.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'IsTempDbMetadataMemoryOptimized')AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('IsTempDbMetadataMemoryOptimized')), 0 AS RunValue, 'Returns 1 if tempdb has been enabled to use memory-optimized tables for metadata; 0 if tempdb is using regular, disk-based tables for metadata. For more information, see tempdb Database.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'IsXTPSupported')			    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('IsXTPSupported')), 0 AS RunValue, 'Applies to: SQL Server (SQL Server 2014 (12.x) and later), SQL Database.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'LCID')					    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('LCID')), 0 AS RunValue, 'Windows locale identifier (LCID) of the collation.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'LicenseType')				    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('LicenseType')), 0 AS RunValue, 'Unused. License information is not preserved or maintained by the SQL Server product. Always returns DISABLED.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'MachineName')				    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('MachineName')), 0 AS RunValue, 'Windows computer name on which the server instance is running. For a clustered instance, an instance of SQL Server running on a virtual server on Microsoft Cluster Service, it returns the name of the virtual server.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'NumLicenses')				    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('NumLicenses')), 0 AS RunValue, 'Unused. License information is not preserved or maintained by the SQL Server product. Always returns NULL.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'PathSeparator')			    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('PathSeparator')), 0 AS RunValue, 'Returns \ on Windows and / on Linux'  AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'ProcessID')				    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('ProcessID')), 0 AS RunValue, 'Process ID of the SQL Server service. ProcessID is useful in identifying which Sqlservr.exe belongs to this instance.'  AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'ProductBuild')			    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('ProductBuild')), 0 AS RunValue, 'The build number.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'ProductBuildType')		    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('ProductBuildType')), 0 AS RunValue, 'Type of build of the current build.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'ProductLevel')			    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('ProductLevel')), 0 AS RunValue, 'Level of the version of the instance of SQL Server.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'ProductMajorVersion')		    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('ProductMajorVersion')), 0 AS RunValue, 'The major version.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'ProductMinorVersion')		    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('ProductMinorVersion')), 0 AS RunValue, 'The minor version.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'ProductUpdateLevel')		    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('ProductUpdateLevel')), 0 AS RunValue, 'Update level of the current build. CU indicates a cumulative update.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'ProductUpdateReference')	    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('ProductUpdateReference')), 0 AS RunValue, 'KB article for that release.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'ProductVersion')			    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('ProductVersion')), 0 AS RunValue, 'Version of the instance of SQL Server, in the form of major.minor.build.revision.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'ResourceLastUpdateDateTime')  AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('ResourceLastUpdateDateTime')), 0 AS RunValue, 'Returns the date and time that the Resource database was last updated.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'ResourceVersion')			    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('ResourceVersion')), 0 AS RunValue, 'Returns the version Resource database.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'ServerName')				    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('ServerName')), 0 AS RunValue, 'Both the Windows server and instance information associated with a specified instance of SQL Server.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'SqlCharSet')				    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('SqlCharSet')), 0 AS RunValue, 'The SQL character set ID from the collation ID.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'SqlCharSetName')			    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('SqlCharSetName')), 0 AS RunValue, 'The SQL character set name from the collation.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'SqlSortOrder')			    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('SqlSortOrder')), 0 AS RunValue, 'The SQL sort order ID from the collation' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
				UNION SELECT @ServerName AS ServerName, @Date AS Date, CONVERT(NVARCHAR, 'SqlSortOrderName')		    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('SqlSortOrderName')), 0 AS RunValue, 'The SQL sort order name from the collation.' AS PropertiDescription, 'https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16' AS [URL]
			) AS A

		EXEC sp_configure 'Show Advanced Options', 1;
		RECONFIGURE;

		INSERT INTO #tmpConfigurationProperties (PropertyName, Minimum, Maximum, ConfigValue, RunValue)
		EXEC sp_configure;

		UPDATE #tmpConfigurationProperties
		SET [ServerName] = CONVERT(NVARCHAR,SERVERPROPERTY('ServerName'))
		  , [Date]	   = GETDATE()
		WHERE [ServerName] IS NULL AND [Date] IS NULL

	END TRY

	BEGIN CATCH
	    SELECT  
			  ERROR_NUMBER()	AS ErrorNumber  
			, ERROR_SEVERITY()	AS ErrorSeverity  
			, ERROR_STATE()		AS ErrorState  
			, ERROR_PROCEDURE() AS ErrorProcedure  
			, ERROR_LINE()		AS ErrorLine  
			, ERROR_MESSAGE()	AS ErrorMessage;  
	END CATCH;

	SELECT 
		  Id			
		, ServerName	
		, Date			
		, PropertyName	
		, Minimum		
		, Maximum		
		, ConfigValue	
		, RunValue	
		, PropertiDescription 
		, URL	
	FROM #tmpConfigurationProperties

END;
