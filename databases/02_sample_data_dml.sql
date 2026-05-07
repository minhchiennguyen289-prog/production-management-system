-- ============================================================
--  PROJECT 12: PRODUCTION MANAGEMENT SYSTEM
--  FILE 2: SAMPLE DATA (DML)
--  DATCOM Lab - NEU College of Technology
-- ============================================================

USE production_db;

-- ============================================================
-- 1. SUPPLIERS (5 records)
-- ============================================================
INSERT INTO Suppliers (SupplierName, Address, PhoneNumber) VALUES
('TSMC',             'Hsinchu Science Park, Taiwan', '+886-3-5636688'),
('Foxconn',          'Tu Thanh, Long Hua, China',    '+86-755-2812'),
('Samsung Display',  'Giheung, South Korea',          '+82-31-209-7114'),
('Sony Semiconductor','Atsugi, Japan',                '+81-46-230-5111'),
('LG Innotek',       'Seoul, South Korea',            '+82-2-3777-1114');

-- ============================================================
-- 2. MATERIALS (10 records)
-- ============================================================
INSERT INTO Materials (MaterialName, Unit, UnitCost, SupplierID) VALUES
('M3 Pro Chip',                  'piece', 180.00, 1),
('A17 Pro Chip',                 'piece', 135.00, 1),
('Liquid Retina XDR Display',    'piece', 110.00, 3),
('Titanium Grade 5 Frame',       'piece',  65.00, 2),
('Camera Module (Sony Sensor)',  'piece',  55.00, 4),
('LiDAR Scanner',                'piece',  25.00, 5),
('NAND Flash 512GB',             'piece',  45.00, 3),
('Lithium-ion Battery (High Cap)','piece', 30.00, 2),
('Aluminum Shell (Unibody)',     'kg',     15.00, 2),
('Eco-friendly Packaging',       'piece',   2.50, 2);

-- ============================================================
-- 3. PLANTS (3 records)
-- ============================================================
INSERT INTO Plants (PlantName, Address) VALUES
('Foxconn Zhengzhou',    'Henan, China'),
('Pegatron Shanghai',    'Shanghai, China'),
('Luxshare ICT Vietnam', 'Bac Giang, Vietnam');

-- ============================================================
-- 4. PRODUCTS (5 records)
-- ============================================================
INSERT INTO Products (ProductName, Description, UnitPrice, StockQuantity) VALUES
('iPhone 15 Pro Max',    'Titanium build, A17 Pro chip',   1199.00, 150),
('MacBook Pro 16" M3 Pro','Liquid Retina XDR, M3 Pro chip',2499.00,  80),
('iPad Pro M4',          'Ultra Thin, Tandem OLED',         999.00, 120),
('Apple Watch Ultra 2',  'Rugged, 3000 nits display',       799.00, 200),
('AirPods Pro 2',        'H2 chip, USB-C charging',         249.00, 500);

-- ============================================================
-- 5. BILL OF MATERIALS (18 records)
-- ============================================================
INSERT INTO Bill_Of_Materials (ProductID, MaterialID, QuantityRequired) VALUES
-- iPhone 15 Pro Max (ProductID=1)
(1, 2, 1.00), (1, 3, 1.00), (1, 4, 1.00), (1, 5, 1.00), (1, 10, 1.00),
-- MacBook Pro 16" M3 Pro (ProductID=2)
(2, 1, 1.00), (2, 3, 1.00), (2, 9, 1.20), (2,  7, 1.00), (2, 10, 1.00),
-- iPad Pro M4 (ProductID=3)
(3, 1, 1.00), (3, 3, 1.00), (3, 8, 1.00), (3, 10, 1.00),
-- Apple Watch Ultra 2 (ProductID=4)
(4, 2, 1.00), (4, 4, 0.50), (4, 8, 1.00), (4, 10, 1.00);

-- ============================================================
-- 6. ORDERS (50 records — generated via procedure)
-- ============================================================
DELIMITER $$
CREATE PROCEDURE PopulateAppleOrders()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 50 DO
        INSERT INTO Orders (ProductID, PlantID, Quantity, StartDate, Status)
        VALUES (
            FLOOR(1 + RAND() * 5),
            FLOOR(1 + RAND() * 3),
            FLOOR(50 + RAND() * 500),
            DATE_ADD('2026-01-01', INTERVAL FLOOR(RAND() * 120) DAY),
            CASE
                WHEN i % 3 = 0 THEN 'Completed'
                WHEN i % 3 = 1 THEN 'In Progress'
                ELSE 'Pending'
            END
        );
        SET i = i + 1;
    END WHILE;
END$$
DELIMITER ;

CALL PopulateAppleOrders();
DROP PROCEDURE PopulateAppleOrders;
