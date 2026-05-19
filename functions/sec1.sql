USE Factory;
GO

-- Create g1 if it doesn't already exist
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'g1')
BEGIN
    CREATE LOGIN g1 WITH PASSWORD = 'g1';
END
GO

-- Create u1 for login g1 if it doesn't already exist
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'u1')
BEGIN
    CREATE USER u1 FOR LOGIN g1;
END
GO

-- Add u1 as co-owner using db_owner fixed database role
IF NOT EXISTS (
    SELECT 1 FROM sys.database_role_members drm
    JOIN sys.database_principals dp ON drm.member_principal_id = dp.principal_id
    JOIN sys.database_principals dr ON drm.role_principal_id = dr.principal_id
    WHERE dp.name = 'u1' AND dr.name = 'db_owner'
)
BEGIN
    ALTER ROLE db_owner ADD MEMBER u1;
END
GO

-- Test co-owner permissions
EXECUTE AS USER = 'u1';

BEGIN TRAN;

-- Create a table
CREATE TABLE TestUser_sec1 (
    id INT PRIMARY KEY,
    Tname VARCHAR(50)
);

-- Insert data
INSERT INTO TestUser_sec1
VALUES (1, 'test1'), (2, 'test2');

-- Update data
UPDATE TestUser_sec1 
SET Tname = 'updated' 
WHERE id = 1;

-- Delete a row
DELETE FROM TestUser_sec1 
WHERE id = 2;

-- Show u1 has db_owner role
SELECT dp.name AS UserName, dr.name AS RoleName
FROM sys.database_role_members drm
JOIN sys.database_principals dp ON drm.member_principal_id = dp.principal_id
JOIN sys.database_principals dr ON drm.role_principal_id = dr.principal_id
WHERE dp.name = 'u1';

-- Show test table mid-transaction
SELECT * FROM TestUser_sec1;

-- Drop the table
DROP TABLE TestUser_sec1;

-- Create and drop a user
CREATE USER tempTest WITHOUT LOGIN;
DROP USER tempTest;

ROLLBACK;
REVERT;
GO