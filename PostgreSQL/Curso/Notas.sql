--------------------------------------------------------------------
-- SELECT
--------------------------------------------------------------------
-- Resolucion FROM --> SELECT
-- Expressions
SELECT 
   first_name || ' ' || last_name,
   email
FROM 
   customer;

--------------------------------------------------------------------
-- ORDER BY
--------------------------------------------------------------------
-- FROM --> SELECT --> ORDER BY
-- Sort rows by expressions
SELECT 
	first_name,
	LENGTH(first_name) len
FROM
	customer
ORDER BY 
	len DESC;

-- PostgreSQL ORDER BY clause and NULL
-- ORDER BY sort_expresssion [ASC | DESC] [NULLS FIRST | NULLS LAST]
-- create a new table
-- CREATE TABLE sort_demo(
-- 	num INT
-- );

-- insert some data
-- INSERT INTO sort_demo(num)
-- VALUES(1),(2),(3),(null);

SELECT * FROM sort_demo
ORDER BY num NULLS FIRST
;
SELECT * FROM sort_demo
ORDER BY num NULLS LAST
;
SELECT num
FROM sort_demo
ORDER BY num DESC NULLS LAST;

--------------------------------------------------------------------
-- DISTINCT
--------------------------------------------------------------------
-- PostgreSQL also provides the DISTINCT ON (expression) to keep the “first” row of each group of duplicates using the following syntax:
-- It is a good practice to always use the ORDER BY clause with the DISTINCT ON(expression) to make the result set predictable.
SELECT
   DISTINCT ON (column1) column_alias,
   column2
FROM
   table_name
ORDER BY
   column1,
   column2;

CREATE TABLE distinct_demo (
	id serial NOT NULL PRIMARY KEY,
	bcolor VARCHAR,
	fcolor VARCHAR
);

INSERT INTO distinct_demo (bcolor, fcolor)
VALUES
	('red', 'red'),
	('red', 'red'),
	('red', NULL),
	(NULL, 'red'),
	('red', 'green'),
	('red', 'blue'),
	('green', 'red'),
	('green', 'blue'),
	('green', 'green'),
	('blue', 'red'),
	('blue', 'green'),
	('blue', 'blue');

SELECT
	id,
	bcolor,
	fcolor
FROM
	distinct_demo ;

SELECT
	DISTINCT bcolor
FROM
	distinct_demo
ORDER BY
	bcolor;

SELECT
	DISTINCT bcolor, fcolor
FROM
	distinct_demo
ORDER BY
	bcolor,
	fcolor;


-- PostgreSQL DISTINCT ON example
SELECT
	DISTINCT ON (bcolor) bcolor,
	fcolor
FROM
	distinct_demo 
ORDER BY
	bcolor,
	fcolor;

--------------------------------------------------------------------
-- WHERE
--------------------------------------------------------------------
-- FROM --> WHERE --> SELECT --> ORDER BY

-- LO DE SIEMPRE NADA NUEVO LO MISMO QUE SQL


--------------------------------------------------------------------
-- LIMIT
--------------------------------------------------------------------
-- SINTAX
SELECT select_list 
FROM table_name
ORDER BY sort_expression
LIMIT row_count

SELECT select_list
FROM table_name
LIMIT row_count OFFSET row_to_skip;

SELECT
	film_id,
	title,
	release_year
FROM
	film
ORDER BY
	film_id
LIMIT 5;

-- To retrieve 4 films starting from the fourth one ordered by film_id, you use both LIMIT and OFFSET clauses as follows:
SELECT
	film_id,
	title,
	release_year
FROM
	film
ORDER BY
	film_id
LIMIT 4 OFFSET 3;


--------------------------------------------------------------------
-- FETCH
--------------------------------------------------------------------
-- To constrain the number of rows returned by a query, you often use the LIMIT clause. The LIMIT clause is widely used by many 
-- relational database management systems such as MySQL, H2, and HSQLDB. However, the LIMIT clause is not a SQL-standard.

-- To conform with the SQL standard, PostgreSQL supports the FETCH clause to retrieve a number of rows returned by a query. Note that 
-- the FETCH clause was introduced in SQL:2008.

-- The following illustrates the syntax of the PostgreSQL FETCH clause:

OFFSET start { ROW | ROWS }
FETCH { FIRST | NEXT } [ row_count ] { ROW | ROWS } ONLY


-- FETCH vs. LIMIT
-- The FETCH clause is functionally equivalent to the LIMIT clause. If you plan to make your application compatible with other database 
-- systems, you should use the FETCH clause because it follows the standard SQL.
SELECT
    film_id,
    title
FROM
    film
ORDER BY
    title 
FETCH FIRST 1 ROW ONLY;

-- It is equivalent to the following query:
SELECT
    film_id,
    title
FROM
    film
ORDER BY
    title 
FETCH FIRST ROW ONLY;

SELECT
    film_id,
    title
FROM
    film
ORDER BY
    title 
FETCH FIRST 5 ROW ONLY;

-- The following statement returns the next five films after the first five films sorted by titles:
SELECT
    film_id,
    title
FROM
    film
ORDER BY
    title 
OFFSET 5 ROWS 
FETCH FIRST 5 ROW ONLY; 


--------------------------------------------------------------------
-- LIKE
--------------------------------------------------------------------
-- PostgreSQL also provides some operators that act like the LIKE, NOT LIKE, ILIKE and NOT ILIKE operator as shown below:

Operator	Equivalent
~~	        LIKE
~~*	        ILIKE
!~~	        NOT LIKE
!~~*	    NOT ILIKE


--------------------------------------------------------------------
-- JOIN
--------------------------------------------------------------------
-- PostgreSQL supports inner join, left join, right join, full outer join, cross join, natural join, and a special kind of join called 
-- self-join.
CREATE TABLE basket_a (
    a INT PRIMARY KEY,
    fruit_a VARCHAR (100) NOT NULL
);

CREATE TABLE basket_b (
    b INT PRIMARY KEY,
    fruit_b VARCHAR (100) NOT NULL
);

