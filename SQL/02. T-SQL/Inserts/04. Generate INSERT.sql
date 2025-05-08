-----------------------------------------------------------------------------------------------------------
-- Generate data to INSERT
-----------------------------------------------------------------------------------------------------------

WITH
  L0   AS (SELECT c FROM (SELECT 1 UNION ALL SELECT 1) AS D(c)), -- 2^1
  L1   AS (SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B),       -- 2^2
  L2   AS (SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B),       -- 2^4
  L3   AS (SELECT 1 AS c FROM L2 AS A CROSS JOIN L2 AS B),       -- 2^8
  L4   AS (SELECT 1 AS c FROM L3 AS A CROSS JOIN L3 AS B),       -- 2^16
  L5   AS (SELECT 1 AS c FROM L4 AS A CROSS JOIN L4 AS B),       -- 2^32
  Nums AS (SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS k FROM L5)

select k as id , 'a_' + cast (k as varchar) as a, 'b_' + cast (k/2 as varchar) as b into t1
from nums
where k <= 1000000


-- Other ways
https://weblogs.asp.net/gunnarpeipman/sql-server-how-to-insert-million-numbers-to-table-fast
