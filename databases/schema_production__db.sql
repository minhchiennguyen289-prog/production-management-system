-- ============================================================
--  PROJECT 12: PRODUCTION MANAGEMENT SYSTEM
--  FILE 1: DATABASE SCHEMA, OBJECTS & SECURITY
-- ============================================================

CREATE DATABASE IF NOT EXISTS production__db;
USE production__db;

CREATE TABLE Products (
    ProductID     INT AUTO_INCREMENT PRIMARY KEY,
    ProductName   VARCHAR(100)   NOT NULL,
    Description   TEXT,
    UnitPrice     DECIMAL(10,2)  NOT NULL,
    StockQuantity INT            NOT NULL DEFAULT 0
);

CREATE TABLE Suppliers (
    SupplierID      INT AUTO_INCREMENT PRIMARY KEY,
    SupplierName    VARCHAR(100) NOT NULL,
    Address         VARCHAR(255),
    PhoneNumber     VARCHAR(20),
    EncryptedPhone  VARBINARY(255)
);

CREATE TABLE Materials (
    MaterialID     INT AUTO_INCREMENT PRIMARY KEY,
    MaterialName   VARCHAR(100)  NOT NULL,
    Unit           VARCHAR(20)   NOT NULL,
    UnitCost       DECIMAL(10,2) NOT NULL,
    StockQuantity  INT NOT NULL DEFAULT 0,
    SupplierID     INT,
    FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID) ON DELETE SET NULL
);

CREATE TABLE Plants (
    PlantID   INT AUTO_INCREMENT PRIMARY KEY,
    PlantName VARCHAR(100) NOT NULL,
    Address   VARCHAR(255)
);

CREATE TABLE Bill_Of_Materials (
    ProductID        INT,
    MaterialID       INT,
    QuantityRequired DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (ProductID, MaterialID),
    FOREIGN KEY (ProductID)  REFERENCES Products(ProductID)  ON DELETE CASCADE,
    FOREIGN KEY (MaterialID) REFERENCES Materials(MaterialID) ON DELETE CASCADE
);

CREATE TABLE MaterialPurchases (
    PurchaseID    INT AUTO_INCREMENT PRIMARY KEY,
    SupplierID    INT NOT NULL,
    MaterialID    INT NOT NULL,
    Quantity      INT NOT NULL,
    PurchaseDate  DATE NOT NULL,
    TotalCost     DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID),
    FOREIGN KEY (MaterialID) REFERENCES Materials(MaterialID)
);

CREATE TABLE Orders (
    OrderID   INT AUTO_INCREMENT PRIMARY KEY,
    ProductID INT,
    PlantID   INT,
    Quantity  INT          NOT NULL,
    StartDate DATE         NOT NULL,
    Status    VARCHAR(50)  DEFAULT 'Pending',
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE RESTRICT,
    FOREIGN KEY (PlantID)   REFERENCES Plants(PlantID)
);

CREATE INDEX idx_orders_status     ON Orders(Status);
CREATE INDEX idx_materials_name    ON Materials(MaterialName);
CREATE INDEX idx_materials_supplier ON Materials(SupplierID);
CREATE INDEX idx_orders_startdate  ON Orders(StartDate);

CREATE VIEW vw_ProductionStatus AS
SELECT o.OrderID, p.ProductName, pl.PlantName, o.Quantity, o.StartDate, o.Status
FROM Orders o
JOIN Products p  ON o.ProductID = p.ProductID
JOIN Plants   pl ON o.PlantID   = pl.PlantID;

CREATE VIEW vw_MaterialUsage AS
SELECT m.MaterialID, m.MaterialName, m.Unit, s.SupplierName,
    SUM(bom.QuantityRequired * o.Quantity) AS TotalConsumed,
    SUM(bom.QuantityRequired * o.Quantity * m.UnitCost) AS TotalMaterialCost
