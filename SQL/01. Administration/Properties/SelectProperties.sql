
--/***********************************************************************************************************
--Ref:
--    https://docs.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver15
--***********************************************************************************************************/

-- Script 1
-- Server level
-- https://learn.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver16

CREATE TABLE #tmpConfigurationProperties
(
	  ServerName	SYSNAME
	, PropertyName	NVARCHAR(125)
	, Minimum		BIGINT
	, Maximum		BIGINT
	, ConfigValue	NVARCHAR(125)
	, RunValue		NVARCHAR(125)
)

INSERT INTO #tmpConfigurationProperties
SELECT *
FROM (
				SELECT CONVERT(NVARCHAR, 'BuildClrVersion')			    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR, SERVERPROPERTY('BuildClrVersion')) AS ConfigValue, 0 AS RunValue 
		UNION	SELECT CONVERT(NVARCHAR, 'Collation')				    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('Collation')), 0 AS RunValue 
		UNION	SELECT CONVERT(NVARCHAR, 'CollationID')				    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('CollationID')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'ComparisonStyle')			    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('ComparisonStyle')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'ComputerNamePhysicalNetBIOS') AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('ComputerNamePhysicalNetBIOS')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'Edition')					    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('Edition')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'EditionID')				    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('EditionID')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'EngineEdition')			    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('EngineEdition')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'HadrManagerStatus')		    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('HadrManagerStatus')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'InstanceDefaultDataPath')	    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('InstanceDefaultDataPath')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'InstanceDefaultLogPath')	    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('InstanceDefaultLogPath')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'InstanceName')				AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('InstanceName')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'IsAdvancedAnalyticsInstalled')AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('IsAdvancedAnalyticsInstalled')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'IsClustered')				    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('IsClustered')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'IsFullTextInstalled')		    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('IsFullTextInstalled')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'IsHadrEnabled')			    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('IsHadrEnabled')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'IsIntegratedSecurityOnly')    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('IsIntegratedSecurityOnly')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'IsLocalDB')				    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('IsLocalDB')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'IsPolyBaseInstalled')		    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('IsPolyBaseInstalled')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'IsSingleUser')			    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('IsSingleUser')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'IsXTPSupported')			    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('IsXTPSupported')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'LCID')					    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('LCID')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'LicenseType')				    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('LicenseType')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'MachineName')				    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR, SERVERPROPERTY('MachineName')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'NumLicenses')				    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('NumLicenses')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'ProcessID')				    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('ProcessID')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'ProductBuild')			    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('ProductBuild')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'ProductBuildType')		    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('ProductBuildType')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'ProductLevel')			    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('ProductLevel')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'ProductMajorVersion')		    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('ProductMajorVersion')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'ProductMinorVersion')		    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('ProductMinorVersion')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'ProductUpdateLevel')		    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('ProductUpdateLevel')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'ProductUpdateReference')	    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('ProductUpdateReference')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'ProductVersion')			    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('ProductVersion')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'ResourceLastUpdateDateTime')  AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('ResourceLastUpdateDateTime')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'ResourceVersion')			    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('ResourceVersion')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'ServerName')				    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('ServerName')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'SqlCharSet')				    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('SqlCharSet')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'SqlCharSetName')			    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('SqlCharSetName')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'SqlSortOrder')			    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('SqlSortOrder')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'SqlSortOrderName')		    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('SqlSortOrderName')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'FilestreamShareName')		    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('FilestreamShareName')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'FilestreamConfiguredLevel')   AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('FilestreamConfiguredLevel')), 0 AS RunValue
		UNION	SELECT CONVERT(NVARCHAR, 'FilestreamEffectiveLevel')    AS PropertyName, 0 AS Minimum, 0 AS Maximum, CONVERT(NVARCHAR,SERVERPROPERTY('FilestreamEffectiveLevel')), 0 AS RunValue
	) AS A
GO

EXEC sp_configure 'Show Advanced Options', 1;
GO
RECONFIGURE;
GO

insert into #tmpConfigurationProperties
EXEC sp_configure;

SELECT * FROM #tmpConfigurationProperties

