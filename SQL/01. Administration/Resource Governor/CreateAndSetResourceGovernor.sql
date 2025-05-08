
/********************************************************************************************
	Create Resource Governor
********************************************************************************************/
USE [master]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Create resource pool to be USED
CREATE RESOURCE POOL [ServicePool] 
WITH
	(
		min_cpu_percent		= 0, 
		max_cpu_percent		= 30, 
		min_memory_percent	= 0, 
		max_memory_percent	= 30, 
		AFFINITY SCHEDULER = AUTO
	)
GO

-- Create admin workload group
CREATE WORKLOAD GROUP [ServiceGroup] 
USING [ServicePool]
GO

-- Create admin workload group
USE master;
GO
 
CREATE FUNCTION Class_funct() 
RETURNS SYSNAME 
WITH SCHEMABINDING
AS
BEGIN
  DECLARE @workload_group sysname;

  IF (
		(SUSER_SNAME() = 'CLIENT\svc_explnwrk01') 
		OR 
		(SUSER_SNAME() = 'INM\app_rlssis_prod')
		OR
		(SUSER_SNAME() = 'CLIENT\svcCORP-EXPLNFSA')
		OR
		(SUSER_SNAME() = 'CLIENT\svcCORP-EXPLNDSH')
		OR
		(SUSER_SNAME() = 'CLIENT\svcCorpExplnFSApi')
		OR
		(SUSER_SNAME() = 'CLIENT\svcCorpExplnUserMgmt')
		OR
		(SUSER_SNAME() = 'CLIENT\svcSchedapi01')
		OR
		(SUSER_SNAME() = 'CLIENT\svcScSsrsProd')	
	 )

	  SET @workload_group = 'ServiceGroup';
     
  RETURN @workload_group;
END;


-- Set the classifier function for Resource Governor
USE master
GO
ALTER RESOURCE GOVERNOR WITH (CLASSIFIER_FUNCTION = dbo.Class_funct);
GO

-- Make changes effective
ALTER RESOURCE GOVERNOR RECONFIGURE
GO

-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------

-- Check if RG is been using
SELECT * FROM sys.resource_governor_configuration
SELECT * FROM sys.dm_resource_governor_resource_pools


USE master
GO
SELECT 
	-- ConSess.session_id
	ConSess.login_name,  WorLoGroName.name
FROM sys.dm_exec_sessions AS ConSess
JOIN sys.dm_resource_governor_workload_groups AS WorLoGroName
ON   ConSess.group_id = WorLoGroName.group_id
WHERE session_id > 60
-- AND   login_name <> 'CLIENT\svc_explnwrk01'
GROUP BY ConSess.login_name,  WorLoGroName.name;

-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------

/*
USE [master]
GO

-- Drop Workload Group
DROP WORKLOAD GROUP [ServiceGroup]
GO

-- Drop Resource Pool
DROP RESOURCE POOL [ServicePool]
GO

-- Delete Funciton
ALTER RESOURCE GOVERNOR WITH (CLASSIFIER_FUNCTION = NULL)
GO

ALTER RESOURCE GOVERNOR DISABLE
GO

DROP FUNCTION [dbo].[Class_funct]
GO

-- To do this you need to recreate the RG
-- ALTER RESOURCE GOVERNOR ENABLE
-- GO
*/
