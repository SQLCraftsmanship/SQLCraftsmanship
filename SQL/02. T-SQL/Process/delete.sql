
/* Optimizing Delete on SQL Server */

-- Brent aticulo
https://www.brentozar.com/archive/2018/04/how-to-delete-just-some-rows-from-a-really-big-table/

de donde saque muchas ideas


-- Suggestions for the aticle
Podria armar un modelo de base de datos para hacer esto del DELETE/DROP/TRUNCATE algo como en esta pagina
    https://www.sqlshack.com/learn-sql-sql-best-practices-for-deleting-and-updating-data/

    Por lo general se una estructura de logging. La app logea todo lo que mas pueda y despues tiene que eliminar registros a lo
    loco

llamarlo como hace SQLServerCentral ... Stairways

-- Suggestions

1. Be sure foreign keys have indexes
2. Be sure the WHERE conditions are indexed
3. Use of WITH ROWLOCK
4. Destroy unused indexes, delete, rebuild the indexes

Performing fast SQL Server delete operations
    https://www.johnsansom.com/fast-sql-server-delete/
    https://web.archive.org/web/20100212155407/http://blogs.msdn.com/sqlcat/archive/2009/05/21/fast-ordered-delete.aspx


For single user optimization
    1. Hint a TABLELOCK
    2. Remove indexes not used in the delete then rebuild them afterward
    3. Batch using something like SET ROWCOUNT 20000 (or whatever, depending on log space) and loop (perhaps with a WAITFOR DELAY) until you get rid of it all (@@ROWCOUNT = 0)
    4. If deleting a large % of table, just make a new one and delete the old table
    5. Partition the rows to delete, then drop the partition. Read more...

For multi user optimization
    1. Hint row locks
    2. Use the clustered index
    3. Design clustered index to minimize page re-organization if large blocks are deleted
    4. Update "is_deleted" column, then do actual deletion later during a maintenance window

For general optimization
    1. Be sure FKs have indexes on their source tables
    2. Be sure WHERE clause has indexes
    3. Identify the rows to delete in the WHERE clause with a view or derived table instead of referencing the table directly

Deleting a row means at least three things: a) making sure no foreign key constraint is violated by the deletion b) marking the space 
occupied by the row as "available". c) removing the row from all indexes on that table. Of these, a) can be the most expensive 
(if the referencing tables do not have an index on the foreign key columns) but it should be done immediately, so you can tell the user 
"you can't delete this row, it's still referenced". b) is probably cheap and c) is usually not that expensive. Therefore, I'm not 
convinced of this idea.

My suggestions:

    1. Make sure that the table has a primary key and clustered index (this is vital for all operations).
    2. Make sure that the clustered index is such that minimal page re-organisation would occur if a large block of rows were to be deleted.
    3. Make sure that your selection criteria are SARGable (*).
    4. Make sure that all your foreign key constraints are currently trusted.

(*)
SARGable:In relational databases, a condition (or predicate) in a query is said to be sargable if the DBMS engine can take advantage of 
an index to speed up the execution of the query (using index seeks, not covering indexes). The term is derived from a contraction of 
Search ARGument Able. 


Seria bueno preguntarse que tipo de DB tenemos que trabajar primero? (OLTP/OLAP)
Cuando lo corremos? solos o en alguna windows maintenance?
Es una tabla o muchas?
Es una tabla grande o chica?
Es una tabla con HEAP, PK, etc? Que tipo de indices tiene esta tabla?
Que tipo de datos tiene la tabla? (JSON, NVARCHAR(MAX), TEXT, etc) Tiene tipo de datos grandes?
Tenes que deleter solamente o archivar y deletear?
Que es lo que estamos intentando optimizar? El proceso de DELETE/Archiving o la utilizacion de la tabla para los usuarios? (Or, are you 
trying to optimize for user experience or speed of getting your query done?)
Tenemos que tener en cuanta el ISOLATIONS LEVEL?
Are you using partitioning on the table/s?

Esto comentario:
    I think, the big trap with delete that kill the performance is that sql after each row deleted, it updates all the related indexes 
    for any column in this row. what about delting all indexes before bulk delete?
