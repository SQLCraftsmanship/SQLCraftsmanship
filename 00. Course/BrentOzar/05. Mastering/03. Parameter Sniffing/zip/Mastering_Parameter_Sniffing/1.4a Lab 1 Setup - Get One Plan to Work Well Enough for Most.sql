/*
Mastering Parameter Sniffing
Lab Setup: Get One Plan to Work Well Enough for Most

v1.2 - 2022-02-08

https://www.BrentOzar.com/go/mastersniffing


This demo requires:
* SQL Server 2017 or newer
* 2018-06 Stack Overflow database: https://www.BrentOzar.com/go/querystack

This first RAISERROR is just to make sure you don't accidentally hit F5 and
run the entire script. You don't need to run this:
*/
USE StackOverflow;
GO
EXEC DropIndexes @TableName = 'Users', @ExceptIndexNames = 'Location';
EXEC DropIndexes @TableName = 'Posts', @ExceptIndexNames = 'CreationDate,_dta_index_Posts_5_85575343__K8,IX_OwnerUserId,OwnerUserId';

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[Comments]') AND name = N'Score_UserId')
	CREATE INDEX Score_UserId ON dbo.Comments(Score, UserId) WITH (MAXDOP = 0);
GO
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 140; /* 2017, not 2019 yet */
GO
EXEC sys.sp_configure N'show advanced', 1;
GO
RECONFIGURE
GO
EXEC sys.sp_configure N'cost threshold for parallelism', N'50' /* Keep small queries serial */
GO
EXEC sys.sp_configure N'max degree of parallelism', N'4' /* Let queries go parallel */
GO
RECONFIGURE
GO
CREATE OR ALTER PROC dbo.usp_MostRecentCommentsForMe 
	@UserId INT, @MinimumCommenterReputation INT = 0, @MinimumCommentScore INT = 0 AS
BEGIN
/* Find the most recent comments on my posts */
SELECT TOP 100 pMine.Id AS MyPostId, u.DisplayName AS Commenter_DisplayName,
	u.Location AS Commenter_Location, u.Reputation AS Commenter_Reputation,
	c.CreationDate AS Comment_CreationDate,
	c.Score AS Comment_Score, c.Text AS Comment
FROM dbo.Posts pMine
	JOIN dbo.Comments c ON pMine.Id = c.PostId
	JOIN dbo.Users u ON c.UserId = u.Id
WHERE pMine.OwnerUserId = @UserId
	AND u.Reputation >= @MinimumCommenterReputation
	AND c.Score >= @MinimumCommentScore
ORDER BY c.CreationDate DESC;

END
GO



/*
License: Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
More info: https://creativecommons.org/licenses/by-sa/4.0/

You are free to:
* Share - copy and redistribute the material in any medium or format
* Adapt - remix, transform, and build upon the material for any purpose, even 
  commercially

Under the following terms:
* Attribution - You must give appropriate credit, provide a link to the license, 
  and indicate if changes were made. You may do so in any reasonable manner, 
  but not in any way that suggests the licensor endorses you or your use.
* ShareAlike - If you remix, transform, or build upon the material, you must
  distribute your contributions under the same license as the original.
*/