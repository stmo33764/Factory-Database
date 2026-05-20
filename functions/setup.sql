-- SETUP SCRIPT  –  Factory Security Demo
-- Run this once against the Factory database
USE Factory;
GO

-- Create Users table (for login demo)
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL
    DROP TABLE dbo.Users;
GO

CREATE TABLE dbo.Users (
    username  NVARCHAR(50)  NOT NULL PRIMARY KEY,
    password  NVARCHAR(50)  NOT NULL,
    role      NVARCHAR(20)  NOT NULL DEFAULT 'engineer'
);
GO

-- Seed with sample login credentials
INSERT INTO dbo.Users (username, password, role) VALUES
    ('admin',   'admin123',  'admin'),
    ('user',  'pass1',     'engineer'),
    ('positive',   'pass2',     'engineer');
GO

--  Create stored procedure sp3
--    Returns mentor info for the engineer assigned
--    to the machine with the highest avg component cost
IF OBJECT_ID('dbo.sp3', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp3;
GO

CREATE PROCEDURE dbo.sp3
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MentorEID      NVARCHAR(50),
            @MentorName     NVARCHAR(50),
            @MentorHireDate NVARCHAR(50);

    WITH MachineStats AS (
        SELECT
            K.MID,
            AVG(CAST(C.Price AS FLOAT)) AS AvgComponentCost
        FROM  KeyComponents K
        JOIN  Components    C ON K.CID = C.CID AND K.Color = C.Color
        GROUP BY K.MID
    ),
    -- Machine with highest average component cost
    TargetMachine AS (
        SELECT TOP 1 MID
        FROM  MachineStats
        ORDER BY AvgComponentCost DESC
    ),
    -- Engineer scheduled on that machine
    TargetEngineer AS (
        SELECT TOP 1 EID
        FROM  OperatingSchedules
        WHERE MID = (SELECT MID FROM TargetMachine)
    )
    -- Retrieve that engineer's mentor details (or 'n/a')
    SELECT
        @MentorEID      = ISNULL(m.EID,                         'n/a'),
        @MentorName     = ISNULL(m.Ename,                       'n/a'),
        @MentorHireDate = ISNULL(CAST(m.DateHired AS NVARCHAR), 'n/a')
    FROM  Engineers e
    LEFT JOIN Engineers m ON e.MentorID = m.EID
    WHERE e.EID = (SELECT EID FROM TargetEngineer);

    -- Handle case where no engineer/mentor was found
    IF @MentorEID IS NULL
        SELECT @MentorEID = 'n/a',
               @MentorName = 'n/a',
               @MentorHireDate = 'n/a';

    SELECT
        @MentorEID      AS MentorEID,
        @MentorName     AS MentorName,
        @MentorHireDate AS MentorHireDate;
END;
GO
