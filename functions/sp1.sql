USE Factory;
GO


CREATE OR ALTER PROC dbo.sp1
    @MID NVARCHAR(50) = 'm1',
    @EID NVARCHAR(50) = 'e01'
AS
BEGIN

    IF EXISTS
    (
        SELECT 1
        FROM OperatingSchedules
        WHERE MID = @MID
          AND EID = @EID
          AND Day IN ('S', 'M', 'T')
    )
        SELECT 'NO' AS Result;
    ELSE
        SELECT 'YES' AS Result;
END;
GO

-- Testing

-- return YES
EXEC dbo.sp1 'm4', 'e02';

-- return NO
EXEC dbo.sp1 'm1', 'e01';

-- One default
EXEC dbo.sp1 'm1';

-- Both defaults
EXEC dbo.sp1;