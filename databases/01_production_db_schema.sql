-- ============================================================
--  PROJECT 12: PRODUCTION MANAGEMENT SYSTEM
--  FILE 1: DATABASE SCHEMA, OBJECTS & SECURITY
--  DATCOM Lab - NEU College of Technology
-- ============================================================

CREATE DATABASE IF NOT EXISTS production_db;
USE production_db;

-- ============================================================
-- SECTION 1: TABLE STRUCTURES
-- ============================================================

CREATE TABLE Products (
    ProductID     INT AUTO_INCREMENT PRIMARY KEY,
    ProductName   VARCHAR(100)   NOT NULL,
    Description   TEXT,
    UnitPrice     DECIMAL(10,2)  NOT NULL,
    StockQuantity INT            NOT NULL DEFAULT 0
);

CREATE TABLE Suppliers (
    SupplierID   INT AUTO_INCREMENT PRIMARY KEY,
    SupplierName VARCHAR(100) NOT NULL,
    Address      VARCHAR(255),
    PhoneNumber  VARCHAR(20)
);

CREATE TABLE Materials (
    MaterialID   INT AUTO_INCREMENT PRIMARY KEY,
    MaterialName VARCHAR(100)  NOT NULL,
    Unit         VARCHAR(20)   NOT NULL,
    UnitCost     DECIMAL(10,2) NOT NULL,
    SupplierID   INT,
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

-- ============================================================
-- SECTION 2: INDEXES
-- ============================================================

-- Speed up filtering orders by status
CREATE INDEX idx_orders_status     ON Orders(Status);
-- Speed up material name searches
CREATE INDEX idx_materials_name    ON Materials(MaterialName);
-- Speed up joins between Materials and Suppliers
CREATE INDEX idx_materials_supplier ON Materials(SupplierID);
-- Speed up order date range queries for reports
CREATE INDEX idx_orders_startdate  ON Orders(StartDate);

-- ============================================================
-- SECTION 3: VIEWS
-- ============================================================

-- VIEW 1: Current Production Status
-- Shows all orders with product and plant details
CREATE VIEW vw_ProductionStatus AS
SELECT
    o.OrderID,
    p.ProductName,
    pl.PlantName,
    o.Quantity,
    o.StartDate,
    o.Status
FROM Orders o
JOIN Products p  ON o.ProductID = p.ProductID
JOIN Plants   pl ON o.PlantID   = pl.PlantID;

-- VIEW 2: Material Usage per Product
-- Shows how much each material is consumed across all orders
CREATE VIEW vw_MaterialUsage AS
SELECT
    m.MaterialID,
    m.MaterialName,
    m.Unit,
    s.SupplierName,
    SUM(bom.QuantityRequired * o.Quantity) AS TotalConsumed,
    SUM(bom.QuantityRequired * o.Quantity * m.UnitCost) AS TotalMaterialCost
FROM Bill_Of_Materials bom
JOIN Materials m  ON bom.MaterialID = m.MaterialID
JOIN Suppliers s  ON m.SupplierID   = s.SupplierID
JOIN Orders    o  ON bom.ProductID  = o.ProductID
WHERE o.Status IN ('In Progress', 'Completed')
GROUP BY m.MaterialID, m.MaterialName, m.Unit, s.SupplierName;

-- VIEW 3: Supplier Delivery Overview
-- Shows supplier contribution: how many materials supplied and total value
CREATE VIEW vw_SupplierDeliveries AS
SELECT
    s.SupplierID,
    s.SupplierName,
    s.PhoneNumber,
    COUNT(DISTINCT m.MaterialID)                      AS MaterialsSupplied,
    SUM(bom.QuantityRequired * o.Quantity)            AS TotalUnitsDelivered,
    SUM(bom.QuantityRequired * o.Quantity * m.UnitCost) AS TotalDeliveryValue
FROM Suppliers s
JOIN Materials         m   ON s.SupplierID  = m.SupplierID
JOIN Bill_Of_Materials bom ON m.MaterialID  = bom.MaterialID
JOIN Orders            o   ON bom.ProductID = o.ProductID
WHERE o.Status IN ('In Progress', 'Completed')
GROUP BY s.SupplierID, s.SupplierName, s.PhoneNumber;

-- ============================================================
-- SECTION 4: USER-DEFINED FUNCTION
-- ============================================================

-- Calculate total raw material cost to produce one unit of a product
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
DELIMITER ;

-- ============================================================
-- SECTION 5: STORED PROCEDURES
-- ============================================================

-- PROCEDURE 1: Create a new production order
DELIMITER $$
CREATE PROCEDURE CreateProductionOrder(
    IN p_ProductID INT,
    IN p_PlantID   INT,
    IN p_Quantity  INT,
    IN p_StartDate DATE
)
BEGIN
    INSERT INTO Orders (ProductID, PlantID, Quantity, StartDate)
    VALUES (p_ProductID, p_PlantID, p_Quantity, p_StartDate);
    SELECT CONCAT('Successfully created order for Product ID: ', p_ProductID) AS Message;
END$$
DELIMITER ;

-- PROCEDURE 2: Generate production report for a given date range
DELIMITER $$
CREATE PROCEDURE GetProductionReport(
    IN p_StartDate DATE,
    IN p_EndDate   DATE
)
BEGIN
    SELECT
        p.ProductName,
        pl.PlantName,
        o.Status,
        COUNT(o.OrderID)   AS TotalOrders,
        SUM(o.Quantity)    AS TotalUnitsProduced,
        SUM(o.Quantity * p.UnitPrice) AS TotalProductionValue
    FROM Orders o
    JOIN Products p  ON o.ProductID = p.ProductID
    JOIN Plants   pl ON o.PlantID   = pl.PlantID
    WHERE o.StartDate BETWEEN p_StartDate AND p_EndDate
    GROUP BY p.ProductName, pl.PlantName, o.Status
    ORDER BY p.ProductName;
END$$
DELIMITER ;

-- ============================================================
-- SECTION 6: TRIGGERS
-- ============================================================

-- TRIGGER: Automatically update product stock when an order is completed
DELIMITER $$
CREATE TRIGGER AfterOrderCompleted
AFTER UPDATE ON Orders
FOR EACH ROW
BEGIN
    IF NEW.Status = 'Completed' AND OLD.Status != 'Completed' THEN
        UPDATE Products
        SET StockQuantity = StockQuantity + NEW.Quantity
        WHERE ProductID = NEW.ProductID;
    END IF;
END$$
DELIMITER ;

-- ============================================================
-- SECTION 7: DATABASE SECURITY - ROLES & PERMISSIONS
-- ============================================================

-- Create application users with restricted privileges

-- Role 1: Production Manager
--   Can view all data, create and update orders, cannot touch financials
CREATE USER IF NOT EXISTS 'prod_manager'@'localhost' IDENTIFIED BY 'ProdMgr@2026!';
GRANT SELECT ON production_db.Products            TO 'prod_manager'@'localhost';
GRANT SELECT ON production_db.Materials           TO 'prod_manager'@'localhost';
GRANT SELECT ON production_db.Suppliers           TO 'prod_manager'@'localhost';
GRANT SELECT ON production_db.Plants              TO 'prod_manager'@'localhost';
GRANT SELECT ON production_db.Bill_Of_Materials   TO 'prod_manager'@'localhost';
GRANT SELECT, INSERT, UPDATE ON production_db.Orders TO 'prod_manager'@'localhost';
GRANT SELECT ON production_db.vw_ProductionStatus   TO 'prod_manager'@'localhost';
GRANT SELECT ON production_db.vw_MaterialUsage      TO 'prod_manager'@'localhost';
GRANT SELECT ON production_db.vw_SupplierDeliveries TO 'prod_manager'@'localhost';
GRANT EXECUTE ON PROCEDURE production_db.CreateProductionOrder TO 'prod_manager'@'localhost';
GRANT EXECUTE ON PROCEDURE production_db.GetProductionReport   TO 'prod_manager'@'localhost';

-- Role 2: Warehouse Staff
--   Can view products and materials, update stock quantities only
CREATE USER IF NOT EXISTS 'warehouse_staff'@'localhost' IDENTIFIED BY 'WareH0use@2026!';
GRANT SELECT ON production_db.Products          TO 'warehouse_staff'@'localhost';
GRANT SELECT ON production_db.Materials         TO 'warehouse_staff'@'localhost';
GRANT SELECT ON production_db.Bill_Of_Materials TO 'warehouse_staff'@'localhost';
GRANT SELECT ON production_db.Orders            TO 'warehouse_staff'@'localhost';
GRANT UPDATE (StockQuantity) ON production_db.Products TO 'warehouse_staff'@'localhost';
GRANT SELECT ON production_db.vw_ProductionStatus      TO 'warehouse_staff'@'localhost';
GRANT SELECT ON production_db.vw_MaterialUsage         TO 'warehouse_staff'@'localhost';

-- Role 3: Finance
--   Read-only access to pricing and financial views; cannot modify operational data
CREATE USER IF NOT EXISTS 'finance_user'@'localhost' IDENTIFIED BY 'F1nance@2026!';
GRANT SELECT (ProductID, ProductName, UnitPrice) ON production_db.Products   TO 'finance_user'@'localhost';
GRANT SELECT (MaterialID, MaterialName, UnitCost) ON production_db.Materials TO 'finance_user'@'localhost';
GRANT SELECT ON production_db.vw_MaterialUsage      TO 'finance_user'@'localhost';
GRANT SELECT ON production_db.vw_SupplierDeliveries TO 'finance_user'@'localhost';
GRANT EXECUTE ON FUNCTION  production_db.CalculateMaterialCost    TO 'finance_user'@'localhost';
GRANT EXECUTE ON PROCEDURE production_db.GetProductionReport      TO 'finance_user'@'localhost';

FLUSH PRIVILEGES;

-- ============================================================
-- SECTION 8: BACKUP & EXPORT POLICY (documentation script)
-- ============================================================

-- NOTE: Run the following shell commands on the MySQL server host
-- for regular automated backups.
--
-- Daily backup (keep 7 days):
--   mysqldump -u root -p production_db > /backups/production_db_$(date +%F).sql
--
-- Weekly compressed backup:
--   mysqldump -u root -p --single-transaction production_db | \
--       gzip > /backups/production_db_weekly_$(date +%Y%W).sql.gz
--
-- Restore from backup:
--   mysql -u root -p production_db < /backups/production_db_YYYY-MM-DD.sql
--
-- Recommended cron schedule (crontab -e):
--   0 2 * * *  /usr/bin/mysqldump -u root -pPASSWORD production_db > /backups/prod_$(date +\%F).sql
--   0 3 * * 0  /usr/bin/mysqldump -u root -pPASSWORD production_db | gzip > /backups/prod_weekly_$(date +\%Y\%W).sql.gz
