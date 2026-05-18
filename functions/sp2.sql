USE Factory;
GO

CREATE OR ALTER PROC dbo.sp2
    @MID NVARCHAR(50),
    @NewCost MONEY
AS
BEGIN
    -- create log table if it doesn't exist
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'MachineCostLog')
    BEGIN
        CREATE TABLE MachineCostLog
        (
            LogNo INT IDENTITY(1000,1),
            MID NVARCHAR(50),
            CostBeforeChange MONEY,
            CostAfterChange MONEY,
            CostDifferenceChanged AS (CostBeforeChange - CostAfterChange),
            WhenChanged DATETIME,
            ChangeByWhichLogin NVARCHAR(20),
            ChangeByWhichUser NVARCHAR(20)
        );
    END

    -- get current cost
    DECLARE @OldCost MONEY;
    SELECT @OldCost = Cost
    FROM Machines
    WHERE MID = @MID;

    -- check 10% rule BEFORE making any changes
    IF ABS(@NewCost - @OldCost) > (@OldCost * 0.10)
    BEGIN
        -- log attempted update
        INSERT INTO MachineCostLog
        (
            MID,
            CostBeforeChange,
            CostAfterChange,
            WhenChanged,
            ChangeByWhichLogin,
            ChangeByWhichUser
        )
        VALUES
        (
            @MID,
            @OldCost,
            @NewCost,
            GETDATE(),
            SUSER_NAME(),
            USER_NAME()
        );

        -- return -1 to show rejection
        RETURN -1;
    END

    -- begin transaction for valid updates
    BEGIN TRANSACTION;

    -- update cost
    UPDATE Machines
    SET Cost = @NewCost
    WHERE MID = @MID;

    -- log update
    INSERT INTO MachineCostLog
    (
        MID,
        CostBeforeChange,
        CostAfterChange,
        WhenChanged,
        ChangeByWhichLogin,
        ChangeByWhichUser
    )
    VALUES
    (
        @MID,
        @OldCost,
        @NewCost,
        GETDATE(),
        SUSER_NAME(),
        USER_NAME()
    );

    COMMIT TRANSACTION;
    -- return 1 to show success
    RETURN 1;
END;
GO

-- check starting cost
SELECT MID, Cost FROM Machines WHERE MID = 'M1';

-- within 10%
DECLARE @Result INT;
EXEC @Result = dbo.sp2 'M1', 400700;
SELECT @Result AS ReturnValue;

-- outside 10%
EXEC @Result = dbo.sp2 'M1', 500000;
SELECT @Result AS ReturnValue;

-- check updated
SELECT MID, Cost FROM Machines WHERE MID = 'M1';
SELECT * FROM MachineCostLog;