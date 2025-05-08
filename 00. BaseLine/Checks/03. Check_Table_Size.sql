
-----------------------------------------------------------------------------------------------------------------------------------------------
-- Get Table Size for all Tables
-----------------------------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#SpaceUsed') IS NOT NULL
	DROP TABLE #SpaceUsed

CREATE TABLE #SpaceUsed 
(
	  TableName sysname
	, NumRows BIGINT
	, ReservedSpace VARCHAR(50)
	, DataSpace VARCHAR(50)
	, IndexSize VARCHAR(50)
	, UnusedSpace VARCHAR(50)
) 

DECLARE @str VARCHAR(500)
SET @str =  'exec sp_spaceused ''?'''
INSERT INTO #SpaceUsed 
EXEC sp_msforeachtable @command1=@str

-- Convertimos las columnas para poder hacer un correcto ordenamiento en caso contrario
-- el ordenamiento por la columna ReservedSpace desc lo hace de forma incorrecta puesto que
-- dicha columna es una STRING
SELECT
    TableName
    , NumRows
    , CONVERT(numeric(18,0),REPLACE(ReservedSpace,' KB','')) / 1024 AS ReservedSpace_MB
    , CONVERT(numeric(18,0),REPLACE(DataSpace,' KB','')) / 1024     AS DataSpace_MB
    , CONVERT(numeric(18,0),REPLACE(IndexSize,' KB','')) / 1024     AS IndexSpace_MB
    , CONVERT(numeric(18,0),REPLACE(UnusedSpace,' KB','')) / 1024   AS UnusedSpace_MB
    , GETDATE() AS [Date]
FROM #SpaceUsed
WHERE TableName IN ('Play_Sessions', 'Cashier_vouchers', 'Alarms', 'Terminal_sas_meters_history',
                    'Account_Movements', 'Audit_3GS', 'Plays')
ORDER BY ReservedSpace_MB desc

