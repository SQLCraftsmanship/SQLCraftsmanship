/*
Mastering Parameter Sniffing
Lab: Tracking Down Parameter Sniffing in the Plan Cache History

v1.2 - 2022-06-12

https://www.BrentOzar.com/go/mastersniffing


This demo requires:
* SQL Server 2017 or newer
* 2018-06 Stack Overflow database: https://www.BrentOzar.com/go/querystack
*/
USE StackOverflow;
GO
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 140; /* 2017, not 2019 yet */
GO
EXEC sys.sp_configure N'cost threshold for parallelism', N'50' /* Keep small queries serial */
GO
EXEC sys.sp_configure N'max degree of parallelism', N'4' /* Let queries go parallel */
GO
RECONFIGURE
GO
ALTER DATABASE [StackOverflow] SET QUERY_STORE = ON
GO
ALTER DATABASE [StackOverflow] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, 
DATA_FLUSH_INTERVAL_SECONDS = 60, INTERVAL_LENGTH_MINUTES = 1, QUERY_CAPTURE_MODE = AUTO)
GO
/* If you're on 2017 or older, comment this out: */
ALTER DATABASE SCOPED CONFIGURATION SET LAST_QUERY_PLAN_STATS = ON;
GO


CREATE OR ALTER PROC dbo.usp_SearchPostsByLocation 
	@Location VARCHAR(100), @StartDate DATETIME, @EndDate DATETIME AS
BEGIN
/* Find the most recent posts from an area */
SELECT TOP 200 u.DisplayName, p.Title, p.Id, p.CreationDate
  FROM dbo.Posts p
  INNER JOIN dbo.Users u ON p.OwnerUserId = u.Id
  WHERE u.Location LIKE @Location
    AND p.CreationDate BETWEEN @StartDate AND @EndDate
  ORDER BY p.CreationDate DESC;
END
GO

IF 'Question' <> (SELECT Type FROM dbo.PostTypes WHERE Id = 1)
	BEGIN
	DELETE dbo.PostTypes;
	SET IDENTITY_INSERT dbo.PostTypes ON;
	INSERT INTO dbo.PostTypes (Id, Type) VALUES
		(1, 'Question'),
		(2, 'Answer'),
		(3, 'Wiki'),
		(4, 'TagWikiExerpt'),
		(5, 'TagWiki'),
		(6, 'ModeratorNomination'),
		(7, 'WikiPlaceholder'),
		(8, 'PrivilegeWiki');
	SET IDENTITY_INSERT dbo.PostTypes OFF;
	END
GO

CREATE OR ALTER PROC dbo.usp_SearchUsers
	@CreationDateStart DATETIME = NULL, @CreationDateEnd DATETIME = NULL,
	@LastAccessDateStart DATETIME = NULL, @LastAccessDateEnd DATETIME = NULL,
	@OrderBy NVARCHAR(50) = NULL AS
BEGIN
DECLARE @StringToExecute NVARCHAR(4000) = N'SELECT TOP 1000 Id, DisplayName, Location, WebsiteUrl, 
	PostsOwned = (SELECT COUNT(*) FROM dbo.Posts p WHERE p.OwnerUserId = u.Id) 
	FROM dbo.Users u WHERE 1 = 1 ';