INSERT INTO basket_a (a, fruit_a)
VALUES
    (1, 'Apple'),
    (2, 'Orange'),
    (3, 'Banana'),
    (4, 'Cucumber');

INSERT INTO basket_b (b, fruit_b)
VALUES
    (1, 'Orange'),
    (2, 'Apple'),
    (3, 'Watermelon'),
    (4, 'Pear');


SELECT * FROM basket_a;
SELECT * FROM basket_b;

-- JOIN
SELECT *
FROM basket_a
JOIN basket_b
ON   basket_a.fruit_a = basket_b.fruit_b

-- LEFT JOIN
SELECT *
FROM basket_a
LEFT JOIN basket_b
ON   basket_a.fruit_a = basket_b.fruit_b

SELECT *
FROM basket_a
LEFT JOIN basket_b 
ON   fruit_a = fruit_b
WHERE b IS NULL;

-- RIGTH JOIN
SELECT *
FROM basket_a
RIGHT JOIN basket_b
ON   basket_a.fruit_a = basket_b.fruit_b
-- to get the records from B which don't much in A
WHERE a IS NULL;

-- FULL OUTER JOIN
SELECT *
FROM basket_a
FULL OUTER JOIN basket_b
ON   basket_a.fruit_a = basket_b.fruit_b
-- To return rows in a table that do not have matching rows in the other,
WHERE a IS NULL OR b IS NULL;

DROP TABLE IF EXISTS departments;
DROP TABLE IF EXISTS employees;

CREATE TABLE departments (
	department_id serial PRIMARY KEY,
	department_name VARCHAR (255) NOT NULL
);

CREATE TABLE employees (
	employee_id serial PRIMARY KEY,
	employee_name VARCHAR (255),
	department_id INTEGER
);

INSERT INTO departments (department_name)
VALUES
	('Sales'),
	('Marketing'),
	('HR'),
	('IT'),
	('Production');

INSERT INTO employees (
	employee_name,
	department_id
)
VALUES
	('Bette Nicholson', 1),
	('Christian Gable', 1),
	('Joe Swank', 2),
	('Fred Costner', 3),
	('Sandra Kilmer', 4),
	('Julia Mcqueen', NULL);
	
	
SELECT * FROM departments;
SELECT * FROM employees;

SELECT
	employee_name,
	department_name
FROM
	employees e
FULL OUTER JOIN departments d 
ON d.department_id = e.department_id;
		


-- SELF-JOINS
-- A PostgreSQL self-join is a regular join that joins a table to itself using the INNER JOIN or LEFT JOIN.
-- Self-joins are very useful to query hierarchical data or to compare rows within the same table.

CREATE TABLE employee (
	employee_id INT PRIMARY KEY,
	first_name VARCHAR (255) NOT NULL,
	last_name VARCHAR (255) NOT NULL,
	manager_id INT,
	FOREIGN KEY (manager_id) 
	REFERENCES employee (employee_id) 
	ON DELETE CASCADE
);
INSERT INTO employee (
	employee_id,
	first_name,
	last_name,
	manager_id
)
VALUES
	(1, 'Windy', 'Hays', NULL),
	(2, 'Ava', 'Christensen', 1),
	(3, 'Hassan', 'Conner', 1),
	(4, 'Anna', 'Reeves', 2),
	(5, 'Sau', 'Norman', 2),
	(6, 'Kelsie', 'Hays', 3),
	(7, 'Tory', 'Goff', 3),
	(8, 'Salley', 'Lester', 3);
	
SELECT *
FROM employee;

-- In this employee table, the manager_id column references the employee_id column. The value in the manager_id column shows the manager that the 
-- employee directly reports to. When the value in the manager_id column is null, that employee does not report to anyone. In other words, he or 
-- she is the top manager.

-- The following query uses the self-join to find who reports to whom:
SELECT
    e.first_name || ' ' || e.last_name employee,
    m .first_name || ' ' || m .last_name manager
FROM
    employee e
INNER JOIN employee m 
ON  m.employee_id = e.manager_id
ORDER BY manager;

-- Comparing the rows with the same table
SELECT
    f1.title,
    f2.title,
    f1.length
FROM
    film f1
INNER JOIN film f2 
    ON f1.film_id <> f2.film_id AND 
       f1.length = f2.length;

---------------------------------------------------------------------------------------------------------------
-- NATURAL JOIN
---------------------------------------------------------------------------------------------------------------
-- A natural join is a join that creates an implicit join based on the same column names in the joined tables.

-- The following shows the syntax of the PostgreSQL natural join:

SELECT *
FROM   T1
NATURAL [INNER, LEFT, RIGHT] JOIN T2;

-- A natural join can be an inner join, left join, or right join. If you do not specify a join explicitly e.g., INNER JOIN, LEFT JOIN, RIGHT JOIN, PostgreSQL will use the INNER JOIN by default.
-- If you use the asterisk (*) in the select list, the result will contain the following columns:
-- All the common columns, which are the columns from both tables that have the same name.
-- Every column from both tables, which is not a common column.
DROP TABLE IF EXISTS categories;
CREATE TABLE categories (
	category_id serial PRIMARY KEY,
	category_name VARCHAR (255) NOT NULL
);

DROP TABLE IF EXISTS products;
CREATE TABLE products (
	product_id serial PRIMARY KEY,
	product_name VARCHAR (255) NOT NULL,
	category_id INT NOT NULL,
	FOREIGN KEY (category_id) REFERENCES categories (category_id)
);


INSERT INTO categories (category_name)
VALUES
	('Smart Phone'),
	('Laptop'),
	('Tablet');

INSERT INTO products (product_name, category_id)
VALUES
	('iPhone', 1),
	('Samsung Galaxy', 1),
	('HP Elite', 2),
	('Lenovo Thinkpad', 2),
	('iPad', 3),
	('Kindle Fire', 3);


SELECT * FROM products
NATURAL JOIN categories;