FROM Bill_Of_Materials bom
JOIN Materials m  ON bom.MaterialID = m.MaterialID
JOIN Suppliers s  ON m.SupplierID   = s.SupplierID
JOIN Orders    o  ON bom.ProductID  = o.ProductID
WHERE o.Status IN ('In Progress', 'Completed')
GROUP BY m.MaterialID, m.MaterialName, m.Unit, s.SupplierName;

CREATE VIEW vw_SupplierDeliveries AS
SELECT s.SupplierID, s.SupplierName, s.PhoneNumber,
    COUNT(DISTINCT m.MaterialID) AS MaterialsSupplied,
    SUM(bom.QuantityRequired * o.Quantity) AS TotalUnitsDelivered,
    SUM(bom.QuantityRequired * o.Quantity * m.UnitCost) AS TotalDeliveryValue
FROM Suppliers s
JOIN Materials         m   ON s.SupplierID  = m.SupplierID
JOIN Bill_Of_Materials bom ON m.MaterialID  = bom.MaterialID
JOIN Orders            o   ON bom.ProductID = o.ProductID
WHERE o.Status IN ('In Progress', 'Completed')
GROUP BY s.SupplierID, s.SupplierName, s.PhoneNumber;

CREATE OR REPLACE VIEW vw_MaterialInventory AS
SELECT m.MaterialID, m.MaterialName, m.Unit, m.StockQuantity, s.SupplierName
FROM Materials m
LEFT JOIN Suppliers s ON m.SupplierID = s.SupplierID;

CREATE OR REPLACE VIEW vw_PurchaseHistory AS
SELECT mp.PurchaseID, s.SupplierName, m.MaterialName, mp.Quantity, mp.TotalCost, mp.PurchaseDate
FROM MaterialPurchases mp
JOIN Suppliers s ON mp.SupplierID = s.SupplierID
JOIN Materials m ON mp.MaterialID = m.MaterialID;

