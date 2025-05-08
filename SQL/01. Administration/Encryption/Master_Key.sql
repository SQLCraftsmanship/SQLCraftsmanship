
---------------------------------------------------------------------------------------------------------------------------------------
-- MASTER KEY ENCRYPTION
---------------------------------------------------------------------------------------------------------------------------------------

-- Ref 1
https://docs.microsoft.com/en-us/sql/relational-databases/security/encryption/sql-server-and-database-encryption-keys-database-engine?view=sql-server-ver15


-- Enabled CLR 
EXEC sp_configure 'clr enabled'

EXEC sp_configure 'clr enabled', 1
RECONFIGURE
 
EXEC sp_configure 'clr enabled'


-- After enabling CLR integration you should focus on its use and security. Starting from SQL Server version 2017 there is a new configuration option 
-- named "clr strict security" which is enabled by default and interprets all assemblies as "unsafe".

-- When the CLR strict security option is enabled, any assemblies that are not signed will not load successfully. To avoid this, you will have to 
-- recreate the assemblies with a signature of either a certificate or an asymmetric key that has a corresponding login with the UNSAFE ASSEMBLY 
-- permission on the server.


-- Check encryption
SELECT is_master_key_encrypted_by_server 
FROM   SYS.DATABASES 
WHERE  Name = 'master'


-- Creates a backup of the service master key.
USE MASTER;
GO

	BACKUP SERVICE MASTER KEY TO FILE = 'c:\temp_backups\keys\service_master_ key'
		ENCRYPTION BY PASSWORD = 'Put a pass';
GO

-- Create a Master Key
USE SSISDB -- change DB name when you need
GO

	CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Password' -- Change password

-- 
USE MASTER
GO
	OPEN MASTER KEY DECRYPTION BY PASSWORD = 'password'
	
	ALTER MASTER KEY ADD ENCRYPTION BY SERVICE MASTER KEY

