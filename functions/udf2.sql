USE FACTORY;
GO

-- Note: WeeklyIncome calculated as HourlyRate * 8 hours per shift per scheduled day
-- No shift duration was specified in schema; 8 hours assumed as standard workday
CREATE OR ALTER FUNCTION dbo.udf2()
RETURNS TABLE
AS
RETURN
(
    SELECT
        e.EID,
        e.EName,
        ISNULL(SUM(p.HourlyRate * 8), 0) AS WeeklyIncome
    FROM Engineers e
    LEFT JOIN OperatingSchedules s ON e.EID = s.EID
    LEFT JOIN PayRate p ON s.Day = p.Day
    GROUP BY e.EID, e.EName
);
GO

-- test
SELECT * FROM dbo.udf2() ORDER BY WeeklyIncome DESC;