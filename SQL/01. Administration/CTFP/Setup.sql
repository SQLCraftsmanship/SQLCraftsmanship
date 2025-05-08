/* check CTFP */
EXEC sp_configure;
cost threshold for parallelism	0	32767	150	150

/* change CTFP */
USE master;
GO
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE
GO
EXEC sp_configure 'cost threshold for parallelism', 10;
GO
RECONFIGURE
GO