Es el que me hizo pensar en que tiene eazon ... la pregunta para aprender tambien es:
    QUE ES LO QUE HACE EL SQL LUEGO DE HACER EL DELETE/DROP/TRUNCATE?

Lo que me lleva a otra pregunta... lo que estas haciendo es un DELETE/DROP/TRUNCATE?

Tenes TRIGGERS?
Not use functions on the WHERE clause'

Como esta el modo de la db? SIMPLE, FULL, BULKED, ETC
Que tama;o tiene el transaction log? Tiene espacio libre? etc
Cada cuanto se hace el backup?
Estas ejecutando un Shrink?
Use try catch
Use a SP
Is it indexed?  If not, then you will most likely end up doing table scans which we all want to avoid.
Don't use cursor if you can emulate cursor is better
Avoid large transactions that can lock the table and take forever to complete. 

Not quite the same situation, but it shares some similarities with this article, in which Brent Ozar uses views to implement deletes 
from very large tables to avoid memory grant and sort spill issues.'


Some Scripts examples
declare @C int
Set @C = 0
while Exists ( select top 1 * from bigtable where [date]< '1 jan 2010' )
begin
Set @C = @C+1
begin tran
insert into _andrew (Data) values (@c)
commit tran
begin tran
delete top (1000000) from
bigtable
where
[date]< '1 jan 2010'
commit tran
end