-- The above statement is equivalent to the following statement that uses the INNER JOIN clause.

SELECT	* FROM products
INNER JOIN categories USING (category_id);

-- The convenience of the NATURAL JOIN is that it does not require you to specify the join clause because it uses an implicit join clause based 
-- on the common column.
-- However, you should avoid using the NATURAL JOIN whenever possible because sometimes it may cause an unexpected result.


---------------------------------------------------------------------------------------------------------------
-- INTERSECT
---------------------------------------------------------------------------------------------------------------
-- The INTERSECT operator returns any rows that are available in both result sets.
-- To use the INTERSECT operator, the columns that appear in the SELECT statements must follow the folowing rules:

-- The number of columns and their order in the SELECT clauses must be the same.
-- The data types of the columns must be compatible.

-- To get popular films which are also top rated films, you use the INTERSECT operator as follows:
SELECT *
FROM most_popular_films 
	INTERSECT
SELECT *
FROM top_rated_films;


---------------------------------------------------------------------------------------------------------------
-- EXCEPT
---------------------------------------------------------------------------------------------------------------
-- The EXCEPT operator returns distinct rows from the first (left) query that are not in the output of the 
-- second (right) query.

-- The queries that involve in the EXCEPT need to follow these rules:

-- The number of columns and their orders must be the same in the two queries.
-- The data types of the respective columns must be compatible.

-- The following statement uses the EXCEPT operator to find the top-rated films that are not popular:
SELECT * FROM top_rated_films
	EXCEPT 
SELECT * FROM most_popular_films;

--------------------------------------------------------------------------------------------------------
-- GROUPING SETS
--------------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS sales;
CREATE TABLE sales (
    brand 	 VARCHAR NOT NULL,
    segment  VARCHAR NOT NULL,
    quantity INT     NOT NULL,
    PRIMARY KEY (brand, segment)
);

INSERT INTO sales (brand, segment, quantity)
VALUES
    ('ABC', 'Premium', 100),
    ('ABC', 'Basic'  , 200),
    ('XYZ', 'Premium', 100),
    ('XYZ', 'Basic'  , 300);

SELECT * FROM sales;

-- Query 1
SELECT
    brand,
    segment,
    SUM (quantity)
FROM sales
GROUP BY brand, segment;

-- Query 2
SELECT
    brand,
    SUM (quantity)
FROM sales
GROUP BY brand;

-- Query 3
SELECT segment, SUM (quantity)
FROM   sales
GROUP BY segment;

-- Query 4
SELECT SUM (quantity) FROM sales;

-- Query 5
SELECT
    brand,
    segment,
    SUM (quantity)
FROM sales
GROUP BY brand, segment
	UNION ALL
SELECT
    brand,
    NULL,
    SUM (quantity)
FROM sales
GROUP BY brand
	UNION ALL
SELECT
    NULL,
    segment,
    SUM (quantity)
FROM sales
GROUP BY segment
	UNION ALL
SELECT
    NULL,
    NULL,
    SUM (quantity)
FROM sales;


-- To make it more efficient, PostgreSQL provides the GROUPING SETS clause which is the subclause of the GROUP BY clause.
-- The GROUPING SETS allows you to define multiple grouping sets in the same query.
-- The general syntax of the GROUPING SETS is as follows:
SELECT
    c1,
    c2,
    aggregate_function(c3)
FROM
    table_name
GROUP BY
    GROUPING SETS (
        (c1, c2),
        (c1),
        (c2),
        ()
);

-- To apply this syntax to the above example, you can use GROUPING SETS clause instead of the UNION ALL clause like this:
SELECT
    brand,
    segment,
    SUM (quantity)
FROM sales
GROUP BY
    GROUPING SETS (
        (brand, segment),
        (brand),
        (segment),
        ()
    );

/*****************************************************************************************************************
Grouping function
The GROUPING() function accepts an argument which can be a column name or an expression:

GROUPING( column_name | expression)
The column_name or expression must match with the one specified in the GROUP BY clause.

The GROUPING() function returns bit 0 if the argument is a member of the current grouping set and 1 otherwise.

See the following example:
*****************************************************************************************************************/
SELECT
	GROUPING(brand)   grouping_brand,
	GROUPING(segment) grouping_segment,
	brand,
	segment,
	SUM (quantity)
FROM sales
GROUP BY
	GROUPING SETS (
		(brand),
		(segment),
		()
	)
ORDER BY
	brand,
	segment;


SELECT
	GROUPING(brand) grouping_brand,
	GROUPING(segment) grouping_segment,
	brand,
	segment,
	SUM (quantity)
FROM
	sales
GROUP BY
	GROUPING SETS (
		(brand),
		(segment),
		()
	)
HAVING GROUPING(brand) = 0	
ORDER BY
	brand,
	segment;

--------------------------------------------------------------------------------------------------------
-- CUBE SETS
--------------------------------------------------------------------------------------------------------

-- The CUBE allows you to generate multiple grouping sets.
-- SITNAX
SELECT
    c1,
    c2,
    c3,
    aggregate (c4)
FROM
    table_name
GROUP BY
    CUBE (c1, c2, c3);


-- Query 1
SELECT
    brand,
    segment,
    SUM (quantity)
FROM sales
GROUP BY
    CUBE (brand, segment)
ORDER BY
    brand,
    segment;

-- Query 2
-- The following query performs a partial cube:
SELECT
    brand,
    segment,
    SUM (quantity)
FROM sales
GROUP BY
    brand,
    CUBE (segment)
ORDER BY
    brand,
    segment;

--------------------------------------------------------------------------------------------------------
-- ROLLUP
--------------------------------------------------------------------------------------------------------

-- Different from the CUBE subclause, ROLLUP does not generate all possible grouping sets based on the 
-- specified columns. It just makes a subset of those.

-- The ROLLUP assumes a hierarchy among the input columns and generates all grouping sets that make sense 
-- considering the hierarchy. This is the reason why ROLLUP is often used to generate the subtotals and 
-- the grand total for reports.

