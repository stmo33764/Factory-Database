DROP TRIGGER IF EXISTS trg1;
GO

USE Factory;
GO

CREATE TRIGGER trg1
ON Components
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Color must be allowed
    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE i.color NOT IN ('pink', 'white', 'yellow')
        AND i.color NOT IN (
            SELECT DISTINCT color 
            FROM Components 
            WHERE CID NOT IN (SELECT CID FROM inserted)
        )
    )
    BEGIN
        RAISERROR('ERROR: Invalid color. New colors must be pink, white, or yellow.', 16, 1);
        ROLLBACK;
        RETURN;
    END

    -- No duplicate CID and color combination
    IF EXISTS (
        SELECT cid, color
        FROM Components
        GROUP BY cid, color
        HAVING COUNT(*) > 1
    )
    BEGIN
        RAISERROR('ERROR: Duplicate CID and Color combination not allowed.', 16, 1);
        ROLLBACK;
        RETURN;
    END

END;
GO

-- Test 1: Valid insert with allowed new color
INSERT INTO Components (cid, color, amountinstock, price)
VALUES ('A300', 'pink', 10, 10.00);

-- Valid insert with existing color (black already exists)
INSERT INTO Components (cid, color, amountinstock, price)
VALUES ('A301', 'black', 5, 5.00);

-- invalid new color not in allowed list or existing colors
BEGIN TRY
    INSERT INTO Components (cid, color, amountinstock, price)
    VALUES ('A302', 'purple', 5, 5.00);
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;
