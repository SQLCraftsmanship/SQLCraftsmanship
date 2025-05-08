
-- Drop table
DROP TABLE IF EXISTS dbo.TableA

-- Create table
CREATE TABLE TableA
(
	 ID		INT NOT NULL IDENTITY(1,1),
	 Value	INT,
 CONSTRAINT PK_ID PRIMARY KEY(ID)  
);

-- Insert Table
INSERT INTO TableA(Value)
VALUES(1),(2),(3),(4),(5),(5),(3),(5)

-- Select all
SELECT * FROM TableA

-- Select duplicate values
SELECT Value, COUNT(*) AS DuplicatesCount
FROM TableA
GROUP BY Value


/*****************************************************************************************************************************************************
	Finding duplicate values in a table with a unique index
*****************************************************************************************************************************************************/

SET STATISTICS IO ON

--Solution 1
SELECT a.* 
FROM	dbo.TableA a, 
	(SELECT 
			ID
			, (SELECT 
					MAX(Value) 
			   FROM dbo.TableA i 
			   WHERE o.Value = i.Value 
			   GROUP BY Value 
			   HAVING o.ID < MAX(i.ID)) AS MaxValue 
	 FROM dbo.TableA o) b
WHERE 
	a.ID = b.ID 
AND b.MaxValue IS NOT NULL


--Solution 2
SELECT a.* 
FROM	dbo.TableA a
	, (SELECT 
			  ID
			, (SELECT 
					MAX(Value) 
				FROM dbo.TableA i 
				WHERE o.Value = i.Value 
				GROUP BY Value 
				HAVING o.ID = MAX(i.ID)) AS MaxValue 
		FROM TableA o) b
WHERE 
	a.ID = b.ID 
AND b.MaxValue IS NULL


--Solution 3
SELECT  a.*
FROM	dbo.TableA a
JOIN (
		SELECT 
			  MAX(ID) AS ID
			, Value 
		FROM dbo.TableA
		GROUP BY Value 
		HAVING COUNT(Value) > 1
	) b
ON  a.ID	< b.ID 
AND a.Value = b.Value


--Solution 4
SELECT  a.* 
FROM	dbo.TableA a 
WHERE	ID < (SELECT 
					MAX(ID)
			  FROM dbo.TableA b 
			  WHERE a.Value = b.Value 
			  GROUP BY Value 
			  HAVING COUNT(*) > 1)


--Solution 5 
SELECT  a.*
FROM	dbo.TableA a
JOIN	(SELECT 
			  ID
			, RANK() OVER(PARTITION BY Value ORDER BY ID DESC) AS rnk 
		 FROM dbo.TableA) b 
ON a.ID = b.ID
WHERE b.rnk > 1


--Solution 6 
SELECT * 
FROM   dbo.TableA 
WHERE  ID NOT IN (SELECT MAX(ID) 
                  FROM  dbo.TableA 
                  GROUP BY Value)


/*****************************************************************************************************************************************************
 Deleting Duplicate Rows in a SQL Server Table
*****************************************************************************************************************************************************/

--Deleting duplicate values
DELETE t
FROM   dbo.TableA t
WHERE  ID IN ( SELECT 
					a.ID 
			   FROM TableA a, 
				   ( SELECT 
							ID
						,	(SELECT MAX(Value) 
							 FROM TableA i 
							 WHERE o.Value = i.Value 
							 GROUP BY Value 
							 HAVING o.ID = MAX(i.ID)) AS MaxValue 
					 FROM TableA o) b
				WHERE a.ID = b.ID 
				AND   b.MaxValue IS NULL) 

--Deleting duplicate values
DELETE  a
FROM	dbo.TableA a
JOIN	(SELECT 
			  ID
			, RANK() OVER(PARTITION BY Value ORDER BY ID DESC) AS rnk 
		 FROM dbo.TableA) b 
ON a.ID = b.ID
WHERE b.rnk > 1


--Deleting duplicate values
DELETE FROM TableA 
WHERE ID NOT IN (SELECT MAX(ID) 
                 FROM   dbo.TableA 
                 GROUP BY Value)


/*****************************************************************************************************************************************************
	Removing duplicates from a SQL Server table without a unique index
*****************************************************************************************************************************************************/
-- Drop table
DROP TABLE IF EXISTS dbo.TableB

-- Create table
CREATE TABLE TableB (Value INT)

-- Insert values
INSERT INTO TableB(Value) 
VALUES(1),(2),(3),(4),(5),(5),(3),(5)

-- Select all
SELECT * FROM TableB

-- Option 1
;WITH TableBWithRowID AS
( SELECT 
	ROW_NUMBER() OVER (ORDER BY Value) AS RowID, Value
  FROM TableB )

DELETE o
FROM   TableBWithRowID o
WHERE  RowID < (SELECT MAX(rowID) FROM TableBWithRowID i WHERE i.Value = o.Value GROUP BY Value)

SELECT * FROM TableB


-- Option 2
; WITH TableBWithRowID AS
( SELECT 
	ROW_NUMBER() OVER (PARTITION BY Value ORDER BY Value) AS RowID, Value
  FROM TableB )
	
	-- SELECT * FROM TableBWithRowID 

DELETE o
FROM  TableBWithRowID o
WHERE RowID > 1

SELECT * FROM TableB


-- Option 3
-- The first two queries below are the equivalent versions of removing duplicates in Oracle, the next two are queries for removing duplicates using %%physloc%% similar 
-- to the case of the table with a unique index, and in the last query, %%physloc%% is not used just for comparing performance of all of these options:

-- A
DELETE	o
FROM	(SELECT %%physloc%% as RowID, value FROM TableB) o
WHERE	o.RowID < ( SELECT MAX(%%physloc%%)
                    FROM TableB i
                    WHERE i.Value = o.Value
                    GROUP BY Value )


-- B
DELETE TableB
WHERE  %%physloc%% NOT IN (	SELECT MAX(%%physloc%%)
							FROM TableB
							GROUP BY Value )

SELECT %%physloc%%, * FROM TableB

-- C
DELETE b1
FROM (SELECT %%physloc%% as RowID, value FROM TableB) b1
JOIN (SELECT %%physloc%% as RowID, RANK() OVER(PARTITION BY Value ORDER BY %%physloc%% DESC) AS rnk FROM TableB ) b2 
ON   b1.RowID = b2.RowID
WHERE b2.rnk > 1


-- D
DELETE b1
FROM   Tableb b1 
WHERE  %%physloc%% < (  SELECT MAX(%%physloc%%) 
						FROM Tableb b2 
						WHERE b1.Value = b2.Value 
						GROUP BY Value 
						HAVING COUNT(*) > 1  )

-- E
;WITH 
TableBWithRowID AS
(
   SELECT ROW_NUMBER() OVER (partition by Value ORDER BY Value) AS RowID, Value
   FROM TableB
)
DELETE o
FROM   TableBWithRowID o
WHERE  RowID > 1

-- Hence, we can conclude that in general, using %%physloc%% does not improve the performance. 
-- While using this approach, it is very important to realize that this is an undocumented feature 
-- of SQL Server and, therefore, developers should be very careful.
