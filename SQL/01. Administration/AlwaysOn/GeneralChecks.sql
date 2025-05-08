------------------------------------------------------------------------

DECLARE @varPrimary NVARCHAR(25)

IF SERVERPROPERTY ('IsHadrEnabled') = 1
BEGIN
	SELECT
		@varPrimary = ARS.role_desc
	FROM sys.availability_groups_cluster AS AGC
	JOIN sys.dm_hadr_availability_replica_cluster_states AS RCS
	ON	 RCS.group_id = AGC.group_id
	JOIN sys.dm_hadr_availability_replica_states AS ARS
	ON   ARS.replica_id = RCS.replica_id
	JOIN sys.availability_group_listeners AS AGL
	ON   AGL.group_id = ARS.group_id
	WHERE ARS.role_desc = 'PRIMARY'
END

-- SELECT ISNULL(@varPrimary, 'SECONDARY')

IF @varPrimary = 'PRIMARY'
BEGIN 
	-- USE [DBA]
	EXECUTE [DBA].[dbo].[IndexOptimize] 
		  @Databases			  = 'USER_DATABASES'
		, @LogToTable			  = 'Y'
		, @UpdateStatistics		  = 'ALL'
		, @OnlyModifiedStatistics = 'Y'
END
ELSE
BEGIN
	SELECT 'Did not Run'
END