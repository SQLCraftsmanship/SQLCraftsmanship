
https://docs.microsoft.com/en-us/troubleshoot/sql/database-design/remove-duplicate-rows-sql-server-tab

https://kb.objectrocket.com/postgresql/delete-duplicate-rows-in-postgresql-762

-- 1.241.078
SELECT COUNT(*) FROM schdgips."DM_SIRHU_PERSONA_PLUS";

-- 6.316
SELECT 
	"ID", COUNT(*) 
FROM schdgips."DM_SIRHU_PERSONA_PLUS"
GROUP BY "ID"
HAVING COUNT(*) > 1
ORDER BY "ID";

SELECT * FROM schdgips."DM_SIRHU_PERSONA_PLUS"
WHERE "ID" = 1364518;


-- DELETE
-- 12632
BEGIN TRANSACTION;	
	DELETE FROM schdgips."DM_SIRHU_PERSONA_PLUS" 
	WHERE "ID" IN
	(	SELECT "ID"
	 		 , ROW_NUM
		FROM
			(	SELECT 
					"ID",
					ROW_NUMBER() OVER( PARTITION BY "ID" ORDER BY "ID" ) AS ROW_NUM
				FROM schdgips."DM_SIRHU_PERSONA_PLUS"  ) x
		WHERE x.ROW_NUM > 1
	 	AND	  x."ID" = 1364518
	);

	SELECT "rownum", "ID" FROM schdgips."DM_SIRHU_PERSONA_PLUS" WHERE "ID" = 1364518;
ROLLBACK TRANSACTION;


-----------------------------------------------------------------------------------------------------------------------------------------------
logica de eliminacion

	Objetivo: Eliminar una sola linea de los registros duplicados. TODA la linea esta duplicada no tengo ningun campo para identificar un 
			  registro del otro.
	
	Logica  : 1. Agrego una columna a la tabla con nombre [RowNum] INT NOT NULL default 0 (cero)
			  2. Selecciono los registros duplicados y los enumero 1 / 2 sobre la columna [RowNum] y ejecuto UPDATE
			  3. Elimino reggistros duplicados con [RowNum] = 2.	
-----------------------------------------------------------------------------------------------------------------------------------------------

-- 1. Add column
ALTER TABLE schdgips."DM_SIRHU_PERSONA_PLUS"
ADD COLUMN RowNum INT NOT NULL DEFAULT 0;

-- 2. UPDATE column RowNum
BEGIN TRANSACTION;
	UPDATE schdgips."DM_SIRHU_PERSONA_PLUS" 
	SET	   RowNum = x.ROW_NUM
	FROM
		(	SELECT 
		 		"ID", 
		 		ROW_NUM
			FROM
				(	SELECT 
						"ID",
						ROW_NUMBER() OVER( PARTITION BY "ID" ORDER BY "ID" ) AS ROW_NUM
					FROM schdgips."DM_SIRHU_PERSONA_PLUS"  ) x
			WHERE 
			 	x."ID" = 1364518
		) AS x
	
	WHERE schdgips."DM_SIRHU_PERSONA_PLUS"."ID" = 1364518 -- x."ID"
	AND   schdgips."DM_SIRHU_PERSONA_PLUS".RowNum > 1;
	
	SELECT "rownum", "ID" FROM schdgips."DM_SIRHU_PERSONA_PLUS" WHERE "ID" = 1364518;
	
ROLLBACK TRANSACTION

/*

SELECT "ID", "rownum" FROM schdgips."DM_SIRHU_PERSONA_PLUS" ORDER BY "ID";
SELECT "ID", "rownum" FROM schdgips."DM_SIRHU_PERSONA_PLUS" WHERE "ID" > 1895303 ORDER BY "ID";

UPDATE schdgips."DM_SIRHU_PERSONA_PLUS" 
SET	   RowNum = 0

DELETE FROM zoo
WHERE animal_id IN
(SELECT animal_id
FROM
(SELECT animal_id,
ROW_NUMBER() OVER( PARTITION BY animal
ORDER BY animal_id ) AS row_num
FROM zoo ) x
WHERE x.row_num > 1 );
*/

SELECT "rownum", "ID" FROM schdgips."DM_SIRHU_PERSONA_PLUS" WHERE "ID" = 1364518;

-------------------------------------------------------------------------------------------------------
-- Otro modo
-------------------------------------------------------------------------------------------------------
SELECT DISTINCT "ID"
	INTO schdgips."duplicate_table_DM_SIRHU_PERSONA_PLUS"
FROM schdgips."DM_SIRHU_PERSONA_PLUS"
GROUP BY "ID"
HAVING COUNT("ID") > 1

	SELECT COUNT(*) FROM schdgips."duplicate_table_DM_SIRHU_PERSONA_PLUS";
	SELECT COUNT(*) FROM schdgips."DM_SIRHU_PERSONA_PLUS";
	
DELETE FROM schdgips."DM_SIRHU_PERSONA_PLUS"
WHERE "ID"
IN ( SELECT "ID" FROM schdgips."duplicate_table_DM_SIRHU_PERSONA_PLUS");

INSERT INTO schdgips."DM_SIRHU_PERSONA_PLUS"
SELECT *
FROM schdgips."duplicate_table_DM_SIRHU_PERSONA_PLUS"

DROP TABLE duplicate_table
