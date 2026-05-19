USE Factory;
GO

-- trg21
-- prevent adding or modifying a machine in Machines unless it has at least one component in KeyComponents
CREATE OR ALTER TRIGGER trg21
ON Machines
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE NOT EXISTS (
            SELECT 1
            FROM KeyComponents kc
            WHERE kc.MID = i.MID
        )
    )
    BEGIN
        RAISERROR('ERROR: A machine must have at least one component in KeyComponents.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- trg22
-- prevent deleting or modifying a row in KeyComponents
CREATE OR ALTER TRIGGER trg22
ON KeyComponents
AFTER DELETE, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM deleted d
        WHERE NOT EXISTS (
            SELECT 1
            FROM KeyComponents kc
            WHERE kc.MID = d.MID
        )
    )
    BEGIN
        RAISERROR('ERROR: Cannot remove the only component associated with a machine.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- try to insert a machine with no components
BEGIN TRY
    INSERT INTO Machines VALUES ('m_new', 2024, 15000);
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;
GO

-- try to delete the only component for m4
BEGIN TRY
    DELETE FROM KeyComponents
    WHERE MID = 'm4' AND CID = 'C3';
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;
GO

-- try to modify MID of component to another machine
BEGIN TRY
    UPDATE KeyComponents
    SET MID = 'm1'
    WHERE MID = 'm4' AND CID = 'C3';
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;
GO