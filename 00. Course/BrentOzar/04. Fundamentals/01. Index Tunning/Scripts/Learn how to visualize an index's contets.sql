USE StackOverflow2013
GO

-- Learn how to visualize an index's contets
BEGIN TRAN TR1

	-- COUNT = 2.465.713
	-- SELECT COUNT(*) FROM dbo.Users

	SELECT top 100 * FROM dbo.Users

	CREATE INDEX IX_LastAccessDate_ID
	ON dbo.Users(LastAccessDate, ID)

    SELECT
        LastAccessDate,
        ID
    FROM dbo.Users
    ORDER BY LastAccessDate, ID
	
	CREATE INDEX IX_LastAccessDate_ID_DisplayName_Age
	ON dbo.Users(LastAccessDate, ID)
	INCLUDE (DisplayName, Age)

	SELECT
		LastAccessDate
		, ID
		, DisplayName
		, Age
	FROM dbo.Users
	ORDER BY LastAccessDate, Id

END TRAN TR1


-- WHERE --> With 1 equility search
BEGIN TRAN TR2

END TRAN TR2


-- LAB: Design Indexes for WHERE
BEGIN TRAN LAB

END TRAN LAB
















