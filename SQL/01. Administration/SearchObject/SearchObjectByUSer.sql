USE [DbName]
GO

WITH object_cte AS
(
    SELECT  
        o.Name,
        o.Type_desc,
        CASE
            WHEN o.Principal_Id IS NULL THEN s.Principal_Id
            ELSE o.Principal_Id
        END AS Principal_Id
        FROM SYS.OBJECTS O
        JOIN SYS.SCHEMAS S
        ON   o.Schema_Id = s.Schema_Id
        WHERE o.Is_Ms_Shipped = 0
        ANd   o.Type IN ('U', 'FN', 'FS', 'FT', 'IF', 'P', 'PC', 'TA', 'TF', 'TR', 'V')
)

SELECT
    cte.Name,
    cte.Type_Desc,
    cte.NAMES
FROM objects_cte cte
JOIN SYS.DATABASE_PRINCIPALS dp
ON cte.principal_id = dp.principal_id
WHERE dp.Name <> 'dbo'
