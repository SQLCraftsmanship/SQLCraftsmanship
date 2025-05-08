https://docs.microsoft.com/en-us/previous-versions/sql/sql-server-2008-r2/ms191278(v=sql.105)?redirectedfrom=MSDN
https://docs.microsoft.com/en-us/previous-versions/sql/sql-server-2008-r2/ms188023(v=sql.105)

SELECT
    mailitem_id,
    sent_status,
    send_request_date
FROM msdb.dbo.sysmail_allitems;
--SELECT * FROM msdb.dbo.sysmail_allitems;
--SELECT * FROM msdb..sysmail_mailitems WHERE sent_date > DATEADD(DAY, -1,GETDATE())
-- WHERE mailitem_id = <the mailitem_id from the previous step> ;

SELECT * FROM msdb.dbo.sysmail_event_log 
-- WHERE mailitem_id = <the mailitem_id from the previous step> ;

SELECT * FROM msdb.dbo.sysmail_faileditems

SELECT * FROM msdb.dbo.sysmail_unsentitems

USE msdb ;  
GO  
  
-- Show the subject, the time that the mail item row was last modified, and the log information. Join sysmail_faileditems to sysmail_event_log   
-- on the mailitem_id column. In the WHERE clause list items where danw was in the recipients, copy_recipients, or blind_copy_recipients.  
-- These are the items that would have been sent to danw.  
SELECT items.subject,  
    items.last_mod_date  
    ,l.description 
FROM dbo.sysmail_faileditems as items  
INNER JOIN dbo.sysmail_event_log AS l  
    ON items.mailitem_id = l.mailitem_id  
WHERE items.recipients LIKE '%danw%'    
    OR items.copy_recipients LIKE '%danw%'   
    OR items.blind_copy_recipients LIKE '%danw%'  
GO  

--  And here is the complete query to get all the failed emails from the past 24 hours:
SELECT items.subject ,
       items.recipients ,
       items.copy_recipients ,
       items.blind_copy_recipients ,
       items.last_mod_date ,
       l.description
FROM   msdb.dbo.sysmail_faileditems AS items
       LEFT OUTER JOIN msdb.dbo.sysmail_event_log AS l 
                    ON items.mailitem_id = l.mailitem_id
WHERE  items.last_mod_date > DATEADD(DAY, -7,GETDATE())