DELIMITER $$
CREATE FUNCTION CalculateMaterialCost(p_ProductID INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE total_cost DECIMAL(10,2);
    SELECT COALESCE(SUM(bom.QuantityRequired * mat.UnitCost), 0) INTO total_cost
    FROM Bill_Of_Materials bom
    JOIN Materials mat ON bom.MaterialID = mat.MaterialID
    WHERE bom.ProductID = p_ProductID;
    RETURN total_cost;
END$$

CREATE PROCEDURE CreateProductionOrder(
    IN p_ProductID INT, IN p_PlantID INT, IN p_Quantity INT, IN p_StartDate DATE
)
BEGIN
    INSERT INTO Orders (ProductID, PlantID, Quantity, StartDate)
    VALUES (p_ProductID, p_PlantID, p_Quantity, p_StartDate);
    SELECT CONCAT('Successfully created order for Product ID: ', p_ProductID) AS Message;
END$$

CREATE PROCEDURE GetProductionReport(IN p_StartDate DATE, IN p_EndDate DATE)
BEGIN
    SELECT p.ProductName, pl.PlantName, o.Status,
        COUNT(o.OrderID) AS TotalOrders, SUM(o.Quantity) AS TotalUnitsProduced,
        SUM(o.Quantity * p.UnitPrice) AS TotalProductionValue
    FROM Orders o
    JOIN Products p  ON o.ProductID = p.ProductID
    JOIN Plants   pl ON o.PlantID   = pl.PlantID
    WHERE o.StartDate BETWEEN p_StartDate AND p_EndDate
    GROUP BY p.ProductName, pl.PlantName, o.Status
    ORDER BY p.ProductName;
END$$

CREATE PROCEDURE UpdateMaterialStock(IN p_material_id INT, IN p_quantity INT)
BEGIN
    UPDATE Materials SET StockQuantity = StockQuantity + p_quantity WHERE MaterialID = p_material_id;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_reduce_material_inventory
AFTER UPDATE ON Orders
FOR EACH ROW
BEGIN
    IF NEW.Status = 'Completed' AND OLD.Status <> 'Completed' THEN
        UPDATE Products SET StockQuantity = StockQuantity + NEW.Quantity WHERE ProductID = NEW.ProductID;
        UPDATE Materials m
        JOIN Bill_Of_Materials bom ON m.MaterialID = bom.MaterialID
        SET m.StockQuantity = m.StockQuantity - (bom.QuantityRequired * NEW.Quantity)
        WHERE bom.ProductID = NEW.ProductID;
    END IF;
END$$
DELIMITER ;

CREATE USER IF NOT EXISTS 'prod_manager'@'localhost' IDENTIFIED BY 'ProdMgr@2026!';
GRANT SELECT ON production__db.Products            TO 'prod_manager'@'localhost';
GRANT SELECT ON production__db.Materials           TO 'prod_manager'@'localhost';
GRANT SELECT ON production__db.Suppliers           TO 'prod_manager'@'localhost';
GRANT SELECT ON production__db.Plants              TO 'prod_manager'@'localhost';
GRANT SELECT ON production__db.Bill_Of_Materials   TO 'prod_manager'@'localhost';
GRANT SELECT, INSERT, UPDATE ON production__db.Orders TO 'prod_manager'@'localhost';
GRANT SELECT ON production__db.vw_ProductionStatus   TO 'prod_manager'@'localhost';
GRANT SELECT ON production__db.vw_MaterialUsage      TO 'prod_manager'@'localhost';
GRANT SELECT ON production__db.vw_SupplierDeliveries TO 'prod_manager'@'localhost';
GRANT EXECUTE ON PROCEDURE production__db.CreateProductionOrder TO 'prod_manager'@'localhost';
GRANT EXECUTE ON PROCEDURE production__db.GetProductionReport   TO 'prod_manager'@'localhost';

CREATE USER IF NOT EXISTS 'warehouse_staff'@'localhost' IDENTIFIED BY 'WareH0use@2026!';
GRANT SELECT ON production__db.Products          TO 'warehouse_staff'@'localhost';
GRANT SELECT ON production__db.Materials         TO 'warehouse_staff'@'localhost';
GRANT SELECT ON production__db.Bill_Of_Materials TO 'warehouse_staff'@'localhost';
GRANT SELECT ON production__db.Orders            TO 'warehouse_staff'@'localhost';
GRANT UPDATE (StockQuantity) ON production__db.Products TO 'warehouse_staff'@'localhost';
GRANT UPDATE (StockQuantity) ON production__db.Materials TO 'warehouse_staff'@'localhost';
GRANT SELECT ON production__db.vw_ProductionStatus      TO 'warehouse_staff'@'localhost';
GRANT SELECT ON production__db.vw_MaterialUsage         TO 'warehouse_staff'@'localhost';
GRANT SELECT ON production__db.vw_MaterialInventory     TO 'warehouse_staff'@'localhost';
GRANT EXECUTE ON PROCEDURE production__db.UpdateMaterialStock TO 'warehouse_staff'@'localhost';

CREATE USER IF NOT EXISTS 'finance_user'@'localhost' IDENTIFIED BY 'F1nance@2026!';
GRANT SELECT (ProductID, ProductName, UnitPrice) ON production__db.Products   TO 'finance_user'@'localhost';
GRANT SELECT (MaterialID, MaterialName, UnitCost) ON production__db.Materials TO 'finance_user'@'localhost';
GRANT SELECT ON production__db.vw_MaterialUsage      TO 'finance_user'@'localhost';
GRANT SELECT ON production__db.vw_SupplierDeliveries TO 'finance_user'@'localhost';
GRANT SELECT ON production__db.vw_PurchaseHistory    TO 'finance_user'@'localhost';
GRANT EXECUTE ON FUNCTION  production__db.CalculateMaterialCost    TO 'finance_user'@'localhost';
GRANT EXECUTE ON PROCEDURE production__db.GetProductionReport      TO 'finance_user'@'localhost';
FLUSH PRIVILEGES;