IF @CreationDateStart IS NOT NULL
	SET @StringToExecute = @StringToExecute + N' AND CreationDate > ''' + CAST(@CreationDateStart AS NVARCHAR(100)) + N''' ';

IF @CreationDateEnd IS NOT NULL
	SET @StringToExecute = @StringToExecute + N' AND CreationDate <= ''' + CAST(@CreationDateEnd AS NVARCHAR(100)) + N''' ';

IF @LastAccessDateStart IS NOT NULL
	SET @StringToExecute = @StringToExecute + N' AND LastAccessDate > ''' + CAST(@LastAccessDateStart AS NVARCHAR(100)) + N''' ';

IF @LastAccessDateEnd IS NOT NULL
	SET @StringToExecute = @StringToExecute + N' AND LastAccessDate <= ''' + CAST(@LastAccessDateEnd AS NVARCHAR(100)) + N''' ';

IF @OrderBy IS NOT NULL
	SET @StringToExecute = @StringToExecute + N' ORDER BY ' + @OrderBy;

EXEC sp_executesql @StringToExecute;
END
GO



CREATE OR ALTER PROC dbo.usp_GetTagsForUser @UserId INT AS
BEGIN
	SELECT TOP 10 COALESCE(p.Tags, pQ.Tags) AS Tag,
		SUM(p.Score) AS TotalScore,
		COUNT(*) AS TotalPosts
	  FROM dbo.Users u
	  INNER JOIN dbo.Posts p ON u.Id = p.OwnerUserId /* If this post is a question, it'll have the tags on it */
	  LEFT OUTER JOIN dbo.Posts pQ ON p.ParentId = pQ.Id /* Because the above might be an answer, not a question */
	  WHERE u.Id = @UserId
	  GROUP BY COALESCE(p.Tags, pQ.Tags)
	  ORDER BY SUM(p.Score) DESC;
END
GO

CREATE OR ALTER PROC dbo.usp_RptTopTags 
	@StartDate DATETIME, @EndDate DATETIME, @SortOrder NVARCHAR(20)= 'Quantity' AS
BEGIN
/* Changelog:
	2020/05/28 Mehow - I needed a quick report for the sales team.
*/
SELECT TOP 250 pQ.Tags, COUNT(*) AS TotalPosts,
	SUM(pQ.Score + COALESCE(pA.Score, 0)) AS TotalScore,
	SUM(pQ.ViewCount) AS TotalViewCount
  FROM dbo.Posts pQ
  LEFT OUTER JOIN dbo.Posts pA ON pQ.Id = pA.ParentId /* Answers join up to questions on this */
  WHERE pQ.CreationDate >= @StartDate
    AND pQ.CreationDate < @EndDate
	AND pQ.PostTypeId = 1
  GROUP BY pQ.Tags
  ORDER BY CASE WHEN @SortOrder = 'Quantity' THEN COUNT(*)
				WHEN @SortOrder = 'Score' THEN SUM(pQ.Score + pA.Score)
				WHEN @SortOrder = 'ViewCount' THEN SUM(pQ.ViewCount)
				ELSE COUNT(*)
			END DESC;
END
GO


CREATE OR ALTER PROC dbo.usp_RptPostLeaderboard 
	@StartDate DATETIME, @EndDate DATETIME, @PostTypeName VARCHAR(50)  AS
BEGIN
/* Changelog:
	2020/05/29 Jonathan9375 - make it work for multiple PostTypes
	2020/05/28 AbusedSysadmin - New social media project to display viral questions.
*/
SELECT TOP 250 *
  FROM dbo.PostTypes pt 
  INNER JOIN dbo.Posts p ON pt.Id = p.PostTypeId
  WHERE p.CreationDate >= @StartDate
    AND p.CreationDate < @EndDate
	AND pt.Type = @PostTypeName
  ORDER BY AnswerCount DESC;
END
GO

CREATE OR ALTER PROC dbo.usp_RptQuestionsAnsweredForUser @UserId INT AS
BEGIN
/* Changelog:
	2020/05/29 David Hooey - PM also wants to show a percentage
	2020/05/28 David Hooey - Product manager wants to show each user's number of questions
*/
WITH MyQuestions AS (
	SELECT pQ.Id AS QuestionId, pQ.AnswerCount
	  FROM dbo.Users u
	  INNER JOIN dbo.Posts pQ ON u.Id = pQ.OwnerUserId /* My questions */
	  INNER JOIN dbo.PostTypes pt ON pQ.PostTypeId = pt.Id AND pt.Type = 'Question'
	  WHERE u.Id = @UserId
),
MyAggregates AS (
SELECT COUNT(*) AS MyQuestions,
	SUM(CASE WHEN AnswerCount > 0 THEN 1 ELSE 0 END) AS Answered
	FROM MyQuestions
)
SELECT MyQuestions, Answered, 100.0 * Answered / MyQuestions AS AnsweredPercent
  FROM MyAggregates
END
GO


CREATE OR ALTER PROC dbo.usp_DashboardFromTopUsers @AsOf DATETIME = '2018-06-03' AS
BEGIN
/* Changelog:
	2020/05/28 DamnTank - last 10 posts by the top 10 posters
*/
CREATE TABLE #RecentlyActiveUsers (Id INT, DisplayName NVARCHAR(40), Location NVARCHAR(100));

INSERT INTO #RecentlyActiveUsers
SELECT TOP 10 u.Id, u.DisplayName, u.Location
  FROM dbo.Users u
  WHERE EXISTS (SELECT * 
					FROM dbo.Posts 
					WHERE OwnerUserId = u.Id
					  AND CreationDate >= DATEADD(DAY, -7, @AsOf))
  ORDER BY u.Reputation DESC;

SELECT TOP 100 u.DisplayName, u.Location, pAnswer.Body, pAnswer.Score, pAnswer.CreationDate
	FROM #RecentlyActiveUsers u
	INNER JOIN dbo.Posts pAnswer ON u.Id = pAnswer.OwnerUserId
	WHERE pAnswer.CreationDate >= DATEADD(DAY, -7, @AsOf) 
	ORDER BY pAnswer.CreationDate DESC;

END
GO


CREATE OR ALTER PROC dbo.usp_ViewPost 
	@UserId INT, @PostId INT AS
BEGIN
	UPDATE dbo.Users
		SET LastAccessDate = GETDATE(),
		[Views] = [Views] + 1
		WHERE Id = @UserId;

	UPDATE dbo.Posts
		SET LastActivityDate = GETDATE(),
		ViewCount = ViewCount + 1
END
GO

DROP TABLE IF EXISTS dbo.TaskLog;
CREATE TABLE dbo.TaskLog(TaskName VARCHAR(50), LastCompleted DATETIME);
INSERT INTO dbo.TaskLog(TaskName, LastCompleted)
	VALUES ('Users - Update Statistics', '1900-01-01'),
		('Posts - Update Statistics', '1900-01-01');
GO

CREATE OR ALTER PROC dbo.dba_Maintenance AS
BEGIN
	/* We've had some problems with bad query plans,
	so proactively update statistics if they get out of date. */
	IF NOT EXISTS (SELECT * 
					FROM dbo.TaskLog
					WHERE TaskName = N'Posts - Update Statistics'
					AND LastCompleted >= DATEADD(MI, -20, GETDATE()))
		BEGIN
		UPDATE dbo.TaskLog
			SET LastCompleted = GETDATE()
			WHERE TaskName = N'Posts - Update Statistics'
		UPDATE STATISTICS dbo.Posts;
		END

	ELSE IF NOT EXISTS (SELECT * 
					FROM dbo.TaskLog
					WHERE TaskName = N'Users - Update Statistics'
					AND LastCompleted >= DATEADD(MI, -20, GETDATE()))
		BEGIN
		UPDATE dbo.TaskLog
			SET LastCompleted = GETDATE()
			WHERE TaskName = N'Users - Update Statistics'
		UPDATE STATISTICS dbo.Users;
		END

END
GO


CREATE OR ALTER VIEW dbo.AverageAnswerResponseTime AS
SELECT pQ.Id, pQ.Tags, pQ.CreationDate AS QuestionDate, 
	DATEDIFF(SECOND, pQ.CreationDate, pA.CreationDate) AS ResponseTimeSeconds
FROM dbo.Posts pQ
INNER JOIN dbo.Posts pA ON pQ.AcceptedAnswerId = pA.Id
WHERE pQ.PostTypeId = 1;
GO



CREATE OR ALTER PROC dbo.usp_RptAvgAnswerTimeByTag
	@StartDate DATETIME, @EndDate DATETIME, @Tag NVARCHAR(50) AS
BEGIN
/* Changelog:
	2020/05/29 James Randell - fixing bugs left over from Bilbo
	2020/05/28 Bilbo Baggins - find out when fast answers are coming in
*/

SELECT TOP 100 YEAR(QuestionDate) AS QuestionYear,
	MONTH(QuestionDate) AS QuestionMonth,
	AVG(ResponseTimeSeconds * 1.0) AS AverageResponseTimeSeconds
	FROM dbo.AverageAnswerResponseTime r
	WHERE r.QuestionDate >= @StartDate
	  AND r.QuestionDate < @EndDate
	  AND r.Tags = @Tag
	GROUP BY YEAR(QuestionDate), MONTH(QuestionDate)
	ORDER BY YEAR(QuestionDate), MONTH(QuestionDate);

END
GO

CREATE OR ALTER PROC dbo.usp_RptFastestAnswers
	@StartDate DATETIME, @EndDate DATETIME, @Tag NVARCHAR(50) AS
BEGIN
/* Changelog:
	2020/05/28 Gabriele D'Onufrio - looking for the fastest answer fingers in the West, possibly fraud
*/
SELECT TOP 10 r.ResponseTimeSeconds, pQuestion.Title, pQuestion.CreationDate, pQuestion.Body,
	uQuestion.DisplayName AS Questioner_DisplayName, uQuestion.Reputation AS Questioner_Reputation,
	pAnswer.Body AS Answer_Body, pAnswer.Score AS Answer_Score,
	uAnswer.DisplayName AS Answerer_DisplayName, uAnswer.Reputation AS Answerer_Reputation
	FROM dbo.AverageAnswerResponseTime r
	INNER JOIN dbo.Posts pQuestion ON r.Id = pQuestion.Id
	INNER JOIN dbo.Users uQuestion ON pQuestion.OwnerUserId = uQuestion.Id
	INNER JOIN dbo.Posts pAnswer ON pQuestion.AcceptedAnswerId = pAnswer.Id
	INNER JOIN dbo.Users uAnswer ON pAnswer.OwnerUserId = uAnswer.Id
	WHERE r.QuestionDate >= @StartDate
	  AND r.QuestionDate < @EndDate
	  AND r.Tags = @Tag
	ORDER BY r.ResponseTimeSeconds ASC;
END
GO


CREATE OR ALTER PROC dbo.usp_LogUserActivity @UserId INT AS
BEGIN
	/* Log activity for the viewing user */
	UPDATE dbo.Users
		SET LastAccessDate = GETDATE()
		WHERE Id = @UserId;
END
GO


CREATE OR ALTER PROC dbo.usp_ViewPost @PostId INT, @UserId INT AS
BEGIN
	/* Log activity for the viewing user */
	EXEC dbo.usp_LogUserActivity @UserId = @UserId;

	/* Log activity on the post */
	UPDATE dbo.Posts
		SET ViewCount = ViewCount + 1
		WHERE Id = @PostId;

	/* Show the contents of the post */
	SELECT COALESCE(pParent.Title, p.Title) AS QuestionTitle,
		COALESCE(pParent.Body, p.Body, pChild.Body) AS QuestionBody,
		COALESCE(pParent.Tags, p.Tags) AS QuestionTags,
		COALESCE(p.Score, pChild.Score) AS AnswerScore,
		COALESCE(pChild.Body, p.Body) AS AnswerBody
		FROM dbo.Posts p
		LEFT OUTER JOIN dbo.Posts pParent ON p.ParentId = pParent.Id
		LEFT OUTER JOIN dbo.Posts pChild ON p.Id = pChild.ParentId
		WHERE p.Id = @PostId
		ORDER BY COALESCE(p.Score, pChild.Score) DESC;
END
GO


CREATE OR ALTER PROC dbo.usp_SearchPostsByPostType 
	@PostType NVARCHAR(50),
	@StartDate DATETIME, 
	@EndDate DATETIME,
	@ResultsToShow INT = 100 AS
BEGIN
	SELECT TOP (@ResultsToShow) p.CreationDate, p.Score, COALESCE(p.Title, pParent.Title) AS Title, u.DisplayName AS OwnerDisplayName
	FROM dbo.PostTypes pt
	INNER JOIN dbo.Posts p ON pt.Id = p.PostTypeId
	LEFT OUTER JOIN dbo.Posts pParent ON p.ParentId = pParent.Id
	INNER JOIN dbo.Users u ON p.OwnerUserId = u.Id
	WHERE pt.Type = @PostType
	  AND p.CreationDate >= @StartDate
	  AND p.CreationDate <= @EndDate
	ORDER BY p.CreationDate;
END
GO


CREATE OR ALTER PROC dbo.usp_ShowBadgesForUser
	@UserId INT WITH RECOMPILE AS
BEGIN
/* Changelog:
	2020/05/29 Norm the New Guy - got lots of complaints about performance, added recompile & nolock, we're good
	2020/05/28 Norm the New Guy - v1, really proud of this, super easy query
*/
	SELECT b.Date, b.Name, b.Id AS BadgeId
	FROM dbo.Badges b WITH (NOLOCK)
	WHERE b.UserId = @UserId
	ORDER BY b.Date, b.Name;
END
GO


CREATE OR ALTER PROC dbo.usp_CastVote @PostId INT, @VoteTypeName NVARCHAR(50), @UserId INT AS
BEGIN
	/* Log activity for the viewing user */
	EXEC dbo.usp_LogUserActivity @UserId = @UserId;

	INSERT INTO dbo.Votes(PostId, UserId, VoteTypeId, CreationDate)
	SELECT @PostId, @UserId, vt.Id, GETDATE()
	FROM dbo.VoteTypes vt
	WHERE vt.Name = @VoteTypeName;

END
GO

CREATE OR ALTER PROC dbo.usp_InsertComment @PostId INT, @UserId INT, @Text NVARCHAR(700) AS
BEGIN
	/* Log activity for the commenting user */
	EXEC dbo.usp_LogUserActivity @UserId = @UserId;

	INSERT INTO dbo.Comments(PostId, UserId, Score, CreationDate, Text)
	VALUES (@PostId, @UserId, 0, GETDATE(), @Text);

	UPDATE dbo.Posts
		SET CommentCount = CommentCount + 1
		WHERE Id = @PostId;

END
GO

CREATE OR ALTER PROC dbo.usp_RptUsersLeaderboard @Location NVARCHAR(100) AS
BEGIN
	SELECT TOP 100 *
		FROM dbo.Users u
		WHERE u.Location = @Location
		ORDER BY Reputation DESC;
END
GO

CREATE OR ALTER PROC dbo.usp_InsertUser @DisplayName NVARCHAR(40), @Location NVARCHAR(100), @WebsiteUrl NVARCHAR(200) AS
BEGIN
	INSERT INTO dbo.Users(CreationDate, DisplayName, DownVotes, LastAccessDate, Location, Reputation, UpVotes, Views, WebsiteUrl)
	VALUES (GETDATE(), @DisplayName, 0, GETDATE(), @Location, 1, 0, 0, @WebsiteUrl);
END
GO

CREATE OR ALTER PROC dbo.usp_GrantBadge @BadgeName NVARCHAR(40), @UserId INT AS
BEGIN
	/* Check to make sure the badge actually exists */
	IF EXISTS (SELECT * FROM dbo.Badges WHERE Name = @BadgeName)
		AND EXISTS (SELECT * FROM dbo.Users WHERE Id = @UserId)
	BEGIN
		INSERT INTO dbo.Badges (Name, UserId, Date)
			VALUES (@BadgeName, @UserId, GETDATE());

		/* Track that the user was active */
		EXEC dbo.usp_LogUserActivity @UserId = @UserId;
	END
END
GO



CREATE OR ALTER PROC [dbo].[usp_SniffLab] WITH RECOMPILE AS
BEGIN
/* Hi! You can ignore this stored procedure.
   This is used to run different random stored procs as part of your class.
   Don't change this in order to "tune" things.
*/
SET NOCOUNT ON
 
DECLARE @Id1 INT = CAST(RAND() * 10000000 AS INT) + 1,
		@Id2 INT = CAST(RAND() * 10000000 AS INT) + 1,
		@P1 NVARCHAR(50),
		@P2 NVARCHAR(50),
		@P3 NVARCHAR(50),
		@P4 NVARCHAR(50),
		@StartDate DATETIME = ('2017-' + CAST(1 + DATEPART(SS, GETDATE()) / 5 AS VARCHAR(4)) + '-' + CAST(1 + DATEPART(SS, GETDATE()) / 2 AS VARCHAR(4)));
DECLARE @EndDateShort DATETIME = DATEADD(DD, 1, @StartDate),
		@EndDateMedium DATETIME = DATEADD(MONTH, 1, @StartDate),
		@EndDateLong DATETIME = DATEADD(MONTH, 6, @StartDate);


IF @Id1 % 19 = 18
	BEGIN
		IF @Id2 % 6 = 5
			EXEC usp_SearchUsers @CreationDateStart = @StartDate, @CreationDateEnd = @EndDateLong, @LastAccessDateStart = @StartDate, @LastAccessDateEnd = @EndDateLong, @OrderBy = N' Reputation DESC ';
		ELSE IF @Id2 % 6 = 4
			EXEC usp_SearchUsers @CreationDateStart = @StartDate, @CreationDateEnd = @EndDateLong, @LastAccessDateStart = @StartDate, @OrderBy = N' Reputation DESC ';
		ELSE IF @Id2 % 6 = 3
			EXEC usp_SearchUsers @CreationDateStart = @StartDate, @LastAccessDateStart = @StartDate, @LastAccessDateEnd = @EndDateLong, @OrderBy = N' Reputation DESC ';
		ELSE IF @Id2 % 6 = 2
			EXEC usp_SearchUsers @CreationDateStart = @StartDate, @CreationDateEnd = @EndDateLong, @OrderBy = N' Reputation DESC ';
		ELSE IF @Id2 % 6 = 1
			EXEC usp_SearchUsers @LastAccessDateStart = @StartDate, @LastAccessDateEnd = @EndDateLong, @OrderBy = N' Reputation DESC ';
		ELSE
			EXEC usp_SearchUsers @CreationDateStart = @StartDate, @LastAccessDateStart = @StartDate, @OrderBy = N' Reputation DESC ';
	END;
ELSE IF @Id1 % 19 = 17
	EXEC dbo.usp_ViewPost @Id1, @Id2;
ELSE IF @Id1 % 19 = 16
	EXEC dbo.dba_Maintenance;
ELSE IF @Id1 % 19 = 15
	EXEC dbo.usp_InsertComment @PostId = @Id1, @UserId = @Id2, @Text = 'Your ideas intrigue me and I would like to subscribe to your newsletter.';
ELSE IF @Id1 % 19 = 14
	EXEC dbo.usp_GrantBadge @BadgeName = N'Supporter', @UserId = @Id1;
ELSE IF @Id1 % 19 = 13
	EXEC dbo.usp_InsertUser @DisplayName = N'John Malkovich', @Location = N'New Jersey Turnpike', @WebsiteUrl = N'https://www.youtube.com/watch?v=2UuRFr0GnHM';
ELSE IF @Id1 % 19 = 12
	BEGIN
		IF @Id2 % 2 = 1
			EXEC dbo.usp_RptUsersLeaderboard @Location = N'San Diego, CA, USA';
		ELSE
			EXEC dbo.usp_RptUsersLeaderboard @Location = N'India';
	END;
ELSE IF @Id1 % 19 = 11
	EXEC dbo.usp_CastVote @PostId = @Id1, @VoteTypeName = 'UpMod', @UserId = @Id2;
ELSE IF @Id1 % 19 = 10
	EXEC dbo.usp_ShowBadgesForUser @UserId = @Id1;
ELSE IF @Id1 % 19 = 9
	EXEC dbo.usp_ViewPost @PostId = @Id1, @UserId = @Id2;
ELSE IF @Id1 % 19 = 8
	BEGIN
		IF @Id2 % 6 = 5
			EXEC usp_SearchPostsByLocation 'Near Stonehenge', @StartDate = '2009-01-01 10:00', @EndDate = '2009-01-01 10:01'; /* Small data, small dates */
		ELSE IF @Id2 % 6 = 4
			EXEC usp_SearchPostsByLocation 'Netherlands', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Medium data, medium dates */
		ELSE IF @Id2 % 6 = 3
			EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Outlier data, medium dates */
		ELSE IF @Id2 % 6 = 2
			EXEC usp_SearchPostsByLocation 'Willemstad, Curaçao', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Outlier data, big dates */
		ELSE IF @Id2 % 6 = 1
			EXEC usp_SearchPostsByLocation 'India', @StartDate = '2008-01-01', @EndDate = '2014-01-01'; /* Big data, big dates */
		ELSE
			EXEC usp_SearchPostsByLocation 'India', @StartDate = '2009-01-01', @EndDate = '2009-02-01'; /* Big data, medium dates */
	END;
ELSE IF @Id1 % 19 = 7
	BEGIN
		IF @Id2 % 2 = 1
			EXEC usp_GetTagsForUser @UserId = 22656;
		ELSE
			EXEC usp_GetTagsForUser @UserId = @Id1;
	END;
ELSE IF @Id1 % 19 = 6
	EXEC usp_RptTopTags @StartDate = @StartDate, @EndDate = @EndDateShort;
ELSE IF @Id1 % 19 = 5
	BEGIN
		IF @Id2 % 2 = 1
			EXEC usp_RptPostLeaderboard @StartDate = @StartDate, @EndDate = @EndDateShort, @PostTypeName = 'Question';
		ELSE
			EXEC usp_RptPostLeaderboard @StartDate = @StartDate, @EndDate = @EndDateShort, @PostTypeName = 'Answer';
	END;
ELSE IF @Id1 % 19 = 4
	BEGIN
		IF @Id2 % 3 = 2
			EXEC usp_RptQuestionsAnsweredForUser @UserId = 22656;
		ELSE IF @Id2 % 3 = 1
			EXEC usp_RptQuestionsAnsweredForUser @UserId = 1144035;
		ELSE
			EXEC usp_RptQuestionsAnsweredForUser @UserId = @Id1;
	END;
ELSE IF @Id1 % 19 = 3
	EXEC usp_DashboardFromTopUsers @AsOf = @StartDate;
ELSE IF @Id1 % 19 = 2
	EXEC usp_RptAvgAnswerTimeByTag @StartDate = @StartDate, @EndDate = @EndDateShort, @Tag = '<sql-server>';
ELSE IF @Id1 % 19 = 1
	BEGIN
		IF @Id2 % 3 = 2
			EXEC usp_RptFastestAnswers @StartDate = @StartDate, @EndDate = @EndDateLong, @Tag = '<sql-server>';
		ELSE IF @Id2 % 3 = 1
			EXEC usp_RptFastestAnswers @StartDate = @StartDate, @EndDate = @EndDateMedium, @Tag = '<sql-server>';
		ELSE
			EXEC usp_RptFastestAnswers @StartDate = @StartDate, @EndDate = @EndDateShort, @Tag = '<sql-server>';
	END;
ELSE
	BEGIN
		IF @Id2 % 3 = 2			SELECT @P1 = N'Question'
		ELSE IF @Id2 % 3 = 1	SELECT @P1 = N'Answer'
		ELSE					SELECT @P1 = N'ModeratorNomination'

		IF @Id2 % 4 = 3			SELECT @P2 = N'2011-11-01', @P3 = N'2011-11-02'; 
		ELSE IF @Id2 % 4 = 2	SELECT @P2 = N'2011-11-01', @P3 = N'2011-11-30'; 
		ELSE					SELECT @P2 = N'2008-01-01', @P3 = N'2013-12-31'; 
	
		IF @Id2 % 2 = 1			SELECT @P4 = N'100'; 
		ELSE					SELECT @P4 = N'10000'; 

		EXEC dbo.usp_SearchPostsByPostType @P1, @P2, @P3, @P4;
	END;

 
WHILE @@TRANCOUNT > 0
	BEGIN
	COMMIT
	END
END
GO

CREATE OR ALTER PROC dbo.usp_SniffLab_Setup AS
BEGIN
	/* Enable RCSI to avoid having blocking as an issue during the lab: */
	ALTER DATABASE [StackOverflow] SET READ_COMMITTED_SNAPSHOT ON WITH NO_WAIT

	/* Only because you'll be focusing on the plan cache in this lab: */
	DBCC FREEPROCCACHE;
END
GO

EXEC dbo.usp_SniffLab_Setup;


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