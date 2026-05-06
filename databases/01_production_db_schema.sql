CREATE DATABASE IF NOT EXISTS production_db;
USE production_db;

CREATE TABLE Products (
    ProductID INT AUTO_INCREMENT PRIMARY KEY,
    ProductName VARCHAR(100) NOT NULL,
    Description TEXT,
    UnitPrice DECIMAL(10,2) NOT NULL,
    StockQuantity INT NOT NULL DEFAULT 0
);

CREATE TABLE Materials (
    MaterialID INT AUTO_INCREMENT PRIMARY KEY,
    MaterialName VARCHAR(100) NOT NULL,
    Unit VARCHAR(20) NOT NULL,
    UnitCost DECIMAL(10,2) NOT NULL,
    SupplierID INT
);

CREATE TABLE Plants (
    PlantID INT AUTO_INCREMENT PRIMARY KEY,
    PlantName VARCHAR(100) NOT NULL,
    Address VARCHAR(255)
);

CREATE TABLE Suppliers (
    SupplierID INT AUTO_INCREMENT PRIMARY KEY,
    SupplierName VARCHAR(100) NOT NULL,
    Address VARCHAR(255),
    PhoneNumber VARCHAR(20)
);

CREATE TABLE Bill_Of_Materials (
    ProductID INT,
    MaterialID INT,
    QuantityRequired DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (ProductID, MaterialID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE CASCADE,
    FOREIGN KEY (MaterialID) REFERENCES Materials(MaterialID) ON DELETE CASCADE
);

CREATE TABLE Orders (
    OrderID INT AUTO_INCREMENT PRIMARY KEY,
    ProductID INT,
    PlantID INT,
    Quantity INT NOT NULL,
    StartDate DATE NOT NULL,
    Status VARCHAR(50) DEFAULT 'Pending',
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE RESTRICT,
    FOREIGN KEY (PlantID) REFERENCES Plants(PlantID)
);

-- 1. USER-DEFINED FUNCTION (Ref: 2.1.3)
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

-- 2. TRIGGER (Ref: 2.2.3)
DELIMITER $$
CREATE TRIGGER AfterOrderCompleted
AFTER UPDATE ON Orders
FOR EACH ROW
BEGIN
    IF NEW.Status = 'Completed' AND OLD.Status != 'Completed' THEN
        UPDATE Products SET StockQuantity = StockQuantity + NEW.Quantity
        WHERE ProductID = NEW.ProductID;
    END IF;
END$$
DELIMITER ;

-- 3. STORED PROCEDURE (Ref: 2.3.3)[cite: 2]
DELIMITER $$
CREATE PROCEDURE CreateProductionOrder(
    IN p_ProductID INT, IN p_PlantID INT, IN p_Quantity INT, IN p_StartDate DATE
)
BEGIN
    INSERT INTO Orders (ProductID, PlantID, Quantity, StartDate)
    VALUES (p_ProductID, p_PlantID, p_Quantity, p_StartDate);
    SELECT CONCAT('Successfully created order for Product ID: ', p_ProductID) AS Message;
END$$
DELIMITER ;

-- 4. VIEW (Ref: 2.4.3)[cite: 2]
CREATE VIEW vw_ProductionStatus AS
SELECT o.OrderID, p.ProductName, pl.PlantName, o.Quantity, o.StartDate, o.Status
FROM Orders o
JOIN Products p ON o.ProductID = p.ProductID
JOIN Plants pl ON o.PlantID = pl.PlantID;

-- 5. INDEXES (Ref: 2.5.3)[cite: 2]
CREATE INDEX idx_orders_status ON Orders(Status);
CREATE INDEX idx_materials_name ON Materials(MaterialName);