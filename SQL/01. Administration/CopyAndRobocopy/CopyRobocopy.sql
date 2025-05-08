
--select  
--count(1),min(urc.modified) min_modified,max(urc.modified) max_modified, min(take_date) min_take_date
--from prd.t_user_retailer_coupon urc 
--with(nolock), prd.t_user_retailer  ur with(nolock)
--where urc.USER_RETAILER_ID = ur.USER_RETAILER_ID
--and (urc.CLIPPED_RETAILER_ID = -1 or urc.CLIPPED_RETAILER_ID is null)
--and urc.take_date  >= '26-OCT-22' and urc.take_date  < '31-OCT-22'


xcopy "\\CORP-SQLPFM01\X:\Backup:\CORP-SQLPFM01\FULL\*.*" "\\PWSWSQLPFMHC001.CLIENT.EXT\X:\ForMigration\" /s/e/h
xcopy "\\CORP-SQLPFM01\X:\Backup:\CORP-SQLPFM01\FULL\*.*" "\\PWSWSQLPFMHC001.CLIENT.EXT\X:\ForMigration\" /s/e/h


"\\CORP-SQLPFM01.CLIENT.EXT\X:\Backup:\CORP-SQLPFM01\FULL\*.*" "\\192.168.30.71.CLIENT.EXT\X:\ForMigration\"
"\\CORP-SQLPFM01.CLIENT.EXT\X:\Backup:\CORP-SQLPFM01\FULL\*.*" "\\192.168.30.71\X:\ForMigration\"

move /y "F:\Folder 1\*.asp" "\\100.50.0.0\F$\Folder 3\"

move /y "X:\Backup\CORP-SQLPFM01\FULL\*.*" "\\192.168.30.71\X$\ForMigration\"
move /y "X:\Backup\CORP-SQLPFM01\FULL\*.*" "\\192.168.30.71\X:\ForMigration\"
move /y "X:\Backup\CORP-SQLPFM01\FULL\*.*" "\\PWSWSQLPFMHC001\X$\ForMigration\"


Robocopy \\server1\data 							   \\server2\data /mir /copyall /dcopy:T
Robocopy \\CORP-SQLPFM01\X:\Backup:\CORP-SQLPFM01\FULL \\PWSWSQLPFMHC001.CLIENT.EXT\X:\ForMigration\ /mir /copyall 
Robocopy \\CORP-SQLPFM01.CLIENT.EXT\X:\Backup:\CORP-SQLPFM01\FULL \\PWSWSQLPFMHC001.CLIENT.EXT\X:\ForMigration\ /mir /copyall 
Robocopy \\X:\Backup:\CORP-SQLPFM01\FULL \\PWSWSQLPFMHC001.CLIENT.EXT\X:\ForMigration\ /mir /copyall 
Robocopy \\192.168.30.142\X:\Backup\CORP-SQLPFM01\FULL \\PWSWSQLPFMHC001.CLIENT.EXT\X:\ForMigration\ /mir /copyall
Robocopy \\CORP-SQLPFM01.CLIENT.EXT\X:\Backup\CORP-SQLPFM01\FULL \\PWSWSQLPFMHC001.CLIENT.EXT\X:\ForMigration\ /mir /copyall 
