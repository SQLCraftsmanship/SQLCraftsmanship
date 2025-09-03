# SQL Server Tips
<style>
r { color: red }
o { color: Orange }
g { color: Green }
lg { color: lightgreen }
b { color: Blue }
lb { color: lightblue }
</style>

> [!TIP]
> Use the command line to detect and resolve the errors!

> [!WARNING]
> DON'T DELETE THE `package.json` file!

> [!CAUTION]
> Don't execute the code without commenting the test cases.

> [!IMPORTANT]  
> Read the contribution guideline before adding a pull request.

# Index
  - [Original Post](#Original#Post)
  - [Cap 2](#)
  - [Cap 10](#)
  - [Cap 11](#)
  - [Cap 12](#)
---

* Original Post

How To Write SQL Server Queries Correctly: IN and NOT IN

https://www.youtube.com/watch?v=yQqtfw1Kuvw

Erik Darlin is an expert database administrator on SQL Server with a lot of years of experience. Nowadays, he performs duties as a consultant and trainer

* When do you use it?

You can use these when you have a list of literal values

* Drawback

You mast worry about whether a column on the outer side allows NULL value.
It's a best practice to use EXISTS / NOT EXISTS.

* Exampl

```sql
/* Create @good var table */
DECLARE @good TABLE (
    [id] INTEGER NULL
);

/* Create @bad  var table */
DECLARE @bad TABLE (
    [id] INTEGER NULL
);

INSERT INTO @good (id) VALUES(NULL)   ; /* change this value between NULL and 1 */
INSERT INTO @bad  (id) VALUES(NULL); /* change this value between NULL and 2 */

SELECT 
    records = COUNT_BIG(*) /* Should be 1*/
FROM @good AS g
WHERE g.id NOT IN
(
    SELECT b.id FROM @bad AS b
)

/*
Though each table allows NULLs in their single column, no NULL values will be inserted into them.

The real lesson here is that if you know that no NULL values are allowed into your tables, you should specify the columns as
NOT NULL.
*/

SET STATISTICS IO ON

CREATE TABLE #OldUsers (
    UserID INT NULL
);

CREATE TABLE #NewUsers (
    UserID INT NULL
);

/* But neither one will have any NULL value at all! */

/* This bring 40.700.647 amount of records*/
INSERT #OldUsers WITH(TABLOCK)(UserID)
SELECT p.OwnerUserId FROM dbo.Posts AS p
WHERE p.OwnerUserId IS NOT NULL;

/* This bring 65.722.799 amount of records*/
INSERT #NewUsers WITH(TABLOCK)(UserID)
SELECT c.UserId FROM dbo.Comments AS c
WHERE c.UserId IS NOT NULL;

/*
The big problem with NOT IN, is that SQL Server goes into defensive driving mode when you use it under NULLable conditions.

Here's an example of a bad way to deal with the situation, vs a good way to deal with the situation:
*/

/* Bad way */
SELECT 
    records = COUNT_BIG(*)
FROM #NewUsers AS nu
WHERE nu.UserId NOT IN
(
    SELECT  
        ou.UserId
    FROM #OldUsers AS ou
)

/* Good way */
SELECT 
    records = COUNT_BIG(*)
FROM #NewUsers AS nu
WHERE NOT EXISTS
(
    SELECT  
        1/0
    FROM #OldUsers AS ou
    WHERE nu.UserID = ou.UserId
)
```

* ASD