The log table looks like this:
CREATE TABLE [dbo].[_andrew](
[Id] [int] IDENTITY(1,1) NOT NULL,
[Data] [int] NOT NULL,
[Time] [datetime] NOT NULL CONSTRAINT [DF__andrew_Time] DEFAULT (getdate()),

 CONSTRAINT [PK__andrew] PRIMARY KEY CLUSTERED
(
    [Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

mismo script pero mejorado
declare @C int
Set @C = 0
SET ROWCOUNT 1000000
DECLARE @deleted int
SET @deleted = 1000000
WHILE @deleted = 1000000
begin
Set @C = @C+1
begin tran
insert into _andrew (Data) values (@c)
commit tran
begin tran
delete from
BigTable
where
id < 171805215
SET @DELETED = @@ROWCOUNT
commit tran
end'

Tipos de cursores
I believe that the fast forward cursor of SQL Server is a great tool to use if, and only if, multiple actions need to be taken on each record returned. 
Cursors should not be declared always bad just like a baseball bat should not be declared always bad.  It is how the tool is used that is good or bad.  
A bat is usually good when used in baseball and usually bad when committing a crime.'  

Una solucion si podemos rehacer la tabla entera seria:
We had the same  problem today.

I wrote a script that does the following:

    Starts a transaction
    retrieves the last id number of the table
    uses sp_rename to rename the PK, indexes and constraints on the table
    sp_renames the table
    executes the create table script for the table to create a new, empty log table
    reseed the Log_ID to one more than the value retrieved before renaming
    end the transaction (rollback for testing, commit when it runs clean)
    The script cleaned up 36 million records in a fraction of a second.


A little more code:
Here is a simple code I use for handling such deletes.
Declare @CT INT -- variable used to compute number of records to be deleted
Set @CT = (select count(ID) from table where CreateDate < GetDate()-60)
While @CT > 0
Begin
Delete top 4000 from Table where CreateDate < Getdate() -60
Set @CT = @CT -4000
End


una sugerencia valida
Another suggestion is: don't the table accumulate 10s or 100s of millions of rows. Use a job to truncate off-hours on a daily or weekly schedule.

original post https://www.sqlservercentral.com/articles/how-to-delete-large-amounts-of-data

-----------------------------------------------------------------------------------------------------------------------------------------------------------'

From Brent Ozar
https://www.brentozar.com/archive/2018/04/how-to-delete-just-some-rows-from-a-really-big-table/

It’s especially painful if you need to do regular archiving jobs, like deleting the oldest 30 days of data from a table with 10 years of data in it.

The trick is making a view that contains the top, say, 1,000 rows that you want to delete:

CREATE VIEW dbo.Comments_ToBeDeleted AS
    SELECT TOP 1000 *
    FROM dbo.Comments
    ORDER BY CreationDate;
GO

And then deleting from the view, not the table:

DELETE dbo.Comments_ToBeDeleted
  WHERE CreationDate < '2010-01-01';


https://www.brentozar.com/archive/2018/04/how-to-delete-just-some-rows-from-a-really-big-table/

...
...
...

dentro de un comentario de brent dice
You can also use a CTE.

WITH Comments_ToBeDeleted AS (
SELECT TOP 1000 *
FROM dbo.Comments
ORDER BY CreationDate
)
DELETE FROM Comments_ToBeDeleted
WHERE CreationDate < '2010-01-01';

I don't have the stack overflow database, but in my tests if you move the where clause inside the cte, it changes the non clustered index scan to a seek. But that didn't seem to affect the performance.

Reply

Brent Ozar
April 28, 2018 4:35 am
Nicholas – I just tested that in Stack, and it’s a nonclustered index scan (not seek), but it’s a good scan in the sense that it doesn’t read the entire table – only enough rows to achieve the goal. 
Estimated number of rows to be read is in the tens of millions, but the actual number of rows is only 1000 – so in this case, the scan is fine. I’d be totally fine with the CTE. Nice work!

otro comentario
Robert Mackenzie
April 28, 2018 8:10 am
We do something similar but without the view (and constant clicking). This gets it done in one swoop without taking huge locks. You can stop the query any time you need to and continue it until it’s 
done. I’ll test it on the SO but would imagine it uses the exact same query plan.

declare @rowCount int = -1;
while(@rowCount 0) begin
delete top 1000 dbo.Comments
where CreationDate < '2010-01-01';
set @rowCount = @@rowCount;
end

Reply

Brent Ozar
April 28, 2018 8:19 am
Robert – yeah, the problem I’ve run into with that is that someone tweaks that TOP number, goes past 5000 thinking they’re going to get ‘er done faster, and whammo, you get table locks. If you put 
it in a view, you make it less likely that someone’s going to change the object (assuming it’s locked down for permissions) and it forces them to keep their locks small. I like the idea though!

Otro comentario
Henrik Staun Poulsen
April 30, 2018 1:37 am
Brent,
I hate the IX_CreationDate index.

Bit here is a case where “Know your data” applies.
Often there is a correlation between CommentsID and CreationDate.
This can be used if you just want to trim down your table.
Something like this:
DECLARE @lower BIGINT
SELECT TOP (1) @lower = CommentsId FROM dbo.Comments ORDER BY CommentsId
DELETE TOP (1000) FROM dbo.Comments WITH (ROWLOCK)
WHERE CommentsId>=@lower AND CommentsId < @lower+1000
AND CreationDate< DATEADD(YEAR, -3, GETUTCDATE())

Then you do not need that extra index on CreationDate, which I find is an important save of I/Os.

Reply

Brent Ozar
April 30, 2018 5:43 am
Henrik – yep, that’s true too! We cover that in our Mastering Query Tuning classes. (Just only so deep I can go in one blog post – holy cow, y’all want me to write a book on this, apparently, hahaha.)


More options query to run the delete
(Let ‘s see if this posts the code properly) Here’s the version we use. The idea was someone else’s (I wish I knew who, so I could cite), but works overall quite well.

It uses the CTE to do the delete as mentioned by Nicholas above, but with the added advantage that it’s constantly narrowing the window it queries.

This is the link with the correct code
https://thebakingdba.blogspot.com/2015/01/t-sql-more-efficient-delete-using-top.html




Otro post interesante
Thanks Brent. I use the technique via CTE for some time and it works correctly, cycling through blocks <5000 records (for safety) and scheduling the procedure every N hours.
However, I had the problem of growth of the transaction log, which I absolutely must keep under control to avoid storage saturation.
To achieve this I've defined a maximum size of the log file (e.g. 50GB) and at each iteration I check the actual size of the file (using SELECT used_log_space_in_bytes FROM sys.dm_db_log_space_usage).
If the size exceeds the maximum size, the procedure stops.
The next log backup performs the truncation and the next execution of the procedure can continue with the deletion.'




--------------------------------------------------------------------------------------------------------------------------------------------------------

SQLCAT blog post
Entiendo que es un blod de desarrolladores de SQL Server?

--------------------------------------------------------------------------------------------------------------------------------------------------------

https://michaeljswart.com/2014/09/take-care-when-scripting-batches/

TAKE CARE WHEN SCRIPTING batches
