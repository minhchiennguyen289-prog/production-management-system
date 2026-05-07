-- ============================================================
--  PROJECT 12: PRODUCTION MANAGEMENT SYSTEM
--  FILE 2: SAMPLE DATA (DML)
-- ============================================================

USE production__db;

-- AES_ENCRYPT
INSERT INTO Suppliers (SupplierName, Address, PhoneNumber, EncryptedPhone) VALUES
('TSMC',             'Hsinchu Science Park, Taiwan', '+886-3-5636688', AES_ENCRYPT('+886-3-5636688', 'DATCOM2026')),
('Foxconn',          'Tu Thanh, Long Hua, China',    '+86-755-2812',   AES_ENCRYPT('+86-755-2812', 'DATCOM2026')),
('Samsung Display',  'Giheung, South Korea',          '+82-31-209-7114',AES_ENCRYPT('+82-31-209-7114', 'DATCOM2026')),
('Sony Semiconductor','Atsugi, Japan',                '+81-46-230-5111',AES_ENCRYPT('+81-46-230-5111', 'DATCOM2026')),
('LG Innotek',       'Seoul, South Korea',            '+82-2-3777-1114',AES_ENCRYPT('+82-2-3777-1114', 'DATCOM2026'));

INSERT INTO Materials (MaterialName, Unit, UnitCost, StockQuantity, SupplierID) VALUES
('M3 Pro Chip',                  'piece', 180.00, 500, 1),
('A17 Pro Chip',                 'piece', 135.00, 400, 1),
('Liquid Retina XDR Display',    'piece', 110.00, 300, 3),
('Titanium Grade 5 Frame',       'piece',  65.00, 600, 2),
('Camera Module (Sony Sensor)',  'piece',  55.00, 350, 4),
('LiDAR Scanner',                'piece',  25.00, 450, 5),
('NAND Flash 512GB',             'piece',  45.00, 700, 3),
('Lithium-ion Battery (High Cap)','piece', 30.00, 550, 2),
('Aluminum Shell (Unibody)',     'kg',     15.00, 900, 2),
('Eco-friendly Packaging',       'piece',   2.50, 1000, 2);

INSERT INTO Plants (PlantName, Address) VALUES
('Foxconn Zhengzhou',    'Henan, China'),
('Pegatron Shanghai',    'Shanghai, China'),
('Luxshare ICT Vietnam', 'Bac Giang, Vietnam'),
('Compal Electronics',   'Vinh Phuc, Vietnam'),
('Wistron Infocomm',     'Kunshan, China');

INSERT INTO Products (ProductName, Description, UnitPrice, StockQuantity) VALUES
('iPhone 15 Pro Max',    'Titanium build, A17 Pro chip',   1199.00, 150),
('MacBook Pro 16" M3 Pro','Liquid Retina XDR, M3 Pro chip',2499.00,  80),
('iPad Pro M4',          'Ultra Thin, Tandem OLED',         999.00, 120),
('Apple Watch Ultra 2',  'Rugged, 3000 nits display',       799.00, 200),
('AirPods Pro 2',        'H2 chip, USB-C charging',         249.00, 500);

INSERT INTO Bill_Of_Materials (ProductID, MaterialID, QuantityRequired) VALUES
(1, 2, 1.00), (1, 3, 1.00), (1, 4, 1.00), (1, 5, 1.00), (1, 10, 1.00),
(2, 1, 1.00), (2, 3, 1.00), (2, 9, 1.20), (2,  7, 1.00), (2, 10, 1.00),
(3, 1, 1.00), (3, 3, 1.00), (3, 8, 1.00), (3, 10, 1.00),
(4, 2, 1.00), (4, 4, 0.50), (4, 8, 1.00), (4, 10, 1.00);

INSERT INTO MaterialPurchases (SupplierID, MaterialID, Quantity, PurchaseDate, TotalCost) VALUES
(1, 1, 100, '2026-01-10', 18000.00),
(1, 2, 120, '2026-01-12', 16200.00),
(3, 3, 80,  '2026-01-15', 8800.00),
(4, 5, 60,  '2026-01-20', 3300.00),
(2, 8, 150, '2026-01-25', 4500.00);

DELIMITER $$
CREATE PROCEDURE PopulateAppleOrders()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 50 DO
        INSERT INTO Orders (ProductID, PlantID, Quantity, StartDate, Status)
        VALUES (
            FLOOR(1 + RAND() * 5),
            FLOOR(1 + RAND() * 5),
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