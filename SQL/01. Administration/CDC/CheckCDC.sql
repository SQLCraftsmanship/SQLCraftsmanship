-- Check Recovery Option
SELECT name, recovery_model_desc, log_reuse_wait_desc, is_cdc_enabled FROM SYS.DATABASES

-- Check tables
select
  name,
  is_tracked_by_cdc 
from sys.tables;


EXEC sys.sp_cdc_disable_db
GO
EXEC sys.sp_cdc_enable_db
GO
