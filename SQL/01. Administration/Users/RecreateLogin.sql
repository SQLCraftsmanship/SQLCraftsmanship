
/**************************************************************************************************************************
Date		: 2022/03/01
Create by	: DBAs AMS
Object		: [dbo].[ReCreateSecurity]
Description	: We have three sorts of login in SQL Server, Windows Login, SQL Logins and Azure Active Directory.
              
              Generate script at Source Server and execute at Destination with 3 errands:
                1. Create SQL Logins
                2. Assign Server role to the SQL login
                3. Create User at Database Level with object permissions
                    3.1 Create User
                    3.2 Grant permission
                    3.3 Assign Database Role
              
Ref.         : https://www.sqlshack.com/move-or-copy-sql-logins-with-assigning-roles-and-permissions/

Exec Command: EXEC [dbo].[ReCreateSecurity]
**************************************************************************************************************************/

IF EXISTS (SELECT NAME FROM SYS.PROCEDURES WHERE NAME = 'ReCreateSecurity')
	DROP PROCEDURE [dbo].[ReCreateSecurity]
GO

CREATE PROC [dbo].[ReCreateSecurity]
AS
BEGIN
	
	SET NOCOUNT ON
    
    -- CREATE TEMP TABLE
    IF EXISTS (SELECT [Name] FROM TEMPDB.dbo.SYSOBJECTS WHERE [Name] = 'ResultTable' AND xtype = 'U')
    BEGIN
        DROP TABLE [TEMPDB].[dbo].[ResultTable]
    END

    CREATE TABLE [TEMPDB].[dbo].[ResultTable]
    (
          [Id]          INT NOT NULL IDENTITY(1, 1)
        , [DBName]      SYSNAME  NULL
        , [Object]      NVARCHAR(20)
        , [Command]     NVARCHAR(MAX)
        , [crDate]      SMALLDATETIME NULL DEFAULT GETDATE()
    )
    
    -----------------------------------------------------------------------------------------------------------
    -- Step 1 [Create Login]
    -----------------------------------------------------------------------------------------------------------
    INSERT INTO [TEMPDB].[dbo].[ResultTable] ([DBName], [Object], [Command])
    SELECT 
          SP.default_language_name AS DBName
        , 'Login'
        , 'IF (SUSER_ID(' + QUOTENAME(SP.name,'''') + ') IS NULL) BEGIN CREATE LOGIN ' 
          + QUOTENAME(SP.name) 
          + CASE 
              WHEN SP.type_desc = 'SQL_LOGIN' THEN ' WITH PASSWORD = ' 
                                                 + CONVERT(NVARCHAR(MAX), SL.password_hash, 1) 
                                                 + ' HASHED, CHECK_EXPIRATION = ' 
                                                 + CASE 
                                                    WHEN SL.is_expiration_checked = 1 THEN 'ON' 
                                                   ELSE 'OFF' 
                                                   END 
                                                 + ', CHECK_POLICY = ' 
                                                 + CASE 
                                                    WHEN SL.is_policy_checked = 1 THEN 'ON,' 
                                                   ELSE 'OFF,' 
                                                   END
              ELSE ' FROM WINDOWS WITH'
            END 
          + ' DEFAULT_DATABASE = [' + SP.default_database_name + '], DEFAULT_LANGUAGE = [' + SP.default_language_name + '] END;' COLLATE SQL_Latin1_General_CP1_CI_AS AS [-- Logins To Be Created --]

    FROM        SYS.SERVER_PRINCIPALS AS SP 
    LEFT JOIN   SYS.SQL_LOGINS        AS SL 
    ON  SP.principal_id = SL.principal_id

    WHERE 
        SP.type IN ('S','G','U')    -- S = SQL login U = Windows login G = Windows group
    AND SP.name NOT LIKE '##%##'
    AND SP.name NOT LIKE 'NT AUTHORITY%'
    AND SP.name NOT LIKE 'NT SERVICE%'
    AND SP.name <> ('sa')
    AND SP.name <> 'distributor_admin'
    -- We can apply the filter on sp.type section by including the following line (delete ,'U' from first line):
    -- SP.type <> 'U'

  
    -----------------------------------------------------------------------------------------------------------
    -- Step 2 [Assign role to the Login]
    -- This script is going to assign the role to the login for all logins which role is different to public. For public, we don't need to do anything.
    -----------------------------------------------------------------------------------------------------------
    INSERT INTO [TEMPDB].[dbo].[ResultTable] ([DBName], [Object], [Command])
    SELECT 
          SR.default_database_name AS DBName
        , 'Role'
        , 'EXEC MASTER..SP_ADDSRVROLEMEMBER @loginame = N''' + SL.name + ''', @rolename = N''' + SR.name + '''; ' AS [-- Roles To Be Assigned --]

    FROM MASTER.SYS.SERVER_ROLE_MEMBERS SRM

    JOIN MASTER.SYS.SERVER_PRINCIPALS   SR 
    ON   SR.principal_id = SRM.role_principal_id

    JOIN MASTER.SYS.SERVER_PRINCIPALS   SL 
    ON   SL.principal_id = SRM.member_principal_id

    WHERE 
        SL.type IN ('S','G','U')
    AND SL.name NOT LIKE '##%##'
    AND SL.name NOT LIKE 'NT AUTHORITY%'
    AND SL.name NOT LIKE 'NT SERVICE%'
    AND SL.name <> ('sa')
    AND SL.name <> 'distributor_admin';

    -----------------------------------------------------------------------------------------------------------
    -- Step 3 Create User
    -- 3.1 Creat User
    -----------------------------------------------------------------------------------------------------------
    -- EXEC [dbo].[ReCreateSecurity]
    DECLARE @CreateUser NVARCHAR(2000) = 'USE ?;
    SELECT 
          DB_NAME()
        , ''User''
        , ''USE '' + DB_NAME()
          + ''; 
          IF (USER_ID('''''' + dp.name + '''''') IS NOT NULL) BEGIN 
          DROP USER ['' + dp.name + ''];
          CREATE USER ['' + dp.name + ''] 
          FOR LOGIN   ['' + dp.name + ''];''
          + ''ALTER USER ['' + dp.name + ''] WITH DEFAULT_SCHEMA = ['' + dp.default_schema_name + ''];
          END;'' AS [-- Logins To Be Created --]
    FROM SYS.DATABASE_PRINCIPALS AS DP
    JOIN SYS.SERVER_PRINCIPALS   AS SP 
    ON   DP.sid = Sp.sid
    WHERE 
        dp.type IN (''S'',''G'',''U'')
    AND dp.name NOT LIKE ''##%##''
    AND dp.name NOT LIKE ''NT AUTHORITY%''
    AND dp.name NOT LIKE ''NT SERVICE%''
    AND dp.name <> (''sa'')
    AND dp.default_schema_name IS NOT NULL
    AND dp.name <> ''distributor_admin''
    AND dp.principal_id > 4'


    INSERT INTO [TEMPDB].[dbo].[ResultTable] ([DBName], [Object], [Command])
    EXEC sp_MSforeachdb @command1 = @CreateUser;

    -----------------------------------------------------------------------------------------------------------
    -- 3.2 Grant permission
    -----------------------------------------------------------------------------------------------------------
    DECLARE @GranUser NVARCHAR(2000) = 'USE ?;
    SELECT 
          DB_NAME()
        , ''Grant''
        , ''USE '' + DB_NAME() +'' ; '' + CASE WHEN dp.state <> ''W'' THEN dp.state_desc ELSE ''GRANT'' END + '' '' + dp.permission_name + '' TO '' + 
          QUOTENAME(dpg.name) COLLATE database_default + CASE WHEN dp.state <> ''W'' THEN '''' ELSE '' WITH GRANT OPTION'' END + '';'' AS [-- Permission To Be Assign to the User --]
    FROM sys.database_permissions AS dp
    JOIN sys.database_principals AS dpg ON dp.grantee_principal_id = dpg.principal_id
    WHERE 
        dp.major_id = 0 AND dpg.principal_id > 4
    AND dpg.type in (''S'',''G'',''U'')
    AND dpg.name NOT LIKE ''##%##''
    AND dpg.name NOT LIKE ''NT AUTHORITY%''
    AND dpg.name NOT LIKE ''NT SERVICE%''
    AND dpg.name <> (''sa'')
    AND dpg.default_schema_name IS NOT NULL
    AND dpg.name <> ''distributor_admin''
    AND dpg.principal_id > 4
    ORDER BY dpg.name';

    INSERT INTO [TEMPDB].[dbo].[ResultTable] ([DBName], [Object], [Command])
    EXEC sp_MSforeachdb @command1 = @GranUser;

    -----------------------------------------------------------------------------------------------------------
    -- 3.3 Assign Database Role
    -----------------------------------------------------------------------------------------------------------
    DECLARE @DatabaseRoleToUser NVARCHAR(2000) = 'USE ?;
    SELECT
          DB_NAME()
        , ''DatabaseRoleToUser''
        , ''USE '' + DB_NAME() + '' ; '' + ''EXECUTE sp_AddRoleMember '' + roles.name + '', ['' + users.name + '']''
    FROM SYS.DATABASE_PRINCIPALS   users
    JOIN SYS.DATABASE_ROLE_MEMBERS link
    ON   link.member_principal_id  = users.principal_id 
    JOIN SYS.DATABASE_PRINCIPALS   roles
    ON   roles.principal_id = link.role_principal_id
    WHERE users.name NOT IN (''public'', ''dbo'', ''guest'') 
    AND ''?'' NOT IN (''master'', ''msdb'', ''model'', ''tempdb'')'

    INSERT INTO [TEMPDB].[dbo].[ResultTable] ([DBName], [Object], [Command])
    EXEC sp_MSforeachdb @command1 = @DatabaseRoleToUser;

    
    SELECT * FROM [TEMPDB].[dbo].[ResultTable]

END
