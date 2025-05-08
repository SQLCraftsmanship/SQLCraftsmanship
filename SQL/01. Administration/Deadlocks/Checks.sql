DEADLOCK Checks 
	- waitresource="KEY: 10:72057594124697600 (45596a51d1e7)"
		10 is the databaser
		72057594124697600 is the partition id
		(45596a51d1e7)    this is the row

		1) This is the DB
		SELECT * FROM sys.databases WHERE database_id IN (10)

		2) Table or Index - retrieve the table or index involved in the deadlock
		SELECT b.name AS TableName, 
			   c.name AS IndexName, c.type_desc AS IndexType, * 
		FROM sys.partitions a
		INNER JOIN sys.objects b 
		   ON a.object_id = b.object_id
		INNER JOIN sys.indexes c 
		   ON a.object_id = c.object_id  AND a.index_id = c.index_id
		WHERE partition_id IN ('72057594124697600')

		3) Exact Row - retrieve the exact row or page, in your specific case the wait resource was a KEY, so you search the "column" 
		   %%lockres%% (yes the column name is actually %%lockres%%). If your table is not too out of date or if it is not a DELETE 
		   operation, then you will find the exact row from that hash, after you have determined which table that "partition id" or 
		   "hobt_id" is from then alter and run the below code (disclaimer - the hashes and page locations may have changed by the 
		   time you are doing the debugging, though unlikely with the key hashes)
			
			SELECT 
			   sys.fn_PhysLocFormatter(%%physloc%%) AS PageResource, 
			   %%lockres%% AS LockResource, *
			FROM t_rma_order_stage
			WHERE %%lockres%% IN ('(45596a51d1e7)')

	- waittime="3075" is in ms?
	- lockMode="U"
	- status="suspended" spid="177"
	- hostname="PWSWHJWEBSC001" 
	- isolationlevel="read committed (2)"
	- currentdb="10" currentdbname="AAD"
	- procname="adhoc" line="12" stmtstart="526" stmtend="844" 
		   sqlhandle="0x020000009d797b197031ec85b31aa6d4d6e23ba5d6a86fde0000000000000000000000000000000000000000"

		   1) Get the query
		   SELECT 
			sql_handle AS Handle,
			SUBSTRING(st.text, (qs.statement_start_offset/2)+1, ((CASE qs.statement_end_offset WHEN -1 THEN DATALENGTH(st.text)
																	ELSE qs.statement_end_offset
																	END - qs.statement_start_offset)/2) + 1) AS Text
			FROM sys.dm_exec_query_stats AS qs
			CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
			WHERE sql_handle = '0x020000009d797b197031ec85b31aa6d4d6e23ba5d6a86fde0000000000000000000000000000000000000000'
			--{SQL Handle}

	- Podes tomar el ID y reemplazarlo por processVictim
		<victimProcess id="processf98cefc8c8" />
		Esto lo hago para ver el XML de una forma mas entendible y saber rapidamente cual es el la victima

		Despues tomo el 2do id <process id="processf98ca8fc28" y lo reemplazo por processSurvivor.
		Misma funcionalidad que el punto anterior