-- For example, the CUBE (c1,c2,c3) makes all eight possible grouping sets:
-- (c1, c2, c3)
-- (c1, c2)
-- (c2, c3)
-- (c1,c3)
-- (c1)
-- (c2)
-- (c3)
-- ()

-- Code language: SQL (Structured Query Language) (sql)
-- However, the ROLLUP(c1,c2,c3) generates only four grouping sets, assuming the hierarchy c1 > c2 > c3 as follows:
-- (c1, c2, c3)
-- (c1, c2)
-- (c1)
-- ()

/***********************************************************************************************************************
-- IMPORTANTE!!!!
-- A common use of  ROLLUP is to calculate the aggregations of data by year, month, and date, considering the 
-- hierarchy year > month > date
***********************************************************************************************************************/

DROP TABLE IF EXISTS sales;
CREATE TABLE sales (
    brand    VARCHAR NOT NULL,
    segment  VARCHAR NOT NULL,
    quantity INT NOT NULL,
    PRIMARY KEY (brand, segment)
);

INSERT INTO sales (brand, segment, quantity)
VALUES
    ('ABC', 'Premium', 100),
    ('ABC', 'Basic'  , 200),
    ('XYZ', 'Premium', 100),
    ('XYZ', 'Basic'  , 300);


-- The following query uses the ROLLUP clause to find the number of products sold by brand (subtotal) and by all brands 
-- and segments (total).

SELECT
    brand,
    segment,
    SUM (quantity)
FROM
    sales
GROUP BY
    ROLLUP (brand, segment)
ORDER BY
    brand,
    segment;


-- If you change the order of brand and segment, the result will be different as follows:
SELECT
    segment,
    brand,
    SUM (quantity)
FROM
    sales
GROUP BY
    ROLLUP (segment, brand)
ORDER BY
    segment,
    brand;

-- The following statement performs a partial roll-up:
SELECT
    segment,
    brand,
    SUM (quantity)
FROM
    sales
GROUP BY
    segment,
    ROLLUP (brand)
ORDER BY
    segment,
    brand;


SELECT * FROM Rental

-- The following statement finds the number of rental per day, month, and year by using the ROLLUP:
SELECT
    EXTRACT (YEAR  FROM rental_date) y,
    EXTRACT (MONTH FROM rental_date) M,
    EXTRACT (DAY   FROM rental_date) d,
    COUNT (rental_id)
FROM
    rental
GROUP BY
    ROLLUP (
        EXTRACT (YEAR  FROM rental_date),
        EXTRACT (MONTH FROM rental_date),
        EXTRACT (DAY   FROM rental_date)
    );


--------------------------------------------------------------------------------------------------------
-- SUBQUERIES
--------------------------------------------------------------------------------------------------------

-- EXAMPLE
-- Suppose we want to find the films whose rental rate is higher than the average rental rate.

-- QUERY 1
-- Subquery
SELECT
	film_id,
	title,
	rental_rate
FROM
	film
WHERE
	rental_rate > (
		SELECT
			AVG (rental_rate)
		FROM
			film
	);

-- PostgreSQL executes the query that contains a subquery in the following sequence:
-- First, executes the subquery.
-- Second, gets the result and passes it to the outer query.
-- Third, executes the outer query.

-- QUERY 2
-- Subquery with IN
SELECT
	film_id,
	title
FROM
	film
WHERE
	film_id IN (
		SELECT
			inventory.film_id
		FROM
			rental
		INNER JOIN inventory ON inventory.inventory_id = rental.inventory_id
		WHERE
			return_date BETWEEN '2005-05-29' AND '2005-05-30'
		AND inventory.film_id = 471
	)
ORDER BY 1

-- La diferencia es que este con el INNER trae duplicados
SELECT
	inventory.film_id, film.title
FROM
	rental
INNER JOIN inventory ON inventory.inventory_id = rental.inventory_id
INNER JOIN film      ON film.film_id		   = inventory.film_id
WHERE
	return_date BETWEEN '2005-05-29' AND '2005-05-30'
AND inventory.film_id = 471
ORDER BY 1

	SELECT * FROM inventory WHERE film_id = 471 -- 7
	SELECT * FROM film 		WHERE film_id = 471 -- 1


-- QUERY 3
-- Subquery with EXISTS
-- A subquery can be an input of the EXISTS operator. If the subquery returns any row, the EXISTS operator returns true. 
-- If the subquery returns no row, the result of EXISTS operator is false.
-- The EXISTS operator only cares about the number of rows returned from the subquery, not the content of the rows
SELECT
	first_name,
	last_name
FROM
	customer
WHERE
	EXISTS (
		SELECT 1
		FROM   payment
		WHERE  payment.customer_id = customer.customer_id
		AND		customer_id = 1 
	);


SELECT customer_id, COUNT(*)
FROM   payment
GROUP BY customer_id
ORDER BY customer_id

	SELECT *
	FROM   payment
	WHERE  customer_id = 1
	
--------------------------------------------------------------------------------------------------------
-- SUBQUERIES + ANY
--------------------------------------------------------------------------------------------------------

-- The PostgreSQL ANY operator compares a value to a set of values returned by a subquery. 
-- In this syntax:

-- The subquery must return exactly one column.
-- The ANY operator must be preceded by one of the following comparison operator =, <=, >, <, > and <>
-- The ANY operator returns true if any value of the subquery meets the condition, otherwise, it returns false.
-- Note that SOME is a synonym for ANY, meaning that you can substitute SOME for ANY in any SQL statement.

-- Query 1
SELECT
    MAX( length )
FROM film
JOIN film_category
	USING(film_id)
GROUP BY category_id;

-- You can use this query as a subquery in the following statement that finds the films whose lengths are greater 
-- than or equal to the maximum length of any film category :
SELECT title
FROM film
WHERE length >= ANY(
    SELECT MAX( length )
    FROM film
    INNER JOIN film_category USING(film_id)
    GROUP BY  category_id );