DROP TABLE IF EXISTS #tmpConfigurationProperties



---- Script 2
---- Database level
---- https://learn.microsoft.com/en-us/sql/t-sql/functions/databasepropertyex-transact-sql?view=sql-server-ver16
--DECLARE @dbname NVARCHAR(MAX) = 'DBA' 
--		SELECT 'Collation'							AS Feature, DATABASEPROPERTYEX(@dbname, 'Collation')		AS Value
--UNION	SELECT 'ComparisonStyle'					AS Feature, DATABASEPROPERTYEX(@dbname, 'ComparisonStyle')	AS Value
--UNION	SELECT 'Edition'							AS Feature, DATABASEPROPERTYEX(@dbname, 'Edition')	AS Value
--UNION	SELECT 'IsAnsiNullDefault'					AS Feature, DATABASEPROPERTYEX(@dbname, 'IsAnsiNullDefault')	AS Value
--UNION	SELECT 'IsAnsiNullsEnabled'					AS Feature, DATABASEPROPERTYEX(@dbname, 'IsAnsiNullsEnabled')	AS Value
--UNION	SELECT 'IsAnsiPaddingEnabled'				AS Feature, DATABASEPROPERTYEX(@dbname, 'IsAnsiPaddingEnabled')	AS Value
--UNION	SELECT 'IsAnsiWarningsEnabled'				AS Feature, DATABASEPROPERTYEX(@dbname, 'IsAnsiWarningsEnabled')	AS Value
--UNION	SELECT 'IsArithmeticAbortEnabled'			AS Feature, DATABASEPROPERTYEX(@dbname, 'IsArithmeticAbortEnabled')	AS Value
--UNION	SELECT 'IsAutoClose'						AS Feature, DATABASEPROPERTYEX(@dbname, 'IsAutoClose')	AS Value
--UNION	SELECT 'IsAutoCreateStatistics'				AS Feature, DATABASEPROPERTYEX(@dbname, 'IsAutoCreateStatistics')	AS Value
--UNION	SELECT 'IsAutoCreateStatisticsIncremental'	AS Feature, DATABASEPROPERTYEX(@dbname, 'IsAutoCreateStatisticsIncremental')	AS Value
--UNION	SELECT 'IsAutoShrink'						AS Feature, DATABASEPROPERTYEX(@dbname, 'IsAutoShrink')	AS Value
--UNION	SELECT 'IsAutoUpdateStatistics'				AS Feature, DATABASEPROPERTYEX(@dbname, 'IsAutoUpdateStatistics')	AS Value
--UNION	SELECT 'IsClone'							AS Feature, DATABASEPROPERTYEX(@dbname, 'IsClone')	AS Value
--UNION	SELECT 'IsCloseCursorsOnCommitEnabled'		AS Feature, DATABASEPROPERTYEX(@dbname, 'IsCloseCursorsOnCommitEnabled')	AS Value
--UNION	SELECT 'IsFulltextEnabled'					AS Feature, DATABASEPROPERTYEX(@dbname, 'IsFulltextEnabled')	AS Value
--UNION	SELECT 'IsInStandBy'						AS Feature, DATABASEPROPERTYEX(@dbname, 'IsInStandBy')	AS Value
--UNION	SELECT 'IsLocalCursorsDefault'				AS Feature, DATABASEPROPERTYEX(@dbname, 'IsLocalCursorsDefault')	AS Value
--UNION	SELECT 'IsMemoryOptimizedElevateToSnapshotEnabled' AS Feature, DATABASEPROPERTYEX(@dbname, 'IsMemoryOptimizedElevateToSnapshotEnabled')	AS Value
--UNION	SELECT 'IsMergePublished'					AS Feature, DATABASEPROPERTYEX(@dbname, 'IsMergePublished')	AS Value
--UNION	SELECT 'IsNullConcat'						AS Feature, DATABASEPROPERTYEX(@dbname, 'IsNullConcat')	AS Value
--UNION	SELECT 'IsNumericRoundAbortEnabled'			AS Feature, DATABASEPROPERTYEX(@dbname, 'IsNumericRoundAbortEnabled')	AS Value
--UNION	SELECT 'IsParameterizationForced'			AS Feature, DATABASEPROPERTYEX(@dbname, 'IsParameterizationForced')	AS Value
--UNION	SELECT 'IsQuotedIdentifiersEnabled'			AS Feature, DATABASEPROPERTYEX(@dbname, 'IsQuotedIdentifiersEnabled')	AS Value
--UNION	SELECT 'IsPublished'						AS Feature, DATABASEPROPERTYEX(@dbname, 'IsPublished')	AS Value
--UNION	SELECT 'IsRecursiveTriggersEnabled'			AS Feature, DATABASEPROPERTYEX(@dbname, 'IsRecursiveTriggersEnabled')	AS Value
--UNION	SELECT 'IsSyncWithBackup'					AS Feature, DATABASEPROPERTYEX(@dbname, 'IsSyncWithBackup')	AS Value
--UNION	SELECT 'IsTornPageDetectionEnabled'			AS Feature, DATABASEPROPERTYEX(@dbname, 'IsTornPageDetectionEnabled')	AS Value
--UNION	SELECT 'IsVerifiedClone'					AS Feature, DATABASEPROPERTYEX(@dbname, 'IsVerifiedClone')	AS Value
--UNION	SELECT 'IsXTPSupported'						AS Feature, DATABASEPROPERTYEX(@dbname, 'IsXTPSupported')	AS Value
--UNION	SELECT 'LastGoodCheckDbTime'				AS Feature, DATABASEPROPERTYEX(@dbname, 'LastGoodCheckDbTime')	AS Value
--UNION	SELECT 'LCID'								AS Feature, DATABASEPROPERTYEX(@dbname, 'LCID')	AS Value
--UNION	SELECT 'MaxSizeInBytes'						AS Feature, DATABASEPROPERTYEX(@dbname, 'MaxSizeInBytes')	AS Value
--UNION	SELECT 'Recovery'							AS Feature, DATABASEPROPERTYEX(@dbname, 'Recovery')	AS Value
--UNION	SELECT 'ServiceObjective'					AS Feature, DATABASEPROPERTYEX(@dbname, 'ServiceObjective')	AS Value
--UNION	SELECT 'ServiceObjectiveId'					AS Feature, DATABASEPROPERTYEX(@dbname, 'ServiceObjectiveId')	AS Value
--UNION	SELECT 'SQLSortOrder'						AS Feature, DATABASEPROPERTYEX(@dbname, 'SQLSortOrder')	AS Value
--UNION	SELECT 'Status'								AS Feature, DATABASEPROPERTYEX(@dbname, 'Status')	AS Value
--UNION	SELECT 'Updateability'						AS Feature, DATABASEPROPERTYEX(@dbname, 'Updateability')	AS Value
--UNION	SELECT 'UserAccess'							AS Feature, DATABASEPROPERTYEX(@dbname, 'UserAccess')	AS Value
--UNION	SELECT 'Version'							AS Feature, DATABASEPROPERTYEX(@dbname, 'Version')	AS Value
--;


