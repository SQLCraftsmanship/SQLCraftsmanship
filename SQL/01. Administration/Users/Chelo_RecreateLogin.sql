
DECLARE  @SQLStatement VARCHAR(MAX)

IF NOT EXISTS ( SELECT
                    *
                  FROM
                    tempdb.sys.objects
                  WHERE
                    name = 'resguardo_seg' ) 
   CREATE  TABLE [tempdb].[dbo].[resguardo_seg] ( 
                                                 [id] [int] IDENTITY(1, 1)
                                                            NOT NULL ,
                                                 [DBName] [sysname] NOT NULL ,
                                                 [text1] [nvarchar](500) NULL ,
                                                 [crdate] [smalldatetime] NULL DEFAULT GETDATE(),
                                                 CONSTRAINT [IX_resguardo_seg] UNIQUE CLUSTERED ( [id] ASC, [DBName] ASC )
                                                  WITH ( PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON,
                                                         ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY] )
   ON     [PRIMARY]

--truncate table [tempdb].[dbo].[resguardo_seg]

SET @SQLStatement = '
SELECT ''?'' AS DBName,''use [?] ;'' + ''CREATE USER ['' + name + ''] for login [''+ name + '']'' from [?].sys.database_principals where principal_id >4  and name <> ''dbo''  AND is_fixed_role=0;
SELECT ''?'' AS DBName,''use [?] ;'' + ''GRANT '' + dp.permission_name collate latin1_general_cs_as
    + '' ON '' + s.name + ''.'' + o.name + '' TO ['' + dpr.name + '']'' as ''-- text''
    FROM [?].sys.database_permissions AS dp
    INNER JOIN [?].sys.objects AS o ON dp.major_id=o.object_id
    INNER JOIN [?].sys.schemas AS s ON o.schema_id = s.schema_id
    INNER JOIN [?].sys.database_principals AS dpr ON dp.grantee_principal_id=dpr.principal_id
    WHERE dpr.name NOT IN (''public'',''guest'') AND ''?'' NOT IN (''master'',''msdb'',''model'',''tempdb'') ;
SELECT ''?'' AS DBName,''use [?] ;'' + ''EXECUTE sp_AddRoleMember '' + roles.name + '', [''+ users.name + '']''
       from [?].sys.database_principals users
       inner join [?].sys.database_role_members link
       on link.member_principal_id = users.principal_id
       inner join [?].sys.database_principals roles
       on roles.principal_id = link.role_principal_id
       where users.name NOT IN (''public'',''dbo'',''guest'') AND ''?'' NOT IN (''master'',''msdb'',''model'',''tempdb'')
       '
PRINT @SQLStatement

INSERT [tempdb].[dbo].[resguardo_seg]
    ( DBName, text1 )
    EXEC sp_MSforeachdb @SQLStatement
