
USE DWH
GO

-- ------------------------------------------------------------------------------------------------------
-- CURSOR FOR IS NULL
-- ------------------------------------------------------------------------------------------------------

-- DECLARE VAR TABLE
DECLARE @Cursor1 TABLE
(
	PK_ID					BIGINT NOT NULL IDENTITY (1, 1),
	user_retailer_coupon_id BIGINT,
	retailer_id			    BIGINT
)

-- CREATE TWO VAR TO LOOP
DECLARE	@Rows BIGINT,
		@i    BIGINT
		
SET @Rows = 0
SET @i = 1

-- INSERT INTO @Cursor1
INSERT INTO @Cursor1 (user_retailer_coupon_id, retailer_id)
	SELECT  
		  urc.user_retailer_coupon_id
		, ur.retailer_id 
	FROM prd.t_user_retailer_coupon urc, prd.t_user_retailer ur
	WHERE 
		urc.USER_RETAILER_ID = ur.USER_RETAILER_ID
	and urc.modified  >= '27-OCT-22' and urc.modified  < '28-OCT-22'
	and urc.PARENT_USER_RETAILER_COUPON_ID is null
	and (urc.CLIPPED_RETAILER_ID = -1 or urc.CLIPPED_RETAILER_ID is null)

-- SET @ROW
SET @Rows = (SELECT TOP 1 PK_ID FROM @Cursor1 ORDER BY PK_ID DESC)

-- EMULATE cursor
SELECT GETDATE(), 'Start WHILE'

WHILE @i <= @Rows
BEGIN
	DECLARE
		@user_retailer_coupon_id BIGINT,
		@retailer_id			 BIGINT

	SELECT
		@user_retailer_coupon_id = user_retailer_coupon_id,
		@retailer_id			 = retailer_id
	FROM @Cursor1
	WHERE PK_ID = @i

	-- Realizar todas las acciones!
	-- For QA
	SELECT @i

	UPDATE PRD.t_user_retailer_coupon 
	SET    CLIPPED_RETAILER_ID		= @retailer_id
	WHERE  USER_RETAILER_COUPON_ID  = @user_retailer_coupon_id;

	SET @i = @i + 1
END

SELECT GETDATE(), 'END WHILE'


-- ------------------------------------------------------------------------------------------------------
-- CURSOR FOR IS NOT NULL
-- ------------------------------------------------------------------------------------------------------

-- DECLARE VAR TABLE
DECLARE @Cursor2 TABLE
(
	PK_ID					BIGINT NOT NULL IDENTITY (1, 1),
	user_retailer_coupon_id BIGINT,
	retailer_id			    BIGINT
)

-- CREATE TWO VAR TO LOOP
DECLARE	@Rows2 BIGINT,
		@i2    BIGINT
		
SET @Rows2 = 0
SET @i2 = 1

-- INSERT INTO @Cursor1
INSERT INTO @Cursor2 (user_retailer_coupon_id, retailer_id)
	SELECT  
		  urc.user_retailer_coupon_id
		, urc.PARENT_USER_RETAILER_COUPON_ID 
	FROM prd.t_user_retailer_coupon urc, prd.t_user_retailer ur
	WHERE 
		urc.USER_RETAILER_ID = ur.USER_RETAILER_ID
	and (urc.CLIPPED_RETAILER_ID = -1 or urc.CLIPPED_RETAILER_ID is null)
	and urc.modified  >= '26-OCT-22' and urc.modified  < '27-OCT-22'
	and urc.PARENT_USER_RETAILER_COUPON_ID is not null;

-- SET @ROW
SET @Rows2 = (SELECT TOP 1 PK_ID FROM @Cursor2 ORDER BY PK_ID DESC)

-- EMULATE cursor
SELECT GETDATE(), 'Start WHILE'

WHILE @i2 <= @Rows2
BEGIN
	DECLARE
		@user_retailer_coupon_id2 BIGINT,
		@retailer_id2			 BIGINT

	SELECT
		@user_retailer_coupon_id2 = user_retailer_coupon_id,
		@retailer_id2			  = retailer_id
	FROM @Cursor2
	WHERE PK_ID = @i2

	-- Realizar todas las acciones!
	-- For QA
	SELECT @i2

	UPDATE PRD.t_user_retailer_coupon 
	SET    CLIPPED_RETAILER_ID		= @retailer_id2
	WHERE  USER_RETAILER_COUPON_ID  = @user_retailer_coupon_id2;

	SET @i2 = @i2 + 1
END

SELECT GETDATE(), 'END WHILE'