--declare @dbname varchar(max)='dba' 
--select 
--	'name' as feature
--,   cast(name as sql_variant) as " value" from sys.databases where name=@dbname 
--union select 'database_id', cast(database_id as sql_variant) as " value" from sys.databases where name=@dbname 
--union select 'source_database_id', cast(source_database_id as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'owner_sid', cast(user_name(owner_sid) as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'create_date', cast(create_date as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'compatibility_level', cast(compatibility_level as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'collation_name', cast(collation_name as sql_variant) as " value" from sys.databases where name=@dbname 
--union select 'user_access', cast(user_access as sql_variant) as " value" from sys.databases where name=@dbname 
--union select 'user_access_desc', cast(user_access_desc as sql_variant) as " value" from sys.databases where name=@dbname 
--union select 'is_read_only', cast(is_read_only as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_auto_close_on', cast(is_auto_close_on as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_auto_shrink_on', cast(is_auto_shrink_on as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'state', cast(state as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'state_desc', cast(state_desc as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_in_standby', cast(is_in_standby as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_cleanly_shutdown', cast(is_cleanly_shutdown as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_supplemental_logging_enabled', cast(is_supplemental_logging_enabled as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'snapshot_isolation_state', cast(snapshot_isolation_state as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'snapshot_isolation_state_desc', cast(snapshot_isolation_state_desc as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_read_committed_snapshot_on', cast(is_read_committed_snapshot_on as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'recovery_model', cast(recovery_model as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'recovery_model_desc', cast(recovery_model_desc as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'page_verify_option', cast(page_verify_option as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'page_verify_option_desc', cast(page_verify_option_desc as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_auto_create_stats_on', cast(is_auto_create_stats_on as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_auto_create_stats_incremental_on', cast(is_auto_create_stats_incremental_on as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_auto_update_stats_on', cast(is_auto_update_stats_on as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_auto_update_stats_async_on', cast(is_auto_update_stats_async_on as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_ansi_null_default_on', cast(is_ansi_null_default_on as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_ansi_nulls_on', cast(is_ansi_nulls_on as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_ansi_padding_on', cast(is_ansi_padding_on as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_ansi_warnings_on', cast(is_ansi_warnings_on as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_arithabort_on', cast(is_arithabort_on as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_concat_null_yields_null_on', cast(is_concat_null_yields_null_on as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_numeric_roundabort_on', cast(is_numeric_roundabort_on as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_quoted_identifier_on', cast(is_quoted_identifier_on as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_recursive_triggers_on', cast(is_recursive_triggers_on as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_cursor_close_on_commit_on', cast(is_cursor_close_on_commit_on as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_local_cursor_default', cast(is_local_cursor_default as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_fulltext_enabled', cast(is_fulltext_enabled as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_trustworthy_on', cast(is_trustworthy_on as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_db_chaining_on', cast(is_db_chaining_on as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_parameterization_forced', cast(is_parameterization_forced as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_master_key_encrypted_by_server', cast(is_master_key_encrypted_by_server as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_query_store_on', cast(is_query_store_on as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_published', cast(is_published as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_subscribed', cast(is_subscribed as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_merge_published', cast(is_merge_published as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_distributor', cast(is_distributor as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_sync_with_backup', cast(is_sync_with_backup as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'service_broker_guid', cast(service_broker_guid as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_broker_enabled', cast(is_broker_enabled as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'log_reuse_wait', cast(log_reuse_wait as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'log_reuse_wait_desc', cast(log_reuse_wait_desc as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_date_correlation_on', cast(is_date_correlation_on as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_cdc_enabled', cast(is_cdc_enabled as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_encrypted', cast(is_encrypted as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_honor_broker_priority_on', cast(is_honor_broker_priority_on as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'replica_id', cast(replica_id as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'group_database_id', cast(group_database_id as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'resource_pool_id', cast(resource_pool_id as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'default_language_lcid', cast(default_language_lcid as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'default_language_name', cast(default_language_name as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'default_fulltext_language_lcid', cast(default_fulltext_language_lcid as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'default_fulltext_language_name', cast(default_fulltext_language_name as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_nested_triggers_on', cast(is_nested_triggers_on as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_transform_noise_words_on', cast(is_transform_noise_words_on as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'two_digit_year_cutoff', cast(two_digit_year_cutoff as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'containment', cast(containment as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'containment_desc', cast(containment_desc as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'target_recovery_time_in_seconds', cast(target_recovery_time_in_seconds as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'delayed_durability', cast(delayed_durability as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'delayed_durability_desc', cast(delayed_durability_desc as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_memory_optimized_elevate_to_snapshot_on', cast(is_memory_optimized_elevate_to_snapshot_on as varchar(60)) as " value" from sys.databases where name=@dbname
--union select 'is_federation_member', cast(is_federation_member as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_remote_data_archive_enabled', cast(is_remote_data_archive_enabled as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_mixed_page_allocation_on', cast(is_mixed_page_allocation_on as sql_variant) as " value" from sys.databases where name=@dbname
--union select 'is_temporal_history_retention_enabled', cast(is_temporal_history_retention_enabled as varchar(70)) as " value" from sys.databases where name=@dbname
