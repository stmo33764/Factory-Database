USE Factory;
GO

-- Create login g2 if it doesn't already exist
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'g2')
BEGIN
    CREATE LOGIN g2 WITH PASSWORD = 'g2';
END
GO

-- Create user u2 if it doesn't already exist
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'u2')
BEGIN
    CREATE USER u2 FOR LOGIN g2;
END
GO

-- Grant read access to all tables except Engineers and PayRate
GRANT SELECT ON SCHEMA::dbo TO u2;
DENY SELECT ON dbo.Engineers TO u2;
DENY SELECT ON dbo.PayRate TO u2;

-- Grant access to udf2
GRANT SELECT ON dbo.udf2 TO u2;

-- Permanently deny all data manipulation regardless of future roles
DENY INSERT, UPDATE, DELETE ON SCHEMA::dbo TO u2;
GO

-- Test u2 permissions
EXECUTE AS USER = 'u2';

-- Read Engineers (fail)
BEGIN TRY
    SELECT * FROM dbo.Engineers;
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;

-- Read PayRate (fail)
BEGIN TRY
    SELECT * FROM dbo.PayRate;
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;

-- Read Machines (success)
BEGIN TRY
    SELECT * FROM dbo.Machines;
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;

-- Access udf2 (succeed)
BEGIN TRY
    SELECT * FROM dbo.udf2();
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;

-- Try to insert data (fail)
BEGIN TRY
    INSERT INTO dbo.Machines VALUES ('m_test', 2024, 10000);
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;

REVERT;
GO