
SET QUOTED_IDENTIFIER OFF  
DECLARE
        @sql VARCHAR(MAX) ,
        @plandata VARCHAR(100)

SET @plandata = 'MDMMember'

DECLARE @SQLStatement VARCHAR(4000) 



SET @sql='use '+@plandata+';'
	
SELECT
    @sql=@sql+ replace([text1],'use ['+@plandata+'] ;','')+';
'
  FROM
    [tempdb].[dbo].[resguardo_seg]
  WHERE
    DBName = @plandata COLLATE database_default AND
    [crdate] = (
                 SELECT
                    MAX([crdate])
                  FROM
                    tempdb.dbo.resguardo_seg
               ) and text1 not like '%controlmsqlprod%'
  ORDER BY
    id,DBName  

print @sql
	EXEC ( @sql)
	
SET QUOTED_IDENTIFIER OFF
DECLARE @SQl1 VARCHAR(max)='use '+@plandata+';'
SELECT @SQl1=@SQl1+"EXEC sp_change_users_login 'Auto_Fix','"+name+"';
" FROM sys.sysusers
WHERE isntname =0 AND islogin=1 AND hasdbaccess=1

exec( @SQl1)