-- Query 2
-- ANY vs. IN
-- The = ANY is equivalent to IN operator.
-- The following example gets the film whose category is either Action or Drama.
SELECT
    title,
    category_id
FROM film
JOIN film_category
	USING(film_id)
WHERE category_id = ANY
	(SELECT	category_id
	 FROM   category
     WHERE  NAME = 'Action'
     OR 	NAME = 'Drama');

	SELECT
		title,
		category_id
	FROM film
	JOIN film_category
		USING(film_id)
	WHERE category_id IN
		(SELECT	category_id
		 FROM   category
		 WHERE  NAME = 'Action'
		 OR 	NAME = 'Drama');

--------------------------------------------------------------------------------------------------------
-- SUBQUERIES + ALL
--------------------------------------------------------------------------------------------------------

/*****************************************************************************************************************************
-- In this syntax:
The ALL operator must be preceded by a comparison operator such as equal (=), not equal (!=), greater than (>), greater than
or equal to (>=), less than (<), and less than or equal to (<=).
The ALL operator must be followed by a subquery which also must be surrounded by the parentheses.
With the assumption that the subquery returns some rows, the ALL operator works as follows:

column_name > ALL (subquery) the expression evaluates to true if a value is greater than the biggest value returned by the 
subquery.

column_name >= ALL (subquery) the expression evaluates to true if a value is greater than or equal to the biggest value 
returned by the subquery.

column_name < ALL (subquery) the expression evaluates to true if a value is less than the smallest value returned by the 
subquery.

column_name <= ALL (subquery) the expression evaluates to true if a value is less than or equal to the smallest value 
returned by the subquery.

column_name = ALL (subquery) the expression evaluates to true if a value is equal to any value returned by the subquery.

column_name != ALL (subquery) the expression evaluates to true if a value is not equal to any value returned by the subquery.

In case the subquery returns no row, then the ALL operator always evaluates to true.
*****************************************************************************************************************************/

-- The following query returns the average lengths of all films grouped by film rating:

SELECT ROUND(AVG(length), 2) avg_length
FROM   film
GROUP BY rating
ORDER BY avg_length DESC;

-- To find all films whose lengths are greater than the list of the average lengths above, you use the ALL and greater 
-- than operator (>) as follows:
SELECT film_id, title, length
FROM film
WHERE length > ALL 
	( SELECT ROUND(AVG (length),2)
      FROM   film
	  GROUP BY rating )
ORDER BY length;

120.44
118.66
113.23
112.01
111.05

--	select length from film where length > 120

--------------------------------------------------------------------------------------------------------
-- SUBQUERIES + EXISTS
--------------------------------------------------------------------------------------------------------

/****************************************************************************************************************************
The EXISTS operator is a boolean operator that tests for existence of rows in a subquery.
The EXISTS accepts an argument which is a subquery.

If the subquery returns at least one row, the result of EXISTS is true. In case the subquery returns no row, the result is of 
EXISTS is false.

The EXISTS operator is often used with the correlated subquery.

The result of EXISTS operator depends on whether any row returned by the subquery, and not on the row contents. Therefore, 
columns that appear on the SELECT clause of the subquery are not important.
****************************************************************************************************************************/


-- Query 1
-- Find customers who have at least one payment whose amount is greater than 11.
SELECT first_name, last_name
FROM   customer c
WHERE EXISTS (  SELECT 1
				FROM   payment p
				WHERE  p.customer_id = c.customer_id
				AND    amount > 11  )
ORDER BY first_name,  last_name;

-- Query 2
-- NOT EXISTS example
-- The NOT operator negates the result of the EXISTS operator. The NOT EXISTS is opposite to EXISTS. It means that if the 
-- subquery returns no row, the NOT EXISTS returns true. If the subquery returns one or more rows, the NOT EXISTS 
-- returns false.

-- The following example returns customers have not made any payment that greater than 11.
SELECT first_name, last_name
FROM   customer c
WHERE NOT EXISTS (  SELECT 1
					FROM   payment p
					WHERE  p.customer_id = c.customer_id
					AND    amount > 11 )
ORDER BY first_name, last_name;

-- Query 3
-- EXISTS and NULL
-- If the subquery returns NULL, EXISTS returns true. See the following example:
SELECT first_name, last_name
FROM   customer
WHERE  EXISTS ( SELECT NULL )
ORDER BY first_name, last_name;

-- In this example, the subquery returned NULL, therefore, the query returned all rows from the customer table.


-----------------------------------------------------------------------------------------------------------------------------
-- CTE
-----------------------------------------------------------------------------------------------------------------------------

A common table expression is a temporary result set which you can reference within another SQL statement including SELECT, 
INSERT, UPDATE or DELETE.
Common Table Expressions are temporary in the sense that they only exist during the execution of the query.
The following shows the syntax of creating a CTE:

	WITH cte_name (column_list) AS (
		CTE_query_definition 
	)
	statement;

Common Table Expressions or CTEs are typically used to simplify complex joins and subqueries in PostgreSQL.

-- Query 1
WITH cte_film AS (
    SELECT 
        film_id, 
        title,
        (CASE 
            WHEN length < 30 THEN 'Short'
            WHEN length < 90 THEN 'Medium'
            ELSE 'Long'
        END) length    
    FROM
        film
)
SELECT film_id, title, length
FROM   cte_film
WHERE  length = 'Long'
ORDER BY title; 
	
-- Query 2
-- The following statement illustrates how to join a CTE with a table:
WITH cte_rental AS (
    SELECT staff_id, COUNT(rental_id) rental_count
    FROM   rental
    GROUP  BY staff_id
)
SELECT s.staff_id, first_name, last_name, rental_count
FROM   staff s
JOIN   cte_rental 
	USING (staff_id); 

-- Query 3
-- Using CTE with a window function example
-- The following statement illustrates how to use the CTE with the RANK() window function:
WITH cte_film AS  (
    SELECT film_id, title, rating, length,
        RANK() OVER (PARTITION BY rating ORDER BY length DESC) length_rank
    FROM film 
)
SELECT *
FROM  cte_film
WHERE length_rank = 1;

