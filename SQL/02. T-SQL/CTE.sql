/***********************************************************************************************************************************************
https://www.mssqltips.com/sqlservertip/6861/cte-in-sql-server-examples/?utm_source=dailynewsletter&utm_medium=email&utm_content=headline&utm_campaign=20210513

CTE in SQL Server Examples

What is a CTE?
By pure definition, a CTE is a 'temporary named result set'. In practice, a CTE is a result set that remains in memory for the scope of 
a single execution of a SELECT, INSERT, UPDATE, DELETE, or MERGE statement.

Syntax
WITH <common_table_expression> ([column names])
AS
(
    <cte_query_definition>
)
<operation>

The <cte_query_definition> is always a SELECT statement. This is where we are defining our result set. You can think of this as a temporary 
table that can be referenced in a FROM or JOIN clause like any other normal table. However, there are some key differences between a CTE and 
a temporary table which will be described later. You can also alias your columns in this section to be referenced later on.

The <operation> placeholder is where we will do our actual execution and reference the CTE. As mentioned earlier, this can be a SELECT, INSERT, 
UPDATE, DELETE, or MERGE T-SQL statement. We will look at some examples of these below.
***********************************************************************************************************************************************/

-- Example
WITH Simple_CTE
AS (
   SELECT dd.CalendarYear
      ,fs.OrderDateKey
      ,fs.ProductKey
      ,fs.OrderQuantity * fs.UnitPrice AS TotalSale
      ,dc.FirstName
      ,dc.LastName
   FROM [dbo].[FactInternetSales] fs
   INNER JOIN [dbo].[DimCustomer] dc ON dc.CustomerKey = fs.CustomerKey
   INNER JOIN [dbo].[DimDate] dd ON dd.DateKey = fs.OrderDateKey
)
SELECT *
FROM Simple_CTE;


-- CTE with SELECT
-- Let's take the syntax a bit further. Often, you might find yourself needing to do a multi-tiered aggregation. That is, an aggregation of an 
-- aggregation. CTEs can be a great way to write this type of query in a readable way.
WITH Sum_OrderQuantity_CTE
AS (
    SELECT 
          ProductKey
        , EnglishMonthName
        , SUM(OrderQuantity) AS TotalOrdersByMonth
    FROM [dbo].[FactInternetSales] fs
    JOIN [dbo].[DimDate] dd 
    ON   dd.DateKey = fs.OrderDateKey
    GROUP BY ProductKey, EnglishMonthName
)

    SELECT 
        ProductKey
        , AVG(TotalOrdersByMonth) AS 'Average Total Orders By Month'
    FROM Sum_OrderQuantity_CTE
    GROUP BY ProductKey
    ORDER BY ProductKey

-- In this SQL code, we are taking the sum of OrderQuantity by product per month to see how much of each item was sold per month. Then, we 
-- are averaging this aggregate to see for each product, what is the monthly average quantity sold























