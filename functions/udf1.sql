USE FACTORY;
GO

CREATE OR ALTER FUNCTION dbo.udf1
(
@MID VARCHAR(10) = 'm1',
@EID VARCHAR(10) = 'e01'
)
Returns VARCHAR(3)
AS
BEGIN
DECLARE @result VARCHAR(3);

IF EXISTS
(
SELECT 1
FROM OperatingSchedules
WHERE MID = @MID
AND EID = @EID
AND Day IN ('S', 'M', 'T')
)
SET @result = 'NO';
ELSE
SET @result = 'YES';

RETURN @result;
END;
GO

-- Test cases
-- Test YES
SELECT dbo.udf1('m4', 'e02') AS Result_YES;

-- Test NO 
SELECT dbo.udf1('m1', 'e01') AS Result_NO;

-- Test with one default
SELECT dbo.udf1('m1', DEFAULT) AS Result_OneDefault;

-- Test with both defaults
SELECT dbo.udf1(DEFAULT, DEFAULT) AS Result_BothDefaults;