/*****************************************************************************************************************************
PostgreSQL CTE advantages
The following are some advantages of using common table expressions or CTEs:

Improve the readability of complex queries. You use CTEs to organize complex queries in a more organized and readable manner.
Ability to create recursive queries. Recursive queries are queries that reference themselves. The recursive queries come in 
handy when you want to query hierarchical data such as organization chart or bill of materials.

Use in conjunction with window functions. You can use CTEs in conjunction with window functions to create an initial result 
set and use another select statement to further process this result set.
*****************************************************************************************************************************/


-----------------------------------------------------------------------------------------------------------------------------
-- RECURSIVE QUERY
-----------------------------------------------------------------------------------------------------------------------------

/****************************************************************************************************************************
A recursive query is a query that refers to a recursive CTE. The recursive queries are useful in many situations such as 
querying hierarchical data like organizational structure, bill of materials, etc.

The following illustrates the syntax of a recursive CTE:

WITH RECURSIVE cte_name AS(
    CTE_query_definition -- non-recursive term
    UNION [ALL]
    CTE_query definion  -- recursive term
) SELECT * FROM cte_name;

A recursive CTE has three elements:

Non-recursive term: the non-recursive term is a CTE query definition that forms the base result set of the CTE structure.
Recursive term: the recursive term is one or more CTE query definitions joined with the non-recursive term using the UNION 
or UNION ALL operator. The recursive term references the CTE name itself.
Termination check: the recursion stops when no rows are returned from the previous iteration.
PostgreSQL executes a recursive CTE in the following sequence:

Execute the non-recursive term to create the base result set (R0).
Execute recursive term with Ri as an input to return the result set Ri+1 as the output.
Repeat step 2 until an empty set is returned. (termination check)
Return the final result set that is a UNION or UNION ALL of the result set R0, R1, … Rn
PostgreSQL recursive query example

CREATE TABLE employees_cte (
	employee_id SERIAL  PRIMARY KEY,
	full_name 	VARCHAR NOT NULL,
	manager_id 	INT
);

INSERT INTO employees_cte (employee_id, full_name, manager_id)
VALUES
	(1, 'Michael North', NULL),
	(2, 'Megan Berry', 1),
	(3, 'Sarah Berry', 1),
	(4, 'Zoe Black', 1),
	(5, 'Tim James', 1),
	(6, 'Bella Tucker', 2),
	(7, 'Ryan Metcalfe', 2),
	(8, 'Max Mills', 2),
	(9, 'Benjamin Glover', 2),
	(10, 'Carolyn Henderson', 3),
	(11, 'Nicola Kelly', 3),
	(12, 'Alexandra Climo', 3),
	(13, 'Dominic King', 3),
	(14, 'Leonard Gray', 4),
	(15, 'Eric Rampling', 4),
	(16, 'Piers Paige', 7),
	(17, 'Ryan Henderson', 7),
	(18, 'Frank Tucker', 8),
	(19, 'Nathan Ferguson', 8),
	(20, 'Kevin Rampling', 8);

https://www.postgresqltutorial.com/postgresql-recursive-query/
****************************************************************************************************************************/

SELECT * FROM employees_cte
WHERE  employee_id = 2

-- The following query returns all subordinates of the manager with the id 2.
WITH RECURSIVE subordinates AS (
	-- Esto trae 1 solo registro "Megan Berry"
	SELECT employee_id, manager_id, full_name
	FROM   employees_cte
	WHERE  employee_id = 2
		UNION
	SELECT e.employee_id, e.manager_id, e.full_name
	FROM   employees_cte e
	JOIN   subordinates s
	ON     s.employee_id = e.manager_id
) 
SELECT *
FROM   subordinates;



---------------------------------------------------------------------------------------------------------------------------------------
-- INSERT
---------------------------------------------------------------------------------------------------------------------------------------

/**************************************************************************************************************
-- RETURNING clause
The INSERT statement also has an optional RETURNING clause that returns the information of the inserted row.

If you want to return the entire inserted row, you use an asterisk (*) after the RETURNING keyword:

INSERT INTO table_name(column1, column2, …)
VALUES (value1, value2, …)
RETURNING *;

If you want to return just some information of the inserted row, you can specify one or more columns after the RETURNING clause.

For example, the following statement returns the id of the inserted row:

INSERT INTO table_name(column1, column2, …)
VALUES (value1, value2, …)
RETURNING id;
Code language: SQL (Structured Query Language) (sql)
To rename the returned value, you use the AS keyword followed by the name of the output. For example:

INSERT INTO table_name(column1, column2, …)
VALUES (value1, value2, …)
RETURNING output_expression AS output_name;
**************************************************************************************************************/

DROP TABLE IF EXISTS links;
CREATE TABLE links (
	id 			SERIAL PRIMARY KEY	 ,
	url 		VARCHAR(255) NOT NULL,
	name 		VARCHAR(255) NOT NULL,
	description VARCHAR(255)		 ,
	last_update DATE
);

-- Query 1
INSERT INTO links (url, name)
VALUES('https://www.postgresqltutorial.com','PostgreSQL Tutorial');

-- Query 2
-- PostgreSQL INSERT – Inserting character string that contains a single quote
INSERT INTO links (url, name)
VALUES('http://www.oreilly.com','O''Reilly Media');
	SELECT * FROM links 

-- Query 3
-- INSERT – Inserting a date value
INSERT INTO links (url, name, last_update)
VALUES('https://www.google.com','Google','2013-06-01');
	SELECT * FROM links 

-- Query 4
-- INSERT- Getting the last insert id
INSERT INTO links (url, name)
VALUES('http://www.postgresql.org','PostgreSQL') 
RETURNING id;

-- Query 5
-- INSERT Multiple Rows
-- To insert multiple rows into a table using a single INSERT statement, you use the following syntax:

-- INSERT INTO table_name (column_list)
-- VALUES
--     (value_list_1),
--     (value_list_2),
--     ...
--     (value_list_n);

-- To insert multiple rows and return the inserted rows, you add the RETURNING clause as follows:

-- INSERT INTO table_name (column_list)
-- VALUES
--     (value_list_1),
--     (value_list_2),
--     ...
--     (value_list_n)
-- RETURNING * | output_expression;

INSERT INTO links (url, name)
VALUES
    ('https://www.google.com','Google'),
    ('https://www.yahoo.com','Yahoo'),
    ('https://www.bing.com','Bing');

	SELECT * FROM links

INSERT INTO links(url,name, description)
VALUES
    ('https://duckduckgo.com/','DuckDuckGo','Privacy & Simplified Search Engine'),
    ('https://swisscows.com/','Swisscows','Privacy safe WEB-search')
RETURNING *;

INSERT INTO links(url,name, description)
VALUES
    ('https://www.searchencrypt.com/','SearchEncrypt','Search Encrypt'),
    ('https://www.startpage.com/','Startpage','The world''s most private search engine')
RETURNING id;


---------------------------------------------------------------------------------------------------------------------------------------
-- UPDATE
---------------------------------------------------------------------------------------------------------------------------------------

-- Returning updated rows
-- UPDATE table_name
-- SET column1 = value1,
--     column2 = value2,
--     ...
-- WHERE condition
-- RETURNING * | output_expression AS output_name;

DROP TABLE IF EXISTS courses;

CREATE TABLE courses(
	course_id serial primary key,
	course_name VARCHAR(255) NOT NULL,
	description VARCHAR(500),
	published_date date
);

INSERT INTO courses(course_name, description, published_date)
VALUES
	('PostgreSQL for Developers','A complete PostgreSQL for Developers','2020-07-13'),
	('PostgreSQL Admininstration','A PostgreSQL Guide for DBA',NULL),
	('PostgreSQL High Performance',NULL,NULL),
	('PostgreSQL Bootcamp','Learn PostgreSQL via Bootcamp','2013-07-11'),
	('Mastering PostgreSQL','Mastering PostgreSQL in 21 Days','2012-06-30');

SELECT * FROM courses

CREATE TABLE product_segment (
    id SERIAL PRIMARY KEY,
    segment VARCHAR NOT NULL,
    discount NUMERIC (4, 2)
);

INSERT INTO product_segment (segment, discount)
VALUES
    ('Grand Luxury', 0.05),
    ('Luxury', 0.06),
    ('Mass', 0.1);

SELECT * FROM product_segment

CREATE TABLE product(
    id SERIAL PRIMARY KEY,
    name VARCHAR NOT NULL,
    price NUMERIC(10,2),
    net_price NUMERIC(10,2),
    segment_id INT NOT NULL,
    FOREIGN KEY(segment_id) REFERENCES product_segment(id)
);

INSERT INTO product (name, price, segment_id) 
VALUES 
    ('diam', 804.89, 1),
    ('vestibulum aliquet', 228.55, 3),
    ('lacinia erat', 366.45, 2),
    ('scelerisque quam turpis', 145.33, 3),
    ('justo lacinia', 551.77, 2),
    ('ultrices mattis odio', 261.58, 3),
    ('hendrerit', 519.62, 2),
    ('in hac habitasse', 843.31, 1),
    ('orci eget orci', 254.18, 3),
    ('pellentesque', 427.78, 2),
    ('sit amet nunc', 936.29, 1),
    ('sed vestibulum', 910.34, 1),
    ('turpis eget', 208.33, 3),
    ('cursus vestibulum', 985.45, 1),
    ('orci nullam', 841.26, 1),
    ('est quam pharetra', 896.38, 1),
    ('posuere', 575.74, 2),
    ('ligula', 530.64, 2),
    ('convallis', 892.43, 1),
    ('nulla elit ac', 161.71, 3);
	
SELECT * FROM product;

-- Query 1
UPDATE  courses
SET 	published_date = '2020-07-01'
WHERE 	course_id = 2
RETURNING *;

-- Query 2
UPDATE 	product
SET 	net_price = price - price * discount
FROM 	product_segment
WHERE 	product.segment_id = product_segment.id
RETURNING *


---------------------------------------------------------------------------------------------------------------------------------------
-- DELETE
---------------------------------------------------------------------------------------------------------------------------------------

DELETE FROM table_name
WHERE condition
RETURNING (select_list | *)

DROP TABLE IF EXISTS links;

CREATE TABLE links (
    id serial PRIMARY KEY,
    url varchar(255) NOT NULL,
    name varchar(255) NOT NULL,
    description varchar(255),
    rel varchar(10),
    last_update date DEFAULT now()
);

INSERT INTO  links 
VALUES 
   ('1', 'https://www.postgresqltutorial.com', 'PostgreSQL Tutorial', 'Learn PostgreSQL fast and easy', 'follow', '2013-06-02'),
   ('2', 'http://www.oreilly.com', 'O''Reilly Media', 'O''Reilly Media', 'nofollow', '2013-06-02'),
   ('3', 'http://www.google.com', 'Google', 'Google', 'nofollow', '2013-06-02'),
   ('4', 'http://www.yahoo.com', 'Yahoo', 'Yahoo', 'nofollow', '2013-06-02'),
   ('5', 'http://www.bing.com', 'Bing', 'Bing', 'nofollow', '2013-06-02'),
   ('6', 'http://www.facebook.com', 'Facebook', 'Facebook', 'nofollow', '2013-06-01'),
   ('7', 'https://www.tumblr.com/', 'Tumblr', 'Tumblr', 'nofollow', '2013-06-02'),
   ('8', 'http://www.postgresql.org', 'PostgreSQL', 'PostgreSQL', 'nofollow', '2013-06-02');
   
select * from links 

-- Query 1
DELETE FROM links
WHERE  id = 7
RETURNING *;

-- Query 2
DELETE FROM links
WHERE id IN (6,5)
RETURNING *;



---------------------------------------------------------------------------------------------------------------------------------------
-- UPSERT
---------------------------------------------------------------------------------------------------------------------------------------

/**************************************************************************************************************************************
To use the upsert feature in PostgreSQL, you use the INSERT ON CONFLICT statement as follows:

INSERT INTO table_name(column_list) 
VALUES(value_list)
ON CONFLICT target action;

In this statement, the target can be one of the following:

 (column_name) – a column name.
 ON CONSTRAINT constraint_name – where the constraint name could be the name of the UNIQUE constraint.
 WHERE predicate – a WHERE clause with a predicate.
The action can be one of the following:

 DO NOTHING – means do nothing if the row already exists in the table.
 DO UPDATE SET column_1 = value_1, .. WHERE condition – update some fields in the table.
**************************************************************************************************************************************/

DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
	customer_id SERIAL  PRIMARY KEY	,
	name 		VARCHAR UNIQUE		,
	email 		VARCHAR NOT NULL	,
	active 		BOOL 	NOT NULL DEFAULT TRUE
);

INSERT INTO customers (name, email)
VALUES 
    ('IBM', 'contact@ibm.com'),
    ('Microsoft', 'contact@microsoft.com'),
    ('Intel', 'contact@intel.com');
	
SELECT * FROM customers;

-- Query 1
-- Suppose Microsoft changes the contact email from contact@microsoft.com to hotline@microft.com, we can update it using the 
-- UPDATE statement. However, to demonstrate the upsert feature, we use the following INSERT ON CONFLICT statement:
INSERT INTO customers (NAME, email)
VALUES('Microsoft', 'hotline@microsoft.com')
ON CONFLICT ON CONSTRAINT customers_name_key
DO NOTHING;

-- The following statement is equivalent to the above statement but it uses the name column instead of the unique constraint 
-- name as the target of the INSERT statement.
INSERT INTO customers (name, email)
VALUES('Microsoft','hotline@microsoft.com') 
ON CONFLICT (name) 
DO NOTHING;


-- Query 2
-- Suppose, you want to concatenate the new email with the old email when inserting a customer that already exists, in this case, 
-- you use the UPDATE clause as the action of the INSERT statement as follows:

INSERT INTO customers (name, email)
VALUES('Microsoft','hotline@microsoft.com') 
ON CONFLICT (name) 
DO 
   UPDATE SET email = EXCLUDED.email || ';' || customers.email;

SELECT * FROM  customers



------------------------------------------------------------------------------------------------------------------------------------
-- TRANSACTION
------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS accounts;

CREATE TABLE accounts (
    id INT GENERATED BY DEFAULT AS IDENTITY,
    name VARCHAR(100) NOT NULL,
    balance DEC(15,2) NOT NULL,
    PRIMARY KEY(id)
);

-- QUERY 1
BEGIN;

INSERT INTO accounts(name,balance)
VALUES('Alice',10000);

COMMIT;

-- QUERY 2
BEGIN;

UPDATE 	accounts 
SET	 	balance = balance - 1000
WHERE id = 2;

UPDATE 	accounts
SET	 	balance = balance + 1000
WHERE id = 1; 

COMMIT;


-- QUERY 3
INSERT INTO accounts(name, balance)
VALUES('Jack',0);   

BEGIN;

	UPDATE 	accounts 
	SET 	balance = balance - 1500
	WHERE id = 1;

	UPDATE 	accounts
	SET 	balance = balance + 1500
	WHERE id = 3; 

ROLLBACK;


--------------------------------------------------------------------------------------------------------------------------------
-- IMPORT
--------------------------------------------------------------------------------------------------------------------------------

-- IMPORT A CSV FILE INTO A TABLE USING COPY STATEMENT
CREATE TABLE persons (
  id 			SERIAL,
  first_name 	VARCHAR(50),
  last_name 	VARCHAR(50),
  dob 			DATE,
  email 		VARCHAR(255),
  PRIMARY KEY (id)
)

-- Query 1
COPY persons(first_name, last_name, dob, email)
FROM 'C:\persons.csv'
DELIMITER ','
CSV HEADER;

SELECT * FROM persons

-- Query 2
-- Import CSV file into a table using pgAdmin
-- Ver imagenes!

--------------------------------------------------------------------------------------------------------------------------------
-- EXPORT
--------------------------------------------------------------------------------------------------------------------------------

-- Export data from a table to CSV using COPY statement
COPY persons TO 'D:\persons_db.csv' DELIMITER ',' CSV HEADER;


-- In some cases, you want to export data from just some columns of a table to a CSV file. To do this, you specify the column 
-- names together with table name after COPY keyword. For example, the following statement exports data from the first_name, 
-- last_name, and email  columns of the persons table to person_partial_db.csv
COPY persons(first_name,last_name,email) 
TO 'D:\persons_partial_db.csv' DELIMITER ',' CSV HEADER;


-- If you don’t want to export the header, which contains the column names of the table, just remove the HEADER flag in the 
-- COPY statement. The following statement exports only data from the email column of the persons table to a CSV file.
COPY persons(email) 
TO 'C:\tmp\persons_email_db.csv' DELIMITER ',' CSV;

-- Export data from a table to CSV file using the \copy command
-- In case you have the access to a remote PostgreSQL database server, but you don’t have sufficient privileges to write to a file 
-- on it, you can use the PostgreSQL built-in command \copy.
-- The \copy command basically runs the COPY statement above. However, instead of server writing the CSV file, psql writes the CSV 
-- file, transfers data from the server to your local file system. To use \copy command, you just need to have sufficient privileges 
-- to your local machine. It does not require PostgreSQL superuser privileges.

-- For example, if you want to export all data of the persons table into persons_client.csv file, you can execute the \copy command 
-- from the psql client as follows:

copy (SELECT * FROM persons WHERE first_name = 'Lucas' ) to 'D:\persons_client.csv' with CSV HEADER


--------------------------------------------------------------------------------------------------------------------------------
-- Data Type
--------------------------------------------------------------------------------------------------------------------------------



