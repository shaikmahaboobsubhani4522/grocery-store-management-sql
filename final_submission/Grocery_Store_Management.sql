-- ============================================================================
-- GROCERY STORE MANAGEMENT SYSTEM — COMPLETE TURNKEY SQL PIPELINE
-- ============================================================================
-- Author: Mahaboob Subhani Shaik
-- Role: Senior SQL Developer & Data Analyst
-- Target DBMS: MySQL 8.x (InnoDB Engine, utf8mb4_unicode_ci)
-- Description: Consolidated master script containing database creation,
--              3NF relational schema DDL, deterministic 1,170-row CSV data
--              insertion, 18-suite QA validation, and all 25 business analytical
--              queries across 6 operational domains.
--
-- Instructions for Single-Command Turnkey Execution:
--   mysql -u root -p < Grocery_Store_Management.sql
-- ============================================================================

-- ============================================================================
-- PART: 01_create_database.sql
-- ============================================================================
-- ============================================================================
-- Project: Grocery Store Management SQL Database
-- File: 01_create_database.sql
-- Description: Idempotent database creation script with production character sets
-- Author: Mahaboob Subhani Shaik
-- Target DBMS: MySQL 8.x
-- ============================================================================

-- Step 1: Create Database if it does not already exist
-- Character Set: utf8mb4 (supports full Unicode, including emojis and international characters)
-- Collation: utf8mb4_unicode_ci (standard Unicode case-insensitive sorting and comparison)
CREATE DATABASE IF NOT EXISTS grocery_store
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Step 2: Switch to the newly created database context
USE grocery_store;

-- Verification query
SELECT 
    SCHEMA_NAME AS database_name,
    DEFAULT_CHARACTER_SET_NAME AS character_set,
    DEFAULT_COLLATION_NAME AS collation_name
FROM information_schema.SCHEMATA
WHERE SCHEMA_NAME = 'grocery_store';


-- ============================================================================
-- PART: 02_create_tables.sql
-- ============================================================================
-- ============================================================================
-- Project: Grocery Store Management SQL Database
-- File: 02_create_tables.sql
-- Description: DDL script creating all seven normalized relational tables
-- Author: Mahaboob Subhani Shaik
-- Target DBMS: MySQL 8.x
-- ============================================================================

USE grocery_store;

-- ----------------------------------------------------------------------------
-- ARCHITECTURAL DECISION NOTES:
-- 1. AUTO_INCREMENT Strategy:
--    The assignment specification (PDF Page 5) instructs:
--    "Add auto increment constraint in all the table's primary keys."
--    The source CSV files contain pre-assigned sequential IDs (1..N).
--    The validated source IDs will be explicitly inserted into AUTO_INCREMENT
--    columns to preserve the original relational IDs.
--
-- 2. Foreign Key Cascade Behavior:
--    The specification explicitly requires cascading foreign keys on all
--    relationships: ON UPDATE CASCADE ON DELETE CASCADE.
--
-- 3. Date Storage:
--    In strict accordance with the project PDF schema, hire_date and order_date
--    are defined as VARCHAR(255). Temporal queries utilize MySQL's
--    STR_TO_DATE(column, '%m/%d/%Y') function for reliable parsing.
-- ----------------------------------------------------------------------------

-- Disable foreign key checks during schema recreation for clean idempotency
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS order_details;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS supplier;

SET FOREIGN_KEY_CHECKS = 1;


-- ============================================================================
-- 1. Supplier Table (Parent Entity)
-- Stores wholesale vendor details and operational warehouse addresses.
-- Source: Suppliers.csv (5 records)
-- ============================================================================
CREATE TABLE supplier (
    sup_id TINYINT AUTO_INCREMENT PRIMARY KEY,
    sup_name VARCHAR(255) NOT NULL,
    address TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- 2. Categories Table (Parent Entity)
-- Stores product department classifications.
-- Source: Categories.csv (5 records)
-- ============================================================================
CREATE TABLE categories (
    cat_id TINYINT AUTO_INCREMENT PRIMARY KEY,
    cat_name VARCHAR(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- 3. Employees Table (Parent Entity)
-- Stores store staff profiles and employment start dates.
-- Source: Store_Employees.csv (10 records)
-- ============================================================================
CREATE TABLE employees (
    emp_id TINYINT AUTO_INCREMENT PRIMARY KEY,
    emp_name VARCHAR(255) NOT NULL,
    hire_date VARCHAR(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- 4. Customers Table (Parent Entity)
-- Stores retail grocery customer profiles and addresses.
-- Source: Customers.csv (200 records)
-- ============================================================================
CREATE TABLE customers (
    cust_id SMALLINT AUTO_INCREMENT PRIMARY KEY,
    cust_name VARCHAR(255) NOT NULL,
    address TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- 5. Products Table (Child of supplier and categories)
-- Stores grocery catalog inventory items, supplier mapping, and retail price.
-- Source: Products.csv (50 records)
-- Relationships:
--   - supplier (1) -> (M) products
--   - categories (1) -> (M) products
-- ============================================================================
CREATE TABLE products (
    prod_id TINYINT AUTO_INCREMENT PRIMARY KEY,
    prod_name VARCHAR(255) NOT NULL,
    sup_id TINYINT NOT NULL,
    cat_id TINYINT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    CONSTRAINT chk_prod_price CHECK (price >= 0),
    CONSTRAINT fk_products_supplier
        FOREIGN KEY (sup_id) REFERENCES supplier(sup_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_products_categories
        FOREIGN KEY (cat_id) REFERENCES categories(cat_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- 6. Orders Table (Child of customers and employees)
-- Stores order transaction headers linking customer and handling employee.
-- Source: Orders.csv (300 records)
-- Relationships:
--   - customers (1) -> (M) orders
--   - employees (1) -> (M) orders
-- ============================================================================
CREATE TABLE orders (
    ord_id SMALLINT AUTO_INCREMENT PRIMARY KEY,
    cust_id SMALLINT NOT NULL,
    emp_id TINYINT NOT NULL,
    order_date VARCHAR(255) NOT NULL,
    CONSTRAINT fk_orders_customers
        FOREIGN KEY (cust_id) REFERENCES customers(cust_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_orders_employees
        FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- 7. Order_Details Table (Child of orders and products)
-- Stores itemized order line items, quantity, unit price, and extended subtotal.
-- Source: OrderDetails.csv (600 records)
-- Relationships:
--   - orders (1) -> (M) order_details
--   - products (1) -> (M) order_details
-- ============================================================================
CREATE TABLE order_details (
    ord_detID SMALLINT AUTO_INCREMENT PRIMARY KEY,
    ord_id SMALLINT NOT NULL,
    prod_id TINYINT NOT NULL,
    quantity TINYINT NOT NULL,
    each_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    CONSTRAINT chk_quantity CHECK (quantity > 0),
    CONSTRAINT chk_each_price CHECK (each_price >= 0),
    CONSTRAINT chk_total_price CHECK (total_price >= 0),
    CONSTRAINT fk_order_details_orders
        FOREIGN KEY (ord_id) REFERENCES orders(ord_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_order_details_products
        FOREIGN KEY (prod_id) REFERENCES products(prod_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- Schema Verification Query
-- ----------------------------------------------------------------------------
SELECT 
    TABLE_NAME, 
    ENGINE, 
    TABLE_ROWS, 
    TABLE_COLLATION 
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'grocery_store'
ORDER BY TABLE_NAME;


-- ============================================================================
-- PART: 03_import_data.sql
-- ============================================================================
-- ============================================================================
-- Project: Grocery Store Management SQL Database
-- File: 03_import_data.sql
-- Description: Turnkey data population script importing all 7 CSV datasets
-- Author: Mahaboob Subhani Shaik
-- Target DBMS: MySQL 8.x
-- ============================================================================

USE grocery_store;

/*
================================================================================
DATA IMPORT SPECIFICATION & REPRODUCIBILITY GUIDE
================================================================================
This script provides two fully documented, reliable import strategies:

METHOD 1: BULK LOAD DATA LOCAL INFILE (High Performance)
To execute bulk CSV loading directly from local files:
1. Enable local_infile on your MySQL Server (run once as root):
      SET GLOBAL local_infile = 1;
2. Launch MySQL CLI with the --local-infile flag enabled:
      mysql -u root -p --local-infile=1 grocery_store
3. Execute the LOAD DATA commands documented in Section A below, ensuring file
   paths use forward slashes (e.g., 'C:/path/to/data/Suppliers.csv').

METHOD 2: DIRECT MULTI-ROW INSERT STATEMENTS (Turnkey & Universal)
Section B provides complete, deterministic multi-row INSERT statements for all
1,170 records across all 7 tables in strict foreign-key dependency order.
This guarantees 100% reproducibility in any MySQL environment, IDE, or CLI
without requiring server-level file read privileges or OS path configuration.

DEPENDENCY ORDER:
  1. supplier       (Parent table - 5 rows)
  2. categories     (Parent table - 5 rows)
  3. employees      (Parent table - 10 rows)
  4. customers      (Parent table - 200 rows)
  5. products       (Child of supplier & categories - 50 rows)
  6. orders         (Child of customers & employees - 300 rows)
  7. order_details  (Child of orders & products - 600 rows)

PRIMARY KEY PRESERVATION:
  The validated source IDs are explicitly supplied in each INSERT/LOAD DATA
  statement. In MySQL InnoDB, explicit non-null values insert directly into
  AUTO_INCREMENT columns, preserving source keys and referential integrity.
================================================================================
*/

-- ============================================================================
-- SECTION A: LOAD DATA LOCAL INFILE TEMPLATES (REFERENCE / ADVANCED SETUP)
-- ============================================================================
/*
-- Run 'SET GLOBAL local_infile = 1;' prior to executing these statements:

LOAD DATA LOCAL INFILE 'C:/path/to/data/Suppliers.csv'
INTO TABLE supplier
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' IGNORE 1 LINES
(@SupplierID, @SupplierName, @Address)
SET sup_id = @SupplierID, sup_name = @SupplierName, address = @Address;

LOAD DATA LOCAL INFILE 'C:/path/to/data/Categories.csv'
INTO TABLE categories
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' IGNORE 1 LINES
(@CategoryID, @CategoryName)
SET cat_id = @CategoryID, cat_name = @CategoryName;

LOAD DATA LOCAL INFILE 'C:/path/to/data/Store_Employees.csv'
INTO TABLE employees
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' IGNORE 1 LINES
(@EmployeeID, @Name, @HireDate)
SET emp_id = @EmployeeID, emp_name = @Name, hire_date = @HireDate;

LOAD DATA LOCAL INFILE 'C:/path/to/data/Customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' IGNORE 1 LINES
(@CustomerID, @Name, @Address)
SET cust_id = @CustomerID, cust_name = @Name, address = @Address;

LOAD DATA LOCAL INFILE 'C:/path/to/data/Products.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' IGNORE 1 LINES
(@ProductID, @Name, @SupplierID, @CategoryID, @Price)
SET prod_id = @ProductID, prod_name = @Name, sup_id = @SupplierID, cat_id = @CategoryID, price = @Price;

LOAD DATA LOCAL INFILE 'C:/path/to/data/Orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' IGNORE 1 LINES
(@OrderID, @CustomerID, @EmployeeID, @OrderDate)
SET ord_id = @OrderID, cust_id = @CustomerID, emp_id = @EmployeeID, order_date = @OrderDate;

LOAD DATA LOCAL INFILE 'C:/path/to/data/OrderDetails.csv'
INTO TABLE order_details
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' IGNORE 1 LINES
(@OrderDetailID, @OrderID, @ProductID, @Quantity, @PriceEach, @TotalPrice)
SET ord_detID = @OrderDetailID, ord_id = @OrderID, prod_id = @ProductID, quantity = @Quantity, each_price = @PriceEach, total_price = @TotalPrice;
*/

-- ============================================================================
-- SECTION B: PRODUCTION TURNKEY MULTI-ROW INSERT STATEMENTS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Loading table: supplier (Source: Suppliers.csv, 5 rows)
-- Explicit Mapping: SupplierID -> sup_id, SupplierName -> sup_name, Address -> address
-- ----------------------------------------------------------------------------
INSERT INTO supplier (sup_id, sup_name, address) VALUES
(1, 'Aarav Sharma', '33 Main Street, Madhya Pradesh, India'),
(2, 'Sai ', '108 Main Street, Telangana, India'),
(3, 'Aarya', '166 Main Street, Uttar Pradesh, India'),
(4, 'Suresh', '163 Main Street, Andhra Pradesh, India'),
(5, 'Karthik', '182 Main Street, West Bengal, India');

-- ----------------------------------------------------------------------------
-- 2. Loading table: categories (Source: Categories.csv, 5 rows)
-- Explicit Mapping: CategoryID -> cat_id, CategoryName -> cat_name
-- ----------------------------------------------------------------------------
INSERT INTO categories (cat_id, cat_name) VALUES
(1, 'Grains & Cereals'),
(2, 'Dairy Products'),
(3, 'Snacks & Confectioneries'),
(4, 'Personal Care'),
(5, 'Household');

-- ----------------------------------------------------------------------------
-- 3. Loading table: employees (Source: Store_Employees.csv, 10 rows)
-- Explicit Mapping: EmployeeID -> emp_id, Name -> emp_name, HireDate -> hire_date
-- ----------------------------------------------------------------------------
INSERT INTO employees (emp_id, emp_name, hire_date) VALUES
(1, 'Aarav Kumar 1', '2/3/2021'),
(2, 'Aditya Singh 1', '1/8/2021'),
(3, 'Pari Kumar 1', '11/12/2021'),
(4, 'Aditya Verma 1', '1/9/2021'),
(5, 'Pari Sharma 1', '2/9/2021'),
(6, 'Zara Verma 1', '10/16/2021'),
(7, 'Vihaan Singh 1', '8/26/2020'),
(8, 'Diya Sharma 1', '8/21/2021'),
(9, 'Arjun Kumar 1', '5/29/2021'),
(10, 'Arjun Verma 1', '4/14/2021');

-- ----------------------------------------------------------------------------
-- 4. Loading table: customers (Source: Customers.csv, 200 rows)
-- Explicit Mapping: CustomerID -> cust_id, Name -> cust_name, Address -> address
-- ----------------------------------------------------------------------------
INSERT INTO customers (cust_id, cust_name, address) VALUES
(1, 'Aditi Shetty', '37 Main Street, Bengaluru, India'),
(2, 'Isha Reddy', '27 Main Street, Hyderabad, India'),
(3, 'Chetan Rao', '168 Main Street, Hyderabad, India'),
(4, 'Deepa Reddy', '102 Main Street, Hyderabad, India'),
(5, 'Isha Rao', '135 Main Street, Hyderabad, India'),
(6, 'Eshwar Reddy', '140 Main Street, Bengaluru, India'),
(7, 'Eshwar Iyer', '156 Main Street, Hyderabad, India'),
(8, 'Deepa Reddy', '181 Main Street, Hyderabad, India'),
(9, 'Isha Rao', '169 Main Street, Bengaluru, India'),
(10, 'Deepa Menon', '69 Main Street, Bengaluru, India'),
(11, 'Hari Menon', '62 Main Street, Hyderabad, India'),
(12, 'Kiran Gowda', '80 Main Street, Hyderabad, India'),
(13, 'Bala Krishnan', '145 Main Street, Bengaluru, India'),
(14, 'Jaya Shetty', '165 Main Street, Hyderabad, India'),
(15, 'Aditi Gowda', '141 Main Street, Bengaluru, India'),
(16, 'Gita Naidu', '128 Main Street, Hyderabad, India'),
(17, 'Kiran Pillai', '174 Main Street, Bengaluru, India'),
(18, 'Jaya Rao', '24 Main Street, Bengaluru, India'),
(19, 'Chetan Naidu', '102 Main Street, Bengaluru, India'),
(20, 'Kiran Rao', '131 Main Street, Bengaluru, India'),
(21, 'Bala Menon', '170 Main Street, Hyderabad, India'),
(22, 'Chetan Nair', '197 Main Street, Bengaluru, India'),
(23, 'Kiran Rao', '178 Main Street, Hyderabad, India'),
(24, 'Chetan Rao', '63 Main Street, Bengaluru, India'),
(25, 'Jaya Rao', '107 Main Street, Hyderabad, India'),
(26, 'Deepa Reddy', '111 Main Street, Hyderabad, India'),
(27, 'Chetan Gowda', '59 Main Street, Bengaluru, India'),
(28, 'Chetan Iyer', '30 Main Street, Bengaluru, India'),
(29, 'Kiran Krishnan', '180 Main Street, Bengaluru, India'),
(30, 'Gita Reddy', '103 Main Street, Bengaluru, India'),
(31, 'Hari Rao', '46 Main Street, Hyderabad, India'),
(32, 'Eshwar Menon', '190 Main Street, Bengaluru, India'),
(33, 'Hari Rao', '68 Main Street, Bengaluru, India'),
(34, 'Chetan Menon', '72 Main Street, Bengaluru, India'),
(35, 'Bala Gowda', '144 Main Street, Bengaluru, India'),
(36, 'Chetan Shetty', '76 Main Street, Bengaluru, India'),
(37, 'Kiran Reddy', '140 Main Street, Hyderabad, India'),
(38, 'Kiran Gowda', '138 Main Street, Bengaluru, India'),
(39, 'Jaya Krishnan', '158 Main Street, Hyderabad, India'),
(40, 'Hari Reddy', '62 Main Street, Bengaluru, India'),
(41, 'Isha Naidu', '67 Main Street, Bengaluru, India'),
(42, 'Deepa Reddy', '27 Main Street, Hyderabad, India'),
(43, 'Jaya Menon', '134 Main Street, Bengaluru, India'),
(44, 'Chetan Shetty', '48 Main Street, Bengaluru, India'),
(45, 'Aditi Reddy', '159 Main Street, Hyderabad, India'),
(46, 'Chetan Naidu', '130 Main Street, Hyderabad, India'),
(47, 'Isha Nair', '68 Main Street, Hyderabad, India'),
(48, 'Chetan Iyer', '87 Main Street, Bengaluru, India'),
(49, 'Jaya Nair', '39 Main Street, Hyderabad, India'),
(50, 'Jaya Pillai', '186 Main Street, Hyderabad, India'),
(51, 'Kiran Iyer', '125 Main Street, Hyderabad, India'),
(52, 'Chetan Menon', '16 Main Street, Hyderabad, India'),
(53, 'Eshwar Iyer', '16 Main Street, Hyderabad, India'),
(54, 'Jaya Gowda', '74 Main Street, Hyderabad, India'),
(55, 'Gita Menon', '143 Main Street, Hyderabad, India'),
(56, 'Eshwar Rao', '3 Main Street, Bengaluru, India'),
(57, 'Jaya Iyer', '9 Main Street, Hyderabad, India'),
(58, 'Eshwar Shetty', '152 Main Street, Bengaluru, India'),
(59, 'Gita Shetty', '195 Main Street, Hyderabad, India'),
(60, 'Jaya Shetty', '92 Main Street, Hyderabad, India'),
(61, 'Aditi Rao', '25 Main Street, Hyderabad, India'),
(62, 'Deepa Menon', '60 Main Street, Bengaluru, India'),
(63, 'Bala Reddy', '115 Main Street, Hyderabad, India'),
(64, 'Chetan Naidu', '9 Main Street, Bengaluru, India'),
(65, 'Eshwar Nair', '89 Main Street, Bengaluru, India'),
(66, 'Isha Iyer', '181 Main Street, Hyderabad, India'),
(67, 'Eshwar Rao', '3 Main Street, Hyderabad, India'),
(68, 'Deepa Pillai', '189 Main Street, Bengaluru, India'),
(69, 'Aditi Menon', '138 Main Street, Bengaluru, India'),
(70, 'Eshwar Krishnan', '136 Main Street, Bengaluru, India'),
(71, 'Gita Naidu', '46 Main Street, Hyderabad, India'),
(72, 'Jaya Nair', '35 Main Street, Hyderabad, India'),
(73, 'Bala Shetty', '126 Main Street, Hyderabad, India'),
(74, 'Eshwar Pillai', '109 Main Street, Bengaluru, India'),
(75, 'Chetan Gowda', '104 Main Street, Hyderabad, India'),
(76, 'Aditi Gowda', '108 Main Street, Bengaluru, India'),
(77, 'Hari Reddy', '192 Main Street, Bengaluru, India'),
(78, 'Isha Krishnan', '87 Main Street, Bengaluru, India'),
(79, 'Bala Reddy', '102 Main Street, Hyderabad, India'),
(80, 'Gita Reddy', '99 Main Street, Hyderabad, India'),
(81, 'Eshwar Naidu', '1 Main Street, Hyderabad, India'),
(82, 'Jaya Menon', '32 Main Street, Hyderabad, India'),
(83, 'Kiran Nair', '5 Main Street, Hyderabad, India'),
(84, 'Chetan Naidu', '123 Main Street, Hyderabad, India'),
(85, 'Chetan Iyer', '107 Main Street, Hyderabad, India'),
(86, 'Isha Reddy', '171 Main Street, Hyderabad, India'),
(87, 'Deepa Krishnan', '26 Main Street, Hyderabad, India'),
(88, 'Eshwar Shetty', '49 Main Street, Hyderabad, India'),
(89, 'Gita Gowda', '138 Main Street, Hyderabad, India'),
(90, 'Bala Rao', '27 Main Street, Bengaluru, India'),
(91, 'Isha Nair', '64 Main Street, Bengaluru, India'),
(92, 'Isha Reddy', '176 Main Street, Hyderabad, India'),
(93, 'Bala Menon', '171 Main Street, Hyderabad, India'),
(94, 'Gita Menon', '95 Main Street, Hyderabad, India'),
(95, 'Eshwar Krishnan', '180 Main Street, Hyderabad, India'),
(96, 'Bala Menon', '161 Main Street, Hyderabad, India'),
(97, 'Hari Gowda', '109 Main Street, Hyderabad, India'),
(98, 'Kiran Krishnan', '163 Main Street, Bengaluru, India'),
(99, 'Aditi Nair', '102 Main Street, Hyderabad, India'),
(100, 'Jaya Iyer', '47 Main Street, Hyderabad, India'),
(101, 'Jaya Menon', '86 Main Street, Hyderabad, India'),
(102, 'Isha Shetty', '80 Main Street, Hyderabad, India'),
(103, 'Hari Rao', '167 Main Street, Hyderabad, India'),
(104, 'Deepa Nair', '73 Main Street, Hyderabad, India'),
(105, 'Isha Iyer', '21 Main Street, Hyderabad, India'),
(106, 'Gita Menon', '35 Main Street, Hyderabad, India'),
(107, 'Eshwar Rao', '53 Main Street, Hyderabad, India'),
(108, 'Aditi Nair', '81 Main Street, Hyderabad, India'),
(109, 'Chetan Pillai', '159 Main Street, Bengaluru, India'),
(110, 'Hari Menon', '193 Main Street, Bengaluru, India'),
(111, 'Aditi Shetty', '148 Main Street, Bengaluru, India'),
(112, 'Eshwar Krishnan', '35 Main Street, Bengaluru, India'),
(113, 'Chetan Nair', '7 Main Street, Hyderabad, India'),
(114, 'Isha Shetty', '105 Main Street, Hyderabad, India'),
(115, 'Bala Naidu', '157 Main Street, Bengaluru, India'),
(116, 'Jaya Reddy', '97 Main Street, Hyderabad, India'),
(117, 'Eshwar Krishnan', '187 Main Street, Hyderabad, India'),
(118, 'Kiran Krishnan', '76 Main Street, Bengaluru, India'),
(119, 'Chetan Nair', '40 Main Street, Bengaluru, India'),
(120, 'Kiran Iyer', '155 Main Street, Hyderabad, India'),
(121, 'Bala Naidu', '156 Main Street, Bengaluru, India'),
(122, 'Chetan Reddy', '135 Main Street, Bengaluru, India'),
(123, 'Deepa Krishnan', '133 Main Street, Bengaluru, India'),
(124, 'Jaya Nair', '102 Main Street, Hyderabad, India'),
(125, 'Gita Nair', '48 Main Street, Hyderabad, India'),
(126, 'Bala Pillai', '156 Main Street, Bengaluru, India'),
(127, 'Hari Nair', '150 Main Street, Bengaluru, India'),
(128, 'Hari Naidu', '25 Main Street, Bengaluru, India'),
(129, 'Kiran Pillai', '191 Main Street, Bengaluru, India'),
(130, 'Eshwar Shetty', '166 Main Street, Bengaluru, India'),
(131, 'Chetan Reddy', '185 Main Street, Hyderabad, India'),
(132, 'Eshwar Gowda', '87 Main Street, Bengaluru, India'),
(133, 'Isha Menon', '69 Main Street, Bengaluru, India'),
(134, 'Deepa Iyer', '104 Main Street, Bengaluru, India'),
(135, 'Kiran Naidu', '29 Main Street, Hyderabad, India'),
(136, 'Jaya Rao', '148 Main Street, Bengaluru, India'),
(137, 'Aditi Rao', '152 Main Street, Hyderabad, India'),
(138, 'Eshwar Shetty', '66 Main Street, Bengaluru, India'),
(139, 'Deepa Krishnan', '4 Main Street, Bengaluru, India'),
(140, 'Jaya Nair', '106 Main Street, Bengaluru, India'),
(141, 'Hari Nair', '117 Main Street, Hyderabad, India'),
(142, 'Bala Nair', '131 Main Street, Hyderabad, India'),
(143, 'Isha Rao', '164 Main Street, Hyderabad, India'),
(144, 'Kiran Reddy', '194 Main Street, Bengaluru, India'),
(145, 'Chetan Rao', '38 Main Street, Hyderabad, India'),
(146, 'Deepa Naidu', '120 Main Street, Hyderabad, India'),
(147, 'Kiran Iyer', '14 Main Street, Hyderabad, India'),
(148, 'Chetan Iyer', '196 Main Street, Hyderabad, India'),
(149, 'Bala Naidu', '21 Main Street, Bengaluru, India'),
(150, 'Gita Menon', '149 Main Street, Hyderabad, India'),
(151, 'Bala Iyer', '58 Main Street, Hyderabad, India'),
(152, 'Gita Rao', '194 Main Street, Hyderabad, India'),
(153, 'Hari Shetty', '59 Main Street, Hyderabad, India'),
(154, 'Deepa Iyer', '87 Main Street, Hyderabad, India'),
(155, 'Deepa Shetty', '76 Main Street, Bengaluru, India'),
(156, 'Deepa Rao', '74 Main Street, Hyderabad, India'),
(157, 'Deepa Gowda', '80 Main Street, Hyderabad, India'),
(158, 'Eshwar Menon', '190 Main Street, Bengaluru, India'),
(159, 'Aditi Menon', '22 Main Street, Hyderabad, India'),
(160, 'Hari Naidu', '131 Main Street, Hyderabad, India'),
(161, 'Jivathran', '142 Main Street, Madhya Pradesh, India'),
(162, 'Damini', '155 Main Street, Bihar, India'),
(163, 'Esha', '7 Main Street, Uttar Pradesh, India'),
(164, 'Gopi', '159 Main Street, West Bengal, India'),
(165, 'Jyotika', '196 Main Street, Uttar Pradesh, India'),
(166, 'Kapila ', '123 Main Street, West Bengal, India'),
(167, 'Karishma', '53 Main Street, Maharashtra, India'),
(168, 'Kasturi', '15 Main Street, Maharashtra, India'),
(169, 'Kavita', '187 Main Street, Bihar, India'),
(170, 'Khushbu', '3 Main Street, West Bengal, India'),
(171, 'Kiran', '159 Main Street, Bihar, India'),
(172, 'Kirti', '10 Main Street, Bihar, India'),
(173, 'Kiran Banerjee', '166 Main Street, Maharashtra, India'),
(174, 'Komal', '51 Main Street, Uttar Pradesh, India'),
(175, 'Krishna', '119 Main Street, West Bengal, India'),
(176, 'Kusum', '199 Main Street, Madhya Pradesh, India'),
(177, 'Kiran Banerjee', '103 Main Street, Maharashtra, India'),
(178, 'Neela', '39 Main Street, Bihar, India'),
(179, 'Neha', '120 Main Street, Uttar Pradesh, India'),
(180, 'Nehal', '156 Main Street, Bihar, India'),
(181, 'Nidhi', '134 Main Street, Madhya Pradesh, India'),
(182, 'Nikita', '101 Main Street, West Bengal, India'),
(183, 'Pranav Mohan', '24 Main Street, Bihar, India'),
(184, 'Meena Varma', '186 Main Street, Madhya Pradesh, India'),
(185, 'Girish Gupta', '52 Main Street, Maharashtra, India'),
(186, 'Neha Joshi', '95 Main Street, West Bengal, India'),
(187, 'Arun Kapoor', '195 Main Street, Uttar Pradesh, India'),
(188, 'Preeti Malhotra', '187 Main Street, Madhya Pradesh, India'),
(189, 'Sunil Pillai', '79 Main Street, Uttar Pradesh, India'),
(190, 'Asha Shetty', '51 Main Street, Bihar, India'),
(191, 'Ravi Chopra', '20 Main Street, West Bengal, India'),
(192, 'Anjali Bose', '137 Main Street, Uttar Pradesh, India'),
(193, 'Suresh Kulkarni', '178 Main Street, Maharashtra, India'),
(194, 'Bindu Mehta', '115 Main Street, West Bengal, India'),
(195, 'Amit Saxena', '53 Main Street, Madhya Pradesh, India'),
(196, 'Divya Desai', '115 Main Street, Maharashtra, India'),
(197, 'Kiran Banerjee', '181 Main Street, Maharashtra, India'),
(198, 'Latha Ghosh', '162 Main Street, Maharashtra, India'),
(199, 'Prasad Rangan', '27 Main Street, Bihar, India'),
(200, 'Shilpa Nayak', '120 Main Street, Bihar, India');

-- ----------------------------------------------------------------------------
-- 5. Loading table: products (Source: Products.csv, 50 rows)
-- Explicit Mapping: ProductID -> prod_id, Name -> prod_name, SupplierID -> sup_id, CategoryID -> cat_id, Price -> price
-- ----------------------------------------------------------------------------
INSERT INTO products (prod_id, prod_name, sup_id, cat_id, price) VALUES
(1, 'Basmati Rice', 3, 1, 358.9846517),
(2, 'Wheat Flour', 2, 1, 255.4992244),
(3, 'Moong Dal', 4, 1, 386.1764812),
(4, 'Chickpeas', 5, 1, 353.5039826),
(5, 'Soybean Oil', 3, 1, 172.8076988),
(6, 'Ghee', 3, 1, 487.4551341),
(7, 'Paneer', 2, 2, 484.2676791),
(8, 'Yogurt', 2, 2, 111.6145026),
(9, 'Mango Pickle', 5, 1, 182.5024562),
(10, 'Mixed Vegetable Pickle', 3, 1, 133.5093716),
(11, 'Almonds', 5, 3, 315.5712554),
(12, 'Cashews', 4, 3, 441.9512343),
(13, 'Green Tea', 2, 3, 166.2641704),
(14, 'Masala Tea', 3, 3, 380.8527447),
(15, 'Coffee Powder', 1, 1, 179.5504607),
(16, 'Sugar', 4, 1, 409.6170697),
(17, 'Jaggery', 1, 3, 200.8510914),
(18, 'Salt', 5, 1, 219.3627841),
(19, 'Turmeric Powder', 3, 1, 456.0074145),
(20, 'Red Chili Powder', 3, 1, 218.7660536),
(21, 'Cumin Seeds', 4, 3, 182.7412995),
(22, 'Mustard Seeds', 1, 3, 433.7040398),
(23, 'Black Pepper', 3, 1, 140.6243556),
(24, 'Cardamom', 3, 1, 344.9015017),
(25, 'Cinnamon Sticks', 2, 1, 224.5675782),
(26, 'Detergent Powder', 5, 5, 464.0220163),
(27, 'Dishwashing Soap', 5, 5, 146.6451513),
(28, 'Toilet Cleaner', 2, 5, 479.3408898),
(29, 'Shampoo', 4, 4, 361.8849759),
(30, 'Conditioner', 2, 4, 476.0805682),
(31, 'Toothpaste', 3, 4, 447.4753435),
(32, 'Bath Soap', 3, 4, 235.2164086),
(33, 'Hand Sanitizer', 3, 4, 496.2095989),
(34, 'Facial Tissue', 3, 4, 173.0823943),
(35, 'Mouth wash', 2, 2, 454.2854953),
(36, 'Chapati', 4, 3, 201.683993),
(37, 'White Bread', 3, 3, 436.2154886),
(38, 'Brown Bread', 3, 3, 346.1443086),
(39, 'Eggs', 3, 3, 89.87249352),
(40, 'Butter', 2, 2, 452.4008463),
(41, 'Cheese Slices', 3, 2, 440.9431243),
(42, 'Tomato Ketchup', 2, 3, 322.3976772),
(43, 'Mayonnaise', 5, 2, 258.1505177),
(44, 'Soya Sauce', 5, 1, 499.5698141),
(45, 'Chili Sauce', 5, 1, 154.7126846),
(46, 'Potato Chips', 4, 3, 169.9324815),
(47, 'Chocolate Bar', 4, 3, 407.9476684),
(48, 'Biscuits', 3, 3, 388.8132485),
(49, 'Instant Noodles', 4, 3, 89.5184864),
(50, 'Pasta', 4, 3, 166.7262278);

-- ----------------------------------------------------------------------------
-- 6. Loading table: orders (Source: Orders.csv, 300 rows)
-- Explicit Mapping: OrderID -> ord_id, CustomerID -> cust_id, EmployeeID -> emp_id, OrderDate -> order_date
-- ----------------------------------------------------------------------------
INSERT INTO orders (ord_id, cust_id, emp_id, order_date) VALUES
(1, 197, 5, '1/30/2022'),
(2, 94, 6, '7/2/2022'),
(3, 97, 3, '11/25/2022'),
(4, 128, 2, '5/4/2022'),
(5, 61, 8, '3/5/2022'),
(6, 135, 5, '8/17/2022'),
(7, 166, 5, '4/22/2022'),
(8, 91, 8, '3/3/2022'),
(9, 195, 8, '10/31/2022'),
(10, 115, 8, '11/30/2022'),
(11, 71, 5, '6/18/2022'),
(12, 26, 1, '8/10/2022'),
(13, 1, 7, '8/2/2022'),
(14, 116, 4, '7/14/2022'),
(15, 23, 8, '7/22/2022'),
(16, 110, 9, '12/20/2022'),
(17, 165, 8, '3/21/2022'),
(18, 160, 5, '1/14/2022'),
(19, 57, 9, '4/23/2022'),
(20, 33, 2, '2/28/2022'),
(21, 171, 10, '5/28/2022'),
(22, 113, 8, '8/27/2022'),
(23, 26, 1, '5/26/2022'),
(24, 3, 3, '1/18/2022'),
(25, 68, 8, '10/23/2022'),
(26, 88, 10, '1/30/2022'),
(27, 22, 8, '12/5/2022'),
(28, 8, 3, '3/13/2022'),
(29, 144, 8, '4/1/2022'),
(30, 106, 5, '8/3/2022'),
(31, 61, 6, '12/13/2022'),
(32, 32, 4, '7/6/2022'),
(33, 100, 4, '5/24/2022'),
(34, 13, 10, '1/16/2022'),
(35, 51, 4, '9/21/2022'),
(36, 141, 10, '6/27/2022'),
(37, 147, 8, '11/6/2022'),
(38, 51, 10, '1/14/2022'),
(39, 180, 9, '3/24/2022'),
(40, 181, 9, '2/12/2022'),
(41, 56, 6, '8/8/2022'),
(42, 152, 3, '5/4/2022'),
(43, 165, 5, '3/24/2022'),
(44, 67, 9, '1/12/2022'),
(45, 56, 2, '11/14/2022'),
(46, 114, 3, '9/10/2022'),
(47, 165, 6, '6/10/2022'),
(48, 39, 5, '3/21/2022'),
(49, 110, 6, '11/25/2022'),
(50, 186, 8, '5/20/2022'),
(51, 146, 2, '5/24/2022'),
(52, 7, 9, '12/21/2022'),
(53, 72, 1, '2/10/2022'),
(54, 31, 4, '4/27/2022'),
(55, 181, 6, '1/28/2022'),
(56, 65, 8, '12/7/2022'),
(57, 124, 2, '11/20/2022'),
(58, 145, 9, '9/28/2022'),
(59, 195, 9, '10/10/2022'),
(60, 154, 7, '7/1/2022'),
(61, 138, 8, '2/9/2022'),
(62, 195, 1, '1/11/2022'),
(63, 148, 2, '12/6/2022'),
(64, 14, 6, '8/6/2022'),
(65, 164, 2, '3/22/2022'),
(66, 175, 7, '7/5/2022'),
(67, 67, 6, '5/10/2022'),
(68, 166, 9, '10/19/2022'),
(69, 84, 6, '3/18/2022'),
(70, 28, 9, '11/11/2022'),
(71, 84, 7, '11/9/2022'),
(72, 130, 1, '7/29/2022'),
(73, 116, 2, '11/8/2022'),
(74, 27, 8, '5/19/2022'),
(75, 145, 8, '2/17/2022'),
(76, 124, 3, '9/25/2022'),
(77, 55, 2, '8/1/2022'),
(78, 19, 6, '9/23/2022'),
(79, 21, 4, '5/29/2022'),
(80, 143, 10, '1/28/2022'),
(81, 138, 9, '1/8/2022'),
(82, 27, 2, '1/15/2022'),
(83, 189, 9, '8/20/2022'),
(84, 167, 3, '1/7/2022'),
(85, 61, 5, '3/25/2022'),
(86, 148, 2, '9/16/2022'),
(87, 168, 8, '10/24/2022'),
(88, 46, 8, '12/22/2022'),
(89, 161, 4, '11/12/2022'),
(90, 75, 2, '2/25/2022'),
(91, 92, 5, '3/30/2022'),
(92, 19, 2, '1/16/2022'),
(93, 114, 3, '2/21/2022'),
(94, 177, 7, '3/19/2022'),
(95, 52, 10, '8/5/2022'),
(96, 105, 2, '4/14/2022'),
(97, 61, 8, '4/18/2022'),
(98, 16, 7, '1/27/2022'),
(99, 73, 9, '12/2/2022'),
(100, 86, 3, '2/22/2022'),
(101, 142, 5, '9/22/2022'),
(102, 39, 5, '12/25/2022'),
(103, 94, 1, '3/3/2022'),
(104, 188, 2, '2/10/2022'),
(105, 15, 3, '3/4/2022'),
(106, 4, 8, '1/14/2022'),
(107, 46, 10, '12/23/2022'),
(108, 120, 2, '12/14/2022'),
(109, 158, 7, '4/28/2022'),
(110, 19, 7, '8/4/2022'),
(111, 186, 6, '3/27/2022'),
(112, 200, 7, '3/30/2022'),
(113, 125, 4, '3/22/2022'),
(114, 150, 10, '1/24/2022'),
(115, 187, 6, '3/23/2022'),
(116, 120, 10, '9/16/2022'),
(117, 139, 3, '1/17/2022'),
(118, 133, 7, '1/30/2022'),
(119, 182, 1, '2/2/2022'),
(120, 60, 9, '5/12/2022'),
(121, 135, 7, '9/10/2022'),
(122, 173, 10, '8/1/2022'),
(123, 100, 9, '11/2/2022'),
(124, 185, 2, '9/12/2022'),
(125, 51, 5, '5/18/2022'),
(126, 32, 4, '9/19/2022'),
(127, 112, 9, '5/9/2022'),
(128, 63, 5, '7/9/2022'),
(129, 120, 5, '12/19/2022'),
(130, 61, 10, '4/13/2022'),
(131, 27, 5, '5/13/2022'),
(132, 113, 6, '10/20/2022'),
(133, 90, 7, '5/2/2022'),
(134, 101, 5, '3/12/2022'),
(135, 121, 2, '8/28/2022'),
(136, 73, 6, '1/11/2022'),
(137, 80, 1, '12/12/2022'),
(138, 148, 2, '3/17/2022'),
(139, 159, 3, '2/26/2022'),
(140, 137, 6, '5/13/2022'),
(141, 182, 6, '8/15/2022'),
(142, 16, 2, '5/24/2022'),
(143, 105, 2, '7/27/2022'),
(144, 129, 9, '9/1/2022'),
(145, 155, 2, '7/2/2022'),
(146, 8, 1, '1/23/2022'),
(147, 73, 6, '12/21/2022'),
(148, 169, 4, '3/10/2022'),
(149, 31, 8, '12/29/2022'),
(150, 130, 3, '9/18/2022'),
(151, 85, 2, '1/6/2022'),
(152, 35, 3, '10/10/2022'),
(153, 77, 8, '4/22/2022'),
(154, 136, 2, '7/30/2022'),
(155, 38, 1, '12/28/2022'),
(156, 36, 4, '11/22/2022'),
(157, 151, 8, '6/27/2022'),
(158, 102, 6, '9/25/2022'),
(159, 55, 9, '12/9/2022'),
(160, 86, 5, '12/14/2022'),
(161, 32, 5, '9/10/2022'),
(162, 188, 7, '8/31/2022'),
(163, 196, 3, '1/7/2022'),
(164, 167, 5, '3/2/2022'),
(165, 146, 2, '10/2/2022'),
(166, 93, 2, '3/18/2022'),
(167, 124, 8, '7/10/2022'),
(168, 121, 7, '2/27/2022'),
(169, 106, 5, '2/23/2022'),
(170, 177, 3, '9/20/2022'),
(171, 32, 7, '5/8/2022'),
(172, 59, 1, '3/10/2022'),
(173, 145, 6, '6/8/2022'),
(174, 125, 10, '6/4/2022'),
(175, 82, 5, '9/2/2022'),
(176, 2, 4, '2/13/2022'),
(177, 172, 3, '10/14/2022'),
(178, 92, 2, '10/23/2022'),
(179, 149, 5, '4/22/2022'),
(180, 39, 2, '12/3/2022'),
(181, 165, 2, '6/8/2022'),
(182, 5, 10, '12/28/2022'),
(183, 157, 5, '8/10/2022'),
(184, 165, 8, '6/15/2022'),
(185, 67, 2, '2/26/2022'),
(186, 167, 6, '11/18/2022'),
(187, 7, 10, '1/24/2022'),
(188, 102, 1, '10/25/2022'),
(189, 75, 3, '7/12/2022'),
(190, 178, 3, '6/2/2022'),
(191, 165, 4, '6/5/2022'),
(192, 163, 1, '2/6/2022'),
(193, 26, 10, '7/24/2022'),
(194, 38, 6, '4/30/2022'),
(195, 170, 6, '7/8/2022'),
(196, 191, 2, '2/24/2022'),
(197, 46, 4, '9/20/2022'),
(198, 7, 2, '2/1/2022'),
(199, 153, 10, '2/11/2022'),
(200, 80, 3, '11/24/2022'),
(201, 160, 4, '2/9/2022'),
(202, 112, 10, '11/4/2022'),
(203, 164, 5, '8/18/2022'),
(204, 58, 3, '1/16/2022'),
(205, 93, 8, '6/17/2022'),
(206, 71, 7, '8/6/2022'),
(207, 174, 10, '3/30/2022'),
(208, 185, 4, '11/27/2022'),
(209, 158, 5, '5/17/2022'),
(210, 144, 9, '9/7/2022'),
(211, 3, 3, '7/5/2022'),
(212, 19, 7, '2/27/2022'),
(213, 66, 8, '2/20/2022'),
(214, 8, 5, '7/29/2022'),
(215, 146, 10, '12/3/2022'),
(216, 3, 10, '2/3/2022'),
(217, 20, 7, '1/6/2022'),
(218, 83, 7, '5/21/2022'),
(219, 68, 5, '2/27/2022'),
(220, 70, 9, '2/13/2022'),
(221, 161, 9, '5/28/2022'),
(222, 145, 9, '12/29/2022'),
(223, 5, 1, '1/22/2022'),
(224, 122, 3, '7/30/2022'),
(225, 134, 7, '12/12/2022'),
(226, 151, 1, '12/6/2022'),
(227, 32, 7, '2/14/2022'),
(228, 31, 4, '9/28/2022'),
(229, 123, 9, '6/15/2022'),
(230, 38, 8, '3/11/2022'),
(231, 33, 3, '7/17/2022'),
(232, 113, 8, '2/13/2022'),
(233, 161, 6, '12/19/2022'),
(234, 56, 7, '9/11/2022'),
(235, 141, 8, '1/5/2022'),
(236, 18, 1, '1/25/2022'),
(237, 134, 1, '9/11/2022'),
(238, 166, 7, '1/5/2022'),
(239, 57, 6, '9/10/2022'),
(240, 3, 8, '11/14/2022'),
(241, 43, 9, '8/3/2022'),
(242, 104, 9, '10/19/2022'),
(243, 40, 3, '7/30/2022'),
(244, 193, 6, '3/30/2022'),
(245, 128, 2, '8/25/2022'),
(246, 143, 4, '1/31/2022'),
(247, 93, 7, '2/6/2022'),
(248, 192, 3, '12/6/2022'),
(249, 145, 5, '10/8/2022'),
(250, 17, 9, '12/23/2022'),
(251, 128, 6, '10/23/2022'),
(252, 70, 4, '2/24/2022'),
(253, 114, 6, '9/23/2022'),
(254, 118, 4, '4/24/2022'),
(255, 190, 7, '12/22/2022'),
(256, 168, 2, '3/1/2022'),
(257, 195, 5, '2/19/2022'),
(258, 199, 8, '5/27/2022'),
(259, 140, 9, '3/25/2022'),
(260, 160, 1, '5/6/2022'),
(261, 175, 6, '7/5/2022'),
(262, 142, 9, '1/1/2022'),
(263, 62, 2, '4/24/2022'),
(264, 37, 8, '2/8/2022'),
(265, 189, 4, '9/23/2022'),
(266, 169, 9, '9/25/2022'),
(267, 165, 8, '6/12/2022'),
(268, 103, 4, '11/18/2022'),
(269, 61, 3, '11/12/2022'),
(270, 10, 7, '6/18/2022'),
(271, 174, 3, '10/19/2022'),
(272, 28, 8, '4/7/2022'),
(273, 177, 1, '11/19/2022'),
(274, 190, 1, '8/18/2022'),
(275, 128, 1, '12/11/2022'),
(276, 47, 10, '12/30/2022'),
(277, 7, 4, '5/23/2022'),
(278, 120, 7, '6/4/2022'),
(279, 21, 10, '7/16/2022'),
(280, 19, 2, '8/25/2022'),
(281, 116, 7, '3/6/2022'),
(282, 74, 8, '11/22/2022'),
(283, 196, 3, '1/23/2022'),
(284, 76, 8, '8/28/2022'),
(285, 174, 1, '7/14/2022'),
(286, 185, 2, '6/29/2022'),
(287, 114, 5, '2/14/2022'),
(288, 195, 9, '4/28/2022'),
(289, 107, 4, '1/10/2022'),
(290, 152, 3, '7/16/2022'),
(291, 48, 7, '12/5/2022'),
(292, 128, 6, '1/28/2022'),
(293, 164, 9, '12/21/2022'),
(294, 192, 6, '10/5/2022'),
(295, 131, 1, '10/9/2022'),
(296, 33, 4, '12/11/2022'),
(297, 153, 9, '12/5/2022'),
(298, 187, 3, '11/30/2022'),
(299, 2, 8, '8/26/2022'),
(300, 166, 4, '6/27/2022');

-- ----------------------------------------------------------------------------
-- 7. Loading table: order_details (Source: OrderDetails.csv, 600 rows)
-- Explicit Mapping: OrderDetailID -> ord_detID, OrderID -> ord_id, ProductID -> prod_id, Quantity -> quantity, PriceEach -> each_price, TotalPrice -> total_price
-- ----------------------------------------------------------------------------
INSERT INTO order_details (ord_detID, ord_id, prod_id, quantity, each_price, total_price) VALUES
(1, 109, 23, 3, 140.6243555888351, 421.8730667665053),
(2, 144, 12, 1, 441.95123431386185, 441.95123431386185),
(3, 82, 13, 4, 166.26417041398335, 665.0566816559334),
(4, 224, 18, 2, 219.3627840930461, 438.7255681860922),
(5, 256, 3, 4, 386.1764811694529, 1544.7059246778117),
(6, 183, 27, 4, 146.64515129714397, 586.5806051885759),
(7, 174, 26, 3, 464.0220163156805, 1392.0660489470413),
(8, 164, 42, 1, 322.39767718952066, 322.39767718952066),
(9, 68, 21, 3, 182.7412994928937, 548.2238984786811),
(10, 129, 3, 1, 386.1764811694529, 386.1764811694529),
(11, 249, 32, 4, 235.21640863684704, 940.8656345473884),
(12, 36, 43, 3, 258.15051770338926, 774.4515531101678),
(13, 141, 15, 1, 179.55046069099683, 179.55046069099683),
(14, 192, 32, 3, 235.21640863684704, 705.6492259105412),
(15, 103, 43, 4, 258.15051770338926, 1032.602070813557),
(16, 2, 6, 4, 487.45513408319806, 1949.820536332792),
(17, 279, 36, 1, 201.6839929677742, 201.6839929677742),
(18, 232, 25, 4, 224.5675782233399, 898.2703128933596),
(19, 41, 26, 4, 464.0220163156805, 1856.0880652627216),
(20, 286, 48, 5, 388.8132485394478, 1944.066242697239),
(21, 54, 30, 1, 476.0805682102502, 476.0805682102502),
(22, 30, 28, 5, 479.3408898225919, 2396.7044491129595),
(23, 87, 2, 2, 255.49922444549492, 510.9984488909899),
(24, 144, 5, 3, 172.80769876843488, 518.4230963053046),
(25, 28, 25, 2, 224.5675782233399, 449.1351564466798),
(26, 243, 26, 4, 464.0220163156805, 1856.0880652627216),
(27, 58, 9, 4, 182.5024562282616, 730.0098249130463),
(28, 81, 28, 4, 479.3408898225919, 1917.363559290368),
(29, 35, 2, 1, 255.49922444549492, 255.49922444549492),
(30, 297, 24, 2, 344.9015016505583, 689.8030033011166),
(31, 108, 48, 4, 388.8132485394478, 1555.2529941577911),
(32, 154, 46, 5, 169.93248151532975, 849.6624075766488),
(33, 118, 7, 3, 484.26767905942313, 1452.8030371782693),
(34, 261, 48, 2, 388.8132485394478, 777.6264970788956),
(35, 187, 29, 3, 361.88497593070855, 1085.6549277921256),
(36, 162, 14, 2, 380.852744704009, 761.7054894080181),
(37, 230, 36, 5, 201.6839929677742, 1008.419964838871),
(38, 229, 41, 3, 440.94312434058753, 1322.8293730217626),
(39, 275, 35, 2, 454.2854952885772, 908.5709905771544),
(40, 264, 26, 3, 464.0220163156805, 1392.0660489470413),
(41, 204, 7, 4, 484.26767905942313, 1937.0707162376923),
(42, 206, 20, 3, 218.7660536306108, 656.2981608918324),
(43, 116, 27, 4, 146.64515129714397, 586.5806051885759),
(44, 184, 17, 3, 200.8510913678053, 602.5532741034159),
(45, 34, 32, 3, 235.21640863684704, 705.6492259105412),
(46, 101, 18, 4, 219.3627840930461, 877.4511363721845),
(47, 124, 48, 2, 388.8132485394478, 777.6264970788956),
(48, 60, 8, 2, 111.61450255218918, 223.2290051043784),
(49, 89, 33, 2, 496.2095988939715, 992.419197787943),
(50, 49, 41, 1, 440.94312434058753, 440.94312434058753),
(51, 186, 20, 1, 218.7660536306108, 218.7660536306108),
(52, 251, 18, 5, 219.3627840930461, 1096.8139204652307),
(53, 49, 46, 4, 169.93248151532975, 679.729926061319),
(54, 255, 16, 3, 409.6170697232217, 1228.8512091696653),
(55, 289, 10, 1, 133.509371642973, 133.509371642973),
(56, 186, 10, 2, 133.509371642973, 267.018743285946),
(57, 78, 33, 4, 496.2095988939715, 1984.838395575886),
(58, 149, 48, 4, 388.8132485394478, 1555.2529941577911),
(59, 260, 38, 5, 346.1443085743635, 1730.7215428718175),
(60, 73, 28, 3, 479.3408898225919, 1438.0226694677758),
(61, 179, 48, 5, 388.8132485394478, 1944.066242697239),
(62, 297, 15, 2, 179.55046069099683, 359.10092138199366),
(63, 274, 41, 2, 440.94312434058753, 881.8862486811751),
(64, 147, 36, 5, 201.6839929677742, 1008.419964838871),
(65, 285, 19, 5, 456.00741451885847, 2280.037072594292),
(66, 131, 11, 1, 315.57125543377435, 315.57125543377435),
(67, 220, 46, 1, 169.93248151532975, 169.93248151532975),
(68, 103, 39, 1, 89.8724935155258, 89.8724935155258),
(69, 204, 5, 3, 172.80769876843488, 518.4230963053046),
(70, 82, 26, 1, 464.0220163156805, 464.0220163156805),
(71, 138, 3, 5, 386.1764811694529, 1930.8824058472649),
(72, 277, 37, 1, 436.2154886334091, 436.2154886334091),
(73, 93, 22, 5, 433.70403983426496, 2168.5201991713247),
(74, 21, 2, 1, 255.49922444549492, 255.49922444549492),
(75, 198, 10, 2, 133.509371642973, 267.018743285946),
(76, 146, 38, 5, 346.1443085743635, 1730.7215428718175),
(77, 238, 12, 3, 441.95123431386185, 1325.8537029415857),
(78, 163, 33, 5, 496.2095988939715, 2481.0479944698573),
(79, 17, 20, 2, 218.7660536306108, 437.5321072612216),
(80, 24, 44, 1, 499.5698140705896, 499.5698140705896),
(81, 84, 15, 2, 179.55046069099683, 359.10092138199366),
(82, 203, 2, 5, 255.49922444549492, 1277.4961222274746),
(83, 238, 49, 3, 89.51848639672136, 268.5554591901641),
(84, 132, 4, 1, 353.50398257722065, 353.50398257722065),
(85, 261, 33, 4, 496.2095988939715, 1984.838395575886),
(86, 92, 43, 2, 258.15051770338926, 516.3010354067785),
(87, 218, 33, 4, 496.2095988939715, 1984.838395575886),
(88, 51, 13, 5, 166.26417041398335, 831.3208520699168),
(89, 41, 41, 2, 440.94312434058753, 881.8862486811751),
(90, 159, 3, 3, 386.1764811694529, 1158.5294435083588),
(91, 68, 30, 5, 476.0805682102502, 2380.402841051251),
(92, 251, 42, 3, 322.39767718952066, 967.193031568562),
(93, 216, 19, 2, 456.00741451885847, 912.0148290377168),
(94, 272, 28, 1, 479.3408898225919, 479.3408898225919),
(95, 65, 15, 3, 179.55046069099683, 538.6513820729905),
(96, 109, 12, 2, 441.95123431386185, 883.9024686277237),
(97, 2, 35, 3, 454.2854952885772, 1362.8564858657314),
(98, 80, 38, 1, 346.1443085743635, 346.1443085743635),
(99, 269, 40, 5, 452.4008463144313, 2262.004231572156),
(100, 169, 37, 2, 436.2154886334091, 872.4309772668182),
(101, 52, 49, 5, 89.51848639672136, 447.5924319836068),
(102, 44, 19, 2, 456.00741451885847, 912.0148290377168),
(103, 156, 33, 1, 496.2095988939715, 496.2095988939715),
(104, 124, 12, 3, 441.95123431386185, 1325.8537029415857),
(105, 129, 21, 3, 182.7412994928937, 548.2238984786811),
(106, 258, 34, 3, 173.08239429241354, 519.2471828772407),
(107, 5, 32, 3, 235.21640863684704, 705.6492259105412),
(108, 123, 45, 2, 154.7126846303358, 309.42536926067163),
(109, 194, 21, 3, 182.7412994928937, 548.2238984786811),
(110, 246, 27, 4, 146.64515129714397, 586.5806051885759),
(111, 60, 39, 1, 89.8724935155258, 89.8724935155258),
(112, 44, 32, 5, 235.21640863684704, 1176.082043184235),
(113, 102, 24, 2, 344.9015016505583, 689.8030033011166),
(114, 28, 36, 4, 201.6839929677742, 806.7359718710968),
(115, 92, 21, 2, 182.7412994928937, 365.4825989857874),
(116, 239, 8, 1, 111.61450255218918, 111.61450255218918),
(117, 62, 24, 3, 344.9015016505583, 1034.704504951675),
(118, 75, 47, 2, 407.9476683953336, 815.8953367906672),
(119, 119, 7, 1, 484.26767905942313, 484.26767905942313),
(120, 230, 17, 3, 200.8510913678053, 602.5532741034159),
(121, 67, 42, 4, 322.39767718952066, 1289.5907087580829),
(122, 179, 42, 5, 322.39767718952066, 1611.988385947603),
(123, 264, 32, 2, 235.21640863684704, 470.4328172736941),
(124, 140, 49, 3, 89.51848639672136, 268.5554591901641),
(125, 64, 48, 3, 388.8132485394478, 1166.4397456183433),
(126, 206, 46, 1, 169.93248151532975, 169.93248151532975),
(127, 181, 50, 4, 166.72622777692487, 666.9049111076995),
(128, 250, 8, 4, 111.61450255218918, 446.4580102087567),
(129, 5, 9, 4, 182.5024562282616, 730.0098249130463),
(130, 75, 2, 1, 255.49922444549492, 255.49922444549492),
(131, 4, 14, 1, 380.852744704009, 380.852744704009),
(132, 181, 28, 1, 479.3408898225919, 479.3408898225919),
(133, 226, 40, 4, 452.4008463144313, 1809.603385257725),
(134, 81, 41, 1, 440.94312434058753, 440.94312434058753),
(135, 224, 11, 4, 315.57125543377435, 1262.2850217350974),
(136, 169, 34, 5, 173.08239429241354, 865.4119714620676),
(137, 48, 27, 3, 146.64515129714397, 439.9354538914319),
(138, 105, 39, 5, 89.8724935155258, 449.362467577629),
(139, 190, 37, 2, 436.2154886334091, 872.4309772668182),
(140, 247, 27, 4, 146.64515129714397, 586.5806051885759),
(141, 127, 44, 3, 499.5698140705896, 1498.7094422117689),
(142, 200, 33, 5, 496.2095988939715, 2481.0479944698573),
(143, 246, 27, 2, 146.64515129714397, 293.29030259428794),
(144, 191, 38, 2, 346.1443085743635, 692.288617148727),
(145, 188, 47, 2, 407.9476683953336, 815.8953367906672),
(146, 248, 36, 5, 201.6839929677742, 1008.419964838871),
(147, 83, 23, 3, 140.6243555888351, 421.8730667665053),
(148, 139, 12, 3, 441.95123431386185, 1325.8537029415857),
(149, 201, 43, 2, 258.15051770338926, 516.3010354067785),
(150, 182, 3, 3, 386.1764811694529, 1158.5294435083588),
(151, 49, 44, 1, 499.5698140705896, 499.5698140705896),
(152, 128, 23, 1, 140.6243555888351, 140.6243555888351),
(153, 126, 34, 5, 173.08239429241354, 865.4119714620676),
(154, 6, 3, 4, 386.1764811694529, 1544.7059246778117),
(155, 45, 32, 3, 235.21640863684704, 705.6492259105412),
(156, 54, 39, 5, 89.8724935155258, 449.362467577629),
(157, 276, 23, 5, 140.6243555888351, 703.1217779441755),
(158, 26, 29, 2, 361.88497593070855, 723.7699518614171),
(159, 14, 7, 5, 484.26767905942313, 2421.338395297116),
(160, 190, 23, 1, 140.6243555888351, 140.6243555888351),
(161, 5, 43, 4, 258.15051770338926, 1032.602070813557),
(162, 285, 48, 3, 388.8132485394478, 1166.4397456183433),
(163, 101, 48, 4, 388.8132485394478, 1555.2529941577911),
(164, 253, 38, 5, 346.1443085743635, 1730.7215428718175),
(165, 192, 40, 4, 452.4008463144313, 1809.603385257725),
(166, 90, 28, 2, 479.3408898225919, 958.6817796451838),
(167, 262, 15, 3, 179.55046069099683, 538.6513820729905),
(168, 43, 21, 2, 182.7412994928937, 365.4825989857874),
(169, 146, 44, 2, 499.5698140705896, 999.1396281411792),
(170, 136, 23, 5, 140.6243555888351, 703.1217779441755),
(171, 300, 41, 4, 440.94312434058753, 1763.77249736235),
(172, 57, 29, 1, 361.88497593070855, 361.88497593070855),
(173, 145, 14, 4, 380.852744704009, 1523.4109788160365),
(174, 61, 4, 3, 353.50398257722065, 1060.511947731662),
(175, 93, 1, 2, 358.98465174820154, 717.9693034964031),
(176, 245, 25, 2, 224.5675782233399, 449.1351564466798),
(177, 86, 38, 5, 346.1443085743635, 1730.7215428718175),
(178, 218, 29, 2, 361.88497593070855, 723.7699518614171),
(179, 32, 32, 3, 235.21640863684704, 705.6492259105412),
(180, 165, 15, 1, 179.55046069099683, 179.55046069099683),
(181, 283, 49, 3, 89.51848639672136, 268.5554591901641),
(182, 280, 19, 1, 456.00741451885847, 456.00741451885847),
(183, 243, 2, 2, 255.49922444549492, 510.9984488909899),
(184, 7, 26, 4, 464.0220163156805, 1856.0880652627216),
(185, 291, 37, 4, 436.2154886334091, 1744.8619545336364),
(186, 37, 48, 3, 388.8132485394478, 1166.4397456183433),
(187, 54, 46, 2, 169.93248151532975, 339.8649630306595),
(188, 64, 2, 3, 255.49922444549492, 766.4976733364848),
(189, 265, 47, 4, 407.9476683953336, 1631.7906735813344),
(190, 195, 27, 3, 146.64515129714397, 439.9354538914319),
(191, 139, 38, 5, 346.1443085743635, 1730.7215428718175),
(192, 141, 41, 4, 440.94312434058753, 1763.77249736235),
(193, 251, 9, 1, 182.5024562282616, 182.5024562282616),
(194, 54, 13, 3, 166.26417041398335, 498.79251124195),
(195, 9, 41, 5, 440.94312434058753, 2204.715621702938),
(196, 104, 25, 5, 224.5675782233399, 1122.8378911166994),
(197, 121, 33, 5, 496.2095988939715, 2481.0479944698573),
(198, 228, 34, 3, 173.08239429241354, 519.2471828772407),
(199, 180, 35, 3, 454.2854952885772, 1362.8564858657314),
(200, 76, 23, 3, 140.6243555888351, 421.8730667665053),
(201, 195, 33, 3, 496.2095988939715, 1488.6287966819143),
(202, 101, 32, 3, 235.21640863684704, 705.6492259105412),
(203, 4, 15, 1, 179.55046069099683, 179.55046069099683),
(204, 239, 12, 1, 441.95123431386185, 441.95123431386185),
(205, 171, 16, 5, 409.6170697232217, 2048.0853486161086),
(206, 21, 44, 2, 499.5698140705896, 999.1396281411792),
(207, 20, 6, 5, 487.45513408319806, 2437.27567041599),
(208, 102, 49, 4, 89.51848639672136, 358.07394558688543),
(209, 197, 9, 1, 182.5024562282616, 182.5024562282616),
(210, 156, 33, 3, 496.2095988939715, 1488.6287966819143),
(211, 164, 20, 5, 218.7660536306108, 1093.830268153054),
(212, 60, 42, 5, 322.39767718952066, 1611.988385947603),
(213, 131, 21, 1, 182.7412994928937, 182.7412994928937),
(214, 260, 34, 3, 173.08239429241354, 519.2471828772407),
(215, 66, 5, 1, 172.80769876843488, 172.80769876843488),
(216, 21, 44, 3, 499.5698140705896, 1498.7094422117689),
(217, 67, 14, 5, 380.852744704009, 1904.2637235200452),
(218, 235, 43, 2, 258.15051770338926, 516.3010354067785),
(219, 168, 13, 3, 166.26417041398335, 498.79251124195),
(220, 187, 43, 3, 258.15051770338926, 774.4515531101678),
(221, 239, 47, 3, 407.9476683953336, 1223.843005186001),
(222, 267, 36, 2, 201.6839929677742, 403.3679859355484),
(223, 189, 8, 1, 111.61450255218918, 111.61450255218918),
(224, 38, 8, 2, 111.61450255218918, 223.2290051043784),
(225, 262, 34, 1, 173.08239429241354, 173.08239429241354),
(226, 90, 14, 4, 380.852744704009, 1523.4109788160365),
(227, 12, 17, 5, 200.8510913678053, 1004.2554568390266),
(228, 282, 31, 5, 447.4753434547104, 2237.3767172735515),
(229, 36, 43, 2, 258.15051770338926, 516.3010354067785),
(230, 231, 17, 2, 200.8510913678053, 401.7021827356106),
(231, 7, 32, 4, 235.21640863684704, 940.8656345473884),
(232, 44, 18, 3, 219.3627840930461, 658.0883522791383),
(233, 67, 28, 2, 479.3408898225919, 958.6817796451838),
(234, 91, 47, 4, 407.9476683953336, 1631.7906735813344),
(235, 127, 19, 1, 456.00741451885847, 456.00741451885847),
(236, 236, 32, 4, 235.21640863684704, 940.8656345473884),
(237, 17, 28, 1, 479.3408898225919, 479.3408898225919),
(238, 162, 38, 1, 346.1443085743635, 346.1443085743635),
(239, 88, 31, 5, 447.4753434547104, 2237.3767172735515),
(240, 297, 36, 5, 201.6839929677742, 1008.419964838871),
(241, 263, 15, 5, 179.55046069099683, 897.7523034549841),
(242, 70, 7, 3, 484.26767905942313, 1452.8030371782693),
(243, 174, 31, 4, 447.4753434547104, 1789.9013738188414),
(244, 148, 38, 1, 346.1443085743635, 346.1443085743635),
(245, 195, 48, 4, 388.8132485394478, 1555.2529941577911),
(246, 198, 20, 1, 218.7660536306108, 218.7660536306108),
(247, 144, 36, 3, 201.6839929677742, 605.0519789033226),
(248, 196, 9, 3, 182.5024562282616, 547.5073686847848),
(249, 44, 21, 1, 182.7412994928937, 182.7412994928937),
(250, 164, 46, 5, 169.93248151532975, 849.6624075766488),
(251, 55, 23, 1, 140.6243555888351, 140.6243555888351),
(252, 84, 13, 3, 166.26417041398335, 498.79251124195),
(253, 87, 40, 4, 452.4008463144313, 1809.603385257725),
(254, 84, 10, 2, 133.509371642973, 267.018743285946),
(255, 272, 39, 1, 89.8724935155258, 89.8724935155258),
(256, 56, 1, 4, 358.98465174820154, 1435.9386069928062),
(257, 195, 41, 5, 440.94312434058753, 2204.715621702938),
(258, 108, 47, 2, 407.9476683953336, 815.8953367906672),
(259, 73, 30, 2, 476.0805682102502, 952.1611364205004),
(260, 218, 30, 3, 476.0805682102502, 1428.2417046307503),
(261, 205, 13, 1, 166.26417041398335, 166.26417041398335),
(262, 78, 35, 2, 454.2854952885772, 908.5709905771544),
(263, 169, 24, 3, 344.9015016505583, 1034.704504951675),
(264, 50, 47, 4, 407.9476683953336, 1631.7906735813344),
(265, 121, 42, 4, 322.39767718952066, 1289.5907087580829),
(266, 158, 45, 3, 154.7126846303358, 464.1380538910074),
(267, 173, 6, 2, 487.45513408319806, 974.910268166396),
(268, 225, 7, 4, 484.26767905942313, 1937.0707162376923),
(269, 271, 49, 2, 89.51848639672136, 179.03697279344271),
(270, 22, 33, 2, 496.2095988939715, 992.419197787943),
(271, 235, 20, 5, 218.7660536306108, 1093.830268153054),
(272, 111, 41, 4, 440.94312434058753, 1763.77249736235),
(273, 276, 13, 5, 166.26417041398335, 831.3208520699168),
(274, 235, 40, 5, 452.4008463144313, 2262.004231572156),
(275, 168, 12, 5, 441.95123431386185, 2209.756171569309),
(276, 79, 49, 2, 89.51848639672136, 179.03697279344271),
(277, 50, 38, 4, 346.1443085743635, 1384.577234297454),
(278, 281, 34, 2, 173.08239429241354, 346.1647885848271),
(279, 288, 7, 4, 484.26767905942313, 1937.0707162376923),
(280, 200, 34, 5, 173.08239429241354, 865.4119714620676),
(281, 211, 31, 1, 447.4753434547104, 447.4753434547104),
(282, 26, 33, 4, 496.2095988939715, 1984.838395575886),
(283, 271, 2, 3, 255.49922444549492, 766.4976733364848),
(284, 300, 15, 3, 179.55046069099683, 538.6513820729905),
(285, 101, 5, 2, 172.80769876843488, 345.6153975368697),
(286, 203, 22, 1, 433.70403983426496, 433.70403983426496),
(287, 31, 1, 1, 358.98465174820154, 358.98465174820154),
(288, 119, 14, 3, 380.852744704009, 1142.558234112027),
(289, 213, 6, 5, 487.45513408319806, 2437.27567041599),
(290, 229, 44, 4, 499.5698140705896, 1998.2792562823583),
(291, 190, 4, 1, 353.50398257722065, 353.50398257722065),
(292, 109, 31, 1, 447.4753434547104, 447.4753434547104),
(293, 53, 48, 3, 388.8132485394478, 1166.4397456183433),
(294, 10, 18, 3, 219.3627840930461, 658.0883522791383),
(295, 28, 33, 1, 496.2095988939715, 496.2095988939715),
(296, 265, 43, 5, 258.15051770338926, 1290.7525885169462),
(297, 249, 11, 2, 315.57125543377435, 631.1425108675487),
(298, 132, 39, 2, 89.8724935155258, 179.7449870310516),
(299, 47, 11, 3, 315.57125543377435, 946.7137663013232),
(300, 255, 39, 5, 89.8724935155258, 449.362467577629),
(301, 57, 50, 4, 166.72622777692487, 666.9049111076995),
(302, 266, 1, 2, 358.98465174820154, 717.9693034964031),
(303, 71, 46, 3, 169.93248151532975, 509.79744454598926),
(304, 189, 5, 1, 172.80769876843488, 172.80769876843488),
(305, 113, 42, 4, 322.39767718952066, 1289.5907087580829),
(306, 180, 38, 4, 346.1443085743635, 1384.577234297454),
(307, 118, 40, 5, 452.4008463144313, 2262.004231572156),
(308, 162, 25, 2, 224.5675782233399, 449.1351564466798),
(309, 284, 22, 3, 433.70403983426496, 1301.112119502795),
(310, 86, 21, 5, 182.7412994928937, 913.7064974644684),
(311, 153, 44, 4, 499.5698140705896, 1998.2792562823583),
(312, 146, 28, 2, 479.3408898225919, 958.6817796451838),
(313, 150, 9, 3, 182.5024562282616, 547.5073686847848),
(314, 233, 45, 4, 154.7126846303358, 618.8507385213433),
(315, 53, 14, 2, 380.852744704009, 761.7054894080181),
(316, 165, 4, 4, 353.50398257722065, 1414.0159303088826),
(317, 161, 19, 3, 456.00741451885847, 1368.0222435565754),
(318, 86, 37, 2, 436.2154886334091, 872.4309772668182),
(319, 167, 13, 2, 166.26417041398335, 332.5283408279667),
(320, 152, 15, 3, 179.55046069099683, 538.6513820729905),
(321, 36, 1, 1, 358.98465174820154, 358.98465174820154),
(322, 176, 10, 2, 133.509371642973, 267.018743285946),
(323, 53, 37, 3, 436.2154886334091, 1308.6464659002272),
(324, 140, 5, 1, 172.80769876843488, 172.80769876843488),
(325, 159, 46, 4, 169.93248151532975, 679.729926061319),
(326, 30, 8, 3, 111.61450255218918, 334.8435076565676),
(327, 105, 13, 3, 166.26417041398335, 498.79251124195),
(328, 237, 26, 3, 464.0220163156805, 1392.0660489470413),
(329, 107, 29, 2, 361.88497593070855, 723.7699518614171),
(330, 188, 45, 4, 154.7126846303358, 618.8507385213433),
(331, 138, 27, 2, 146.64515129714397, 293.29030259428794),
(332, 259, 6, 3, 487.45513408319806, 1462.365402249594),
(333, 71, 28, 1, 479.3408898225919, 479.3408898225919),
(334, 239, 21, 5, 182.7412994928937, 913.7064974644684),
(335, 147, 41, 3, 440.94312434058753, 1322.8293730217626),
(336, 62, 28, 1, 479.3408898225919, 479.3408898225919),
(337, 186, 46, 5, 169.93248151532975, 849.6624075766488),
(338, 153, 27, 2, 146.64515129714397, 293.29030259428794),
(339, 248, 14, 1, 380.852744704009, 380.852744704009),
(340, 214, 23, 5, 140.6243555888351, 703.1217779441755),
(341, 61, 15, 4, 179.55046069099683, 718.2018427639873),
(342, 116, 47, 2, 407.9476683953336, 815.8953367906672),
(343, 40, 39, 5, 89.8724935155258, 449.362467577629),
(344, 94, 22, 4, 433.70403983426496, 1734.8161593370598),
(345, 154, 17, 3, 200.8510913678053, 602.5532741034159),
(346, 61, 16, 2, 409.6170697232217, 819.2341394464435),
(347, 46, 46, 3, 169.93248151532975, 509.79744454598926),
(348, 220, 12, 5, 441.95123431386185, 2209.756171569309),
(349, 198, 32, 3, 235.21640863684704, 705.6492259105412),
(350, 29, 49, 4, 89.51848639672136, 358.07394558688543),
(351, 148, 45, 4, 154.7126846303358, 618.8507385213433),
(352, 224, 22, 5, 433.70403983426496, 2168.5201991713247),
(353, 67, 37, 5, 436.2154886334091, 2181.0774431670457),
(354, 53, 20, 4, 218.7660536306108, 875.0642145224432),
(355, 207, 43, 1, 258.15051770338926, 258.15051770338926),
(356, 168, 4, 1, 353.50398257722065, 353.50398257722065),
(357, 6, 2, 2, 255.49922444549492, 510.9984488909899),
(358, 216, 36, 3, 201.6839929677742, 605.0519789033226),
(359, 122, 21, 1, 182.7412994928937, 182.7412994928937),
(360, 123, 2, 4, 255.49922444549492, 1021.9968977819798),
(361, 82, 36, 5, 201.6839929677742, 1008.419964838871),
(362, 298, 21, 5, 182.7412994928937, 913.7064974644684),
(363, 286, 21, 4, 182.7412994928937, 730.9651979715748),
(364, 22, 15, 2, 179.55046069099683, 359.10092138199366),
(365, 177, 5, 2, 172.80769876843488, 345.6153975368697),
(366, 114, 32, 5, 235.21640863684704, 1176.082043184235),
(367, 236, 46, 5, 169.93248151532975, 849.6624075766488),
(368, 10, 31, 5, 447.4753434547104, 2237.3767172735515),
(369, 41, 38, 1, 346.1443085743635, 346.1443085743635),
(370, 177, 12, 2, 441.95123431386185, 883.9024686277237),
(371, 103, 17, 3, 200.8510913678053, 602.5532741034159),
(372, 231, 22, 5, 433.70403983426496, 2168.5201991713247),
(373, 282, 37, 2, 436.2154886334091, 872.4309772668182),
(374, 269, 3, 1, 386.1764811694529, 386.1764811694529),
(375, 227, 45, 5, 154.7126846303358, 773.5634231516791),
(376, 240, 1, 5, 358.98465174820154, 1794.9232587410077),
(377, 134, 18, 1, 219.3627840930461, 219.3627840930461),
(378, 3, 19, 4, 456.00741451885847, 1824.0296580754336),
(379, 263, 19, 4, 456.00741451885847, 1824.0296580754336),
(380, 60, 41, 1, 440.94312434058753, 440.94312434058753),
(381, 233, 22, 2, 433.70403983426496, 867.4080796685299),
(382, 179, 37, 1, 436.2154886334091, 436.2154886334091),
(383, 171, 30, 1, 476.0805682102502, 476.0805682102502),
(384, 12, 37, 4, 436.2154886334091, 1744.8619545336364),
(385, 156, 7, 2, 484.26767905942313, 968.5353581188464),
(386, 271, 24, 3, 344.9015016505583, 1034.704504951675),
(387, 166, 3, 5, 386.1764811694529, 1930.8824058472649),
(388, 139, 44, 2, 499.5698140705896, 999.1396281411792),
(389, 259, 6, 3, 487.45513408319806, 1462.365402249594),
(390, 7, 25, 3, 224.5675782233399, 673.7027346700197),
(391, 246, 2, 2, 255.49922444549492, 510.9984488909899),
(392, 174, 33, 3, 496.2095988939715, 1488.6287966819143),
(393, 271, 19, 4, 456.00741451885847, 1824.0296580754336),
(394, 276, 33, 2, 496.2095988939715, 992.419197787943),
(395, 103, 26, 1, 464.0220163156805, 464.0220163156805),
(396, 226, 50, 1, 166.72622777692487, 166.72622777692487),
(397, 101, 19, 1, 456.00741451885847, 456.00741451885847),
(398, 138, 12, 1, 441.95123431386185, 441.95123431386185),
(399, 189, 2, 5, 255.49922444549492, 1277.4961222274746),
(400, 162, 35, 1, 454.2854952885772, 454.2854952885772),
(401, 121, 11, 2, 315.57125543377435, 631.1425108675487),
(402, 69, 31, 5, 447.4753434547104, 2237.3767172735515),
(403, 195, 29, 4, 361.88497593070855, 1447.5399037228342),
(404, 50, 42, 4, 322.39767718952066, 1289.5907087580829),
(405, 137, 22, 5, 433.70403983426496, 2168.5201991713247),
(406, 190, 32, 5, 235.21640863684704, 1176.082043184235),
(407, 237, 34, 5, 173.08239429241354, 865.4119714620676),
(408, 45, 41, 4, 440.94312434058753, 1763.77249736235),
(409, 24, 22, 1, 433.70403983426496, 433.70403983426496),
(410, 27, 27, 1, 146.64515129714397, 146.64515129714397),
(411, 155, 44, 5, 499.5698140705896, 2497.8490703529483),
(412, 277, 32, 3, 235.21640863684704, 705.6492259105412),
(413, 47, 6, 2, 487.45513408319806, 974.910268166396),
(414, 53, 35, 5, 454.2854952885772, 2271.427476442886),
(415, 40, 31, 4, 447.4753434547104, 1789.9013738188414),
(416, 2, 23, 4, 140.6243555888351, 562.4974223553404),
(417, 114, 41, 2, 440.94312434058753, 881.8862486811751),
(418, 263, 40, 5, 452.4008463144313, 2262.004231572156),
(419, 65, 8, 2, 111.61450255218918, 223.2290051043784),
(420, 183, 3, 3, 386.1764811694529, 1158.5294435083588),
(421, 70, 1, 3, 358.98465174820154, 1076.953955244605),
(422, 56, 17, 5, 200.8510913678053, 1004.2554568390266),
(423, 260, 44, 4, 499.5698140705896, 1998.2792562823583),
(424, 18, 20, 5, 218.7660536306108, 1093.830268153054),
(425, 18, 29, 1, 361.88497593070855, 361.88497593070855),
(426, 42, 34, 3, 173.08239429241354, 519.2471828772407),
(427, 21, 36, 3, 201.6839929677742, 605.0519789033226),
(428, 223, 22, 5, 433.70403983426496, 2168.5201991713247),
(429, 187, 46, 2, 169.93248151532975, 339.8649630306595),
(430, 280, 35, 5, 454.2854952885772, 2271.427476442886),
(431, 185, 25, 2, 224.5675782233399, 449.1351564466798),
(432, 18, 37, 3, 436.2154886334091, 1308.6464659002272),
(433, 50, 3, 4, 386.1764811694529, 1544.7059246778117),
(434, 184, 27, 1, 146.64515129714397, 146.64515129714397),
(435, 41, 5, 1, 172.80769876843488, 172.80769876843488),
(436, 187, 2, 3, 255.49922444549492, 766.4976733364848),
(437, 171, 11, 1, 315.57125543377435, 315.57125543377435),
(438, 233, 40, 4, 452.4008463144313, 1809.603385257725),
(439, 292, 1, 5, 358.98465174820154, 1794.9232587410077),
(440, 290, 37, 1, 436.2154886334091, 436.2154886334091),
(441, 152, 17, 2, 200.8510913678053, 401.7021827356106),
(442, 248, 31, 3, 447.4753434547104, 1342.426030364131),
(443, 142, 34, 1, 173.08239429241354, 173.08239429241354),
(444, 10, 9, 5, 182.5024562282616, 912.5122811413078),
(445, 226, 3, 1, 386.1764811694529, 386.1764811694529),
(446, 236, 23, 2, 140.6243555888351, 281.2487111776702),
(447, 267, 22, 2, 433.70403983426496, 867.4080796685299),
(448, 97, 47, 4, 407.9476683953336, 1631.7906735813344),
(449, 108, 27, 3, 146.64515129714397, 439.9354538914319),
(450, 29, 12, 1, 441.95123431386185, 441.95123431386185),
(451, 92, 31, 3, 447.4753434547104, 1342.426030364131),
(452, 233, 28, 5, 479.3408898225919, 2396.7044491129595),
(453, 39, 15, 2, 179.55046069099683, 359.10092138199366),
(454, 59, 28, 3, 479.3408898225919, 1438.0226694677758),
(455, 213, 29, 5, 361.88497593070855, 1809.4248796535428),
(456, 148, 44, 1, 499.5698140705896, 499.5698140705896),
(457, 66, 43, 2, 258.15051770338926, 516.3010354067785),
(458, 26, 42, 2, 322.39767718952066, 644.7953543790413),
(459, 26, 21, 2, 182.7412994928937, 365.4825989857874),
(460, 172, 43, 1, 258.15051770338926, 258.15051770338926),
(461, 120, 27, 5, 146.64515129714397, 733.2257564857198),
(462, 288, 25, 3, 224.5675782233399, 673.7027346700197),
(463, 140, 23, 1, 140.6243555888351, 140.6243555888351),
(464, 143, 19, 3, 456.00741451885847, 1368.0222435565754),
(465, 261, 39, 4, 89.8724935155258, 359.4899740621032),
(466, 200, 50, 1, 166.72622777692487, 166.72622777692487),
(467, 246, 22, 4, 433.70403983426496, 1734.8161593370598),
(468, 195, 45, 1, 154.7126846303358, 154.7126846303358),
(469, 133, 49, 4, 89.51848639672136, 358.07394558688543),
(470, 54, 46, 4, 169.93248151532975, 679.729926061319),
(471, 251, 32, 1, 235.21640863684704, 235.21640863684704),
(472, 121, 20, 5, 218.7660536306108, 1093.830268153054),
(473, 237, 20, 2, 218.7660536306108, 437.5321072612216),
(474, 266, 34, 3, 173.08239429241354, 519.2471828772407),
(475, 46, 40, 5, 452.4008463144313, 2262.004231572156),
(476, 114, 35, 4, 454.2854952885772, 1817.1419811543087),
(477, 47, 48, 3, 388.8132485394478, 1166.4397456183433),
(478, 162, 16, 3, 409.6170697232217, 1228.8512091696653),
(479, 222, 27, 5, 146.64515129714397, 733.2257564857198),
(480, 154, 12, 4, 441.95123431386185, 1767.8049372554474),
(481, 197, 30, 3, 476.0805682102502, 1428.2417046307503),
(482, 104, 18, 3, 219.3627840930461, 658.0883522791383),
(483, 213, 39, 2, 89.8724935155258, 179.7449870310516),
(484, 134, 23, 2, 140.6243555888351, 281.2487111776702),
(485, 147, 13, 3, 166.26417041398335, 498.79251124195),
(486, 141, 46, 5, 169.93248151532975, 849.6624075766488),
(487, 149, 34, 5, 173.08239429241354, 865.4119714620676),
(488, 236, 4, 4, 353.50398257722065, 1414.0159303088826),
(489, 7, 17, 4, 200.8510913678053, 803.4043654712212),
(490, 260, 25, 3, 224.5675782233399, 673.7027346700197),
(491, 214, 22, 3, 433.70403983426496, 1301.112119502795),
(492, 237, 45, 3, 154.7126846303358, 464.1380538910074),
(493, 139, 42, 3, 322.39767718952066, 967.193031568562),
(494, 57, 37, 4, 436.2154886334091, 1744.8619545336364),
(495, 112, 17, 3, 200.8510913678053, 602.5532741034159),
(496, 90, 35, 5, 454.2854952885772, 2271.427476442886),
(497, 31, 9, 3, 182.5024562282616, 547.5073686847848),
(498, 251, 27, 4, 146.64515129714397, 586.5806051885759),
(499, 205, 33, 3, 496.2095988939715, 1488.6287966819143),
(500, 63, 6, 3, 487.45513408319806, 1462.365402249594),
(501, 218, 28, 3, 479.3408898225919, 1438.0226694677758),
(502, 176, 43, 4, 258.15051770338926, 1032.602070813557),
(503, 2, 5, 1, 172.80769876843488, 172.80769876843488),
(504, 296, 10, 2, 133.509371642973, 267.018743285946),
(505, 271, 25, 3, 224.5675782233399, 673.7027346700197),
(506, 13, 11, 5, 315.57125543377435, 1577.8562771688717),
(507, 38, 5, 2, 172.80769876843488, 345.6153975368697),
(508, 82, 43, 5, 258.15051770338926, 1290.7525885169462),
(509, 264, 21, 5, 182.7412994928937, 913.7064974644684),
(510, 272, 29, 1, 361.88497593070855, 361.88497593070855),
(511, 40, 12, 4, 441.95123431386185, 1767.8049372554474),
(512, 199, 33, 1, 496.2095988939715, 496.2095988939715),
(513, 39, 14, 3, 380.852744704009, 1142.558234112027),
(514, 12, 31, 5, 447.4753434547104, 2237.3767172735515),
(515, 293, 12, 1, 441.95123431386185, 441.95123431386185),
(516, 133, 44, 1, 499.5698140705896, 499.5698140705896),
(517, 110, 16, 3, 409.6170697232217, 1228.8512091696653),
(518, 231, 48, 1, 388.8132485394478, 388.8132485394478),
(519, 209, 37, 3, 436.2154886334091, 1308.6464659002272),
(520, 150, 47, 3, 407.9476683953336, 1223.843005186001),
(521, 80, 7, 5, 484.26767905942313, 2421.338395297116),
(522, 3, 24, 3, 344.9015016505583, 1034.704504951675),
(523, 249, 39, 3, 89.8724935155258, 269.61748054657744),
(524, 148, 38, 2, 346.1443085743635, 692.288617148727),
(525, 51, 30, 4, 476.0805682102502, 1904.3222728410008),
(526, 163, 33, 2, 496.2095988939715, 992.419197787943),
(527, 119, 32, 5, 235.21640863684704, 1176.082043184235),
(528, 90, 5, 1, 172.80769876843488, 172.80769876843488),
(529, 51, 49, 2, 89.51848639672136, 179.03697279344271),
(530, 70, 36, 2, 201.6839929677742, 403.3679859355484),
(531, 177, 20, 2, 218.7660536306108, 437.5321072612216),
(532, 293, 9, 5, 182.5024562282616, 912.5122811413078),
(533, 252, 10, 5, 133.509371642973, 667.5468582148651),
(534, 228, 14, 2, 380.852744704009, 761.7054894080181),
(535, 60, 37, 1, 436.2154886334091, 436.2154886334091),
(536, 135, 34, 1, 173.08239429241354, 173.08239429241354),
(537, 78, 11, 5, 315.57125543377435, 1577.8562771688717),
(538, 52, 3, 5, 386.1764811694529, 1930.8824058472649),
(539, 265, 48, 2, 388.8132485394478, 777.6264970788956),
(540, 122, 36, 1, 201.6839929677742, 201.6839929677742),
(541, 170, 36, 2, 201.6839929677742, 403.3679859355484),
(542, 82, 19, 4, 456.00741451885847, 1824.0296580754336),
(543, 44, 15, 2, 179.55046069099683, 359.10092138199366),
(544, 57, 32, 1, 235.21640863684704, 235.21640863684704),
(545, 52, 2, 1, 255.49922444549492, 255.49922444549492),
(546, 293, 12, 3, 441.95123431386185, 1325.8537029415857),
(547, 100, 27, 2, 146.64515129714397, 293.29030259428794),
(548, 112, 20, 4, 218.7660536306108, 875.0642145224432),
(549, 36, 17, 1, 200.8510913678053, 200.8510913678053),
(550, 252, 9, 5, 182.5024562282616, 912.5122811413078),
(551, 156, 39, 1, 89.8724935155258, 89.8724935155258),
(552, 8, 46, 5, 169.93248151532975, 849.6624075766488),
(553, 108, 41, 1, 440.94312434058753, 440.94312434058753),
(554, 84, 25, 1, 224.5675782233399, 224.5675782233399),
(555, 22, 49, 3, 89.51848639672136, 268.5554591901641),
(556, 250, 30, 2, 476.0805682102502, 952.1611364205004),
(557, 34, 19, 1, 456.00741451885847, 456.00741451885847),
(558, 158, 19, 4, 456.00741451885847, 1824.0296580754336),
(559, 24, 43, 2, 258.15051770338926, 516.3010354067785),
(560, 189, 25, 5, 224.5675782233399, 1122.8378911166994),
(561, 28, 7, 1, 484.26767905942313, 484.26767905942313),
(562, 144, 4, 3, 353.50398257722065, 1060.511947731662),
(563, 16, 20, 1, 218.7660536306108, 218.7660536306108),
(564, 211, 3, 3, 386.1764811694529, 1158.5294435083588),
(565, 44, 36, 1, 201.6839929677742, 201.6839929677742),
(566, 253, 25, 2, 224.5675782233399, 449.1351564466798),
(567, 163, 21, 4, 182.7412994928937, 730.9651979715748),
(568, 149, 28, 1, 479.3408898225919, 479.3408898225919),
(569, 281, 43, 1, 258.15051770338926, 258.15051770338926),
(570, 204, 44, 1, 499.5698140705896, 499.5698140705896),
(571, 166, 27, 2, 146.64515129714397, 293.29030259428794),
(572, 78, 36, 3, 201.6839929677742, 605.0519789033226),
(573, 29, 18, 5, 219.3627840930461, 1096.8139204652307),
(574, 143, 1, 4, 358.98465174820154, 1435.9386069928062),
(575, 148, 26, 4, 464.0220163156805, 1856.0880652627216),
(576, 150, 31, 3, 447.4753434547104, 1342.426030364131),
(577, 151, 48, 5, 388.8132485394478, 1944.066242697239),
(578, 198, 35, 2, 454.2854952885772, 908.5709905771544),
(579, 112, 1, 5, 358.98465174820154, 1794.9232587410077),
(580, 186, 30, 1, 476.0805682102502, 476.0805682102502),
(581, 215, 47, 5, 407.9476683953336, 2039.738341976668),
(582, 187, 38, 1, 346.1443085743635, 346.1443085743635),
(583, 165, 30, 1, 476.0805682102502, 476.0805682102502),
(584, 260, 7, 1, 484.26767905942313, 484.26767905942313),
(585, 194, 11, 4, 315.57125543377435, 1262.2850217350974),
(586, 103, 24, 1, 344.9015016505583, 344.9015016505583),
(587, 70, 26, 5, 464.0220163156805, 2320.110081578402),
(588, 170, 48, 1, 388.8132485394478, 388.8132485394478),
(589, 240, 12, 3, 441.95123431386185, 1325.8537029415857),
(590, 5, 29, 5, 361.88497593070855, 1809.4248796535428),
(591, 288, 13, 3, 166.26417041398335, 498.79251124195),
(592, 104, 3, 5, 386.1764811694529, 1930.8824058472649),
(593, 104, 3, 4, 386.1764811694529, 1544.7059246778117),
(594, 157, 27, 3, 146.64515129714397, 439.9354538914319),
(595, 3, 17, 3, 200.8510913678053, 602.5532741034159),
(596, 202, 29, 2, 361.88497593070855, 723.7699518614171),
(597, 113, 24, 1, 344.9015016505583, 344.9015016505583),
(598, 269, 2, 3, 255.49922444549492, 766.4976733364848),
(599, 185, 9, 3, 182.5024562282616, 547.5073686847848),
(600, 132, 33, 2, 496.2095988939715, 992.419197787943);

-- ============================================================================
-- POST-IMPORT ROW COUNT VERIFICATION
-- ============================================================================
SELECT 'supplier' AS table_name, COUNT(*) AS row_count FROM supplier
UNION ALL
SELECT 'categories', COUNT(*) FROM categories
UNION ALL
SELECT 'employees', COUNT(*) FROM employees
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_details', COUNT(*) FROM order_details;


-- ============================================================================
-- PART: 04_validation.sql
-- ============================================================================
-- ============================================================================
-- Project: Grocery Store Management SQL Database
-- File: 04_validation.sql
-- Description: Comprehensive QA & Data Integrity Validation Test Suite
-- Author: Mahaboob Subhani Shaik
-- Target DBMS: MySQL 8.x
-- ============================================================================

USE grocery_store;

-- ============================================================================
-- TEST SUITE 1: ROW COUNT VERIFICATION
-- Validates actual database row counts against authoritative CSV baselines.
-- Expected: supplier=5, categories=5, employees=10, customers=200,
--           products=50, orders=300, order_details=600.
-- ============================================================================
SELECT 
    'supplier' AS table_name, 
    COUNT(*) AS actual_count, 
    5 AS expected_count,
    CASE WHEN COUNT(*) = 5 THEN 'PASS' ELSE 'FAIL' END AS status
FROM supplier
UNION ALL
SELECT 'categories', COUNT(*), 5, CASE WHEN COUNT(*) = 5 THEN 'PASS' ELSE 'FAIL' END FROM categories
UNION ALL
SELECT 'employees', COUNT(*), 10, CASE WHEN COUNT(*) = 10 THEN 'PASS' ELSE 'FAIL' END FROM employees
UNION ALL
SELECT 'customers', COUNT(*), 200, CASE WHEN COUNT(*) = 200 THEN 'PASS' ELSE 'FAIL' END FROM customers
UNION ALL
SELECT 'products', COUNT(*), 50, CASE WHEN COUNT(*) = 50 THEN 'PASS' ELSE 'FAIL' END FROM products
UNION ALL
SELECT 'orders', COUNT(*), 300, CASE WHEN COUNT(*) = 300 THEN 'PASS' ELSE 'FAIL' END FROM orders
UNION ALL
SELECT 'order_details', COUNT(*), 600, CASE WHEN COUNT(*) = 600 THEN 'PASS' ELSE 'FAIL' END FROM order_details;


-- ============================================================================
-- TEST SUITE 2: PRIMARY KEY UNIQUENESS & NOT NULL AUDIT
-- Verifies that primary keys have zero duplicates and zero NULLs.
-- ============================================================================
SELECT 
    'supplier.sup_id' AS pk_column,
    COUNT(sup_id) AS total_keys,
    COUNT(DISTINCT sup_id) AS unique_keys,
    SUM(CASE WHEN sup_id IS NULL THEN 1 ELSE 0 END) AS null_keys,
    CASE WHEN COUNT(sup_id) = COUNT(DISTINCT sup_id) AND SUM(CASE WHEN sup_id IS NULL THEN 1 ELSE 0 END) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM supplier
UNION ALL
SELECT 'categories.cat_id', COUNT(cat_id), COUNT(DISTINCT cat_id), SUM(CASE WHEN cat_id IS NULL THEN 1 ELSE 0 END),
    CASE WHEN COUNT(cat_id) = COUNT(DISTINCT cat_id) AND SUM(CASE WHEN cat_id IS NULL THEN 1 ELSE 0 END) = 0 THEN 'PASS' ELSE 'FAIL' END FROM categories
UNION ALL
SELECT 'employees.emp_id', COUNT(emp_id), COUNT(DISTINCT emp_id), SUM(CASE WHEN emp_id IS NULL THEN 1 ELSE 0 END),
    CASE WHEN COUNT(emp_id) = COUNT(DISTINCT emp_id) AND SUM(CASE WHEN emp_id IS NULL THEN 1 ELSE 0 END) = 0 THEN 'PASS' ELSE 'FAIL' END FROM employees
UNION ALL
SELECT 'customers.cust_id', COUNT(cust_id), COUNT(DISTINCT cust_id), SUM(CASE WHEN cust_id IS NULL THEN 1 ELSE 0 END),
    CASE WHEN COUNT(cust_id) = COUNT(DISTINCT cust_id) AND SUM(CASE WHEN cust_id IS NULL THEN 1 ELSE 0 END) = 0 THEN 'PASS' ELSE 'FAIL' END FROM customers
UNION ALL
SELECT 'products.prod_id', COUNT(prod_id), COUNT(DISTINCT prod_id), SUM(CASE WHEN prod_id IS NULL THEN 1 ELSE 0 END),
    CASE WHEN COUNT(prod_id) = COUNT(DISTINCT prod_id) AND SUM(CASE WHEN prod_id IS NULL THEN 1 ELSE 0 END) = 0 THEN 'PASS' ELSE 'FAIL' END FROM products
UNION ALL
SELECT 'orders.ord_id', COUNT(ord_id), COUNT(DISTINCT ord_id), SUM(CASE WHEN ord_id IS NULL THEN 1 ELSE 0 END),
    CASE WHEN COUNT(ord_id) = COUNT(DISTINCT ord_id) AND SUM(CASE WHEN ord_id IS NULL THEN 1 ELSE 0 END) = 0 THEN 'PASS' ELSE 'FAIL' END FROM orders
UNION ALL
SELECT 'order_details.ord_detID', COUNT(ord_detID), COUNT(DISTINCT ord_detID), SUM(CASE WHEN ord_detID IS NULL THEN 1 ELSE 0 END),
    CASE WHEN COUNT(ord_detID) = COUNT(DISTINCT ord_detID) AND SUM(CASE WHEN ord_detID IS NULL THEN 1 ELSE 0 END) = 0 THEN 'PASS' ELSE 'FAIL' END FROM order_details;


-- ============================================================================
-- TEST SUITE 3: REFERENTIAL INTEGRITY (ORPHAN FOREIGN KEY SCANS)
-- Scans all six child-parent relationships for orphan foreign key values.
-- Expected: Exactly 0 orphans for every relationship.
-- ============================================================================
SELECT 
    'products -> supplier' AS relationship,
    COUNT(*) AS orphan_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM products p
LEFT JOIN supplier s ON p.sup_id = s.sup_id
WHERE s.sup_id IS NULL
UNION ALL
SELECT 'products -> categories', COUNT(*), CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM products p
LEFT JOIN categories c ON p.cat_id = c.cat_id
WHERE c.cat_id IS NULL
UNION ALL
SELECT 'orders -> customers', COUNT(*), CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM orders o
LEFT JOIN customers c ON o.cust_id = c.cust_id
WHERE c.cust_id IS NULL
UNION ALL
SELECT 'orders -> employees', COUNT(*), CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM orders o
LEFT JOIN employees e ON o.emp_id = e.emp_id
WHERE e.emp_id IS NULL
UNION ALL
SELECT 'order_details -> orders', COUNT(*), CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM order_details od
LEFT JOIN orders o ON od.ord_id = o.ord_id
WHERE o.ord_id IS NULL
UNION ALL
SELECT 'order_details -> products', COUNT(*), CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM order_details od
LEFT JOIN products p ON od.prod_id = p.prod_id
WHERE p.prod_id IS NULL;


-- ============================================================================
-- TEST SUITE 4: ORDER FULFILLMENT & REVENUE INTEGRITY AUDIT
-- Validates critical Phase 1 findings:
-- 1. Orders without line items = exactly 44
-- 2. Orders with line items = exactly 256
-- 3. Total store revenue = exactly ₹551,330.00
-- ============================================================================
SELECT 
    'Orders with NO line items' AS metric,
    COUNT(o.ord_id) AS actual_value,
    44 AS expected_value,
    CASE WHEN COUNT(o.ord_id) = 44 THEN 'PASS' ELSE 'FAIL' END AS status
FROM orders o
LEFT JOIN order_details od ON o.ord_id = od.ord_id
WHERE od.ord_id IS NULL
UNION ALL
SELECT 
    'Orders WITH line items',
    COUNT(DISTINCT od.ord_id),
    256,
    CASE WHEN COUNT(DISTINCT od.ord_id) = 256 THEN 'PASS' ELSE 'FAIL' END
FROM order_details od
UNION ALL
SELECT 
    'Total Store Revenue (INR)',
    ROUND(SUM(total_price), 2),
    551330.00,
    CASE WHEN ROUND(SUM(total_price), 2) = 551330.00 THEN 'PASS' ELSE 'FAIL' END
FROM order_details;


-- ============================================================================
-- TEST SUITE 5: CUSTOMER ORDER PARTICIPATION AUDIT
-- Validates:
-- 1. Customers who placed orders = exactly 156
-- 2. Customers with fulfilled orders (with line items) = exactly 141
-- ============================================================================
SELECT 
    'Unique customers placing orders' AS metric,
    COUNT(DISTINCT cust_id) AS actual_value,
    156 AS expected_value,
    CASE WHEN COUNT(DISTINCT cust_id) = 156 THEN 'PASS' ELSE 'FAIL' END AS status
FROM orders
UNION ALL
SELECT 
    'Unique customers with fulfilled items',
    COUNT(DISTINCT o.cust_id),
    141,
    CASE WHEN COUNT(DISTINCT o.cust_id) = 141 THEN 'PASS' ELSE 'FAIL' END
FROM orders o
INNER JOIN order_details od ON o.ord_id = od.ord_id;


-- ============================================================================
-- TEST SUITE 6: LINE-ITEM ARITHMETIC & CATALOG PRICE CONSISTENCY
-- Validates:
-- 1. TotalPrice = Quantity * PriceEach across all 600 line items (0 mismatches)
-- 2. OrderDetails.each_price = Products.price across all 600 line items (0 mismatches)
-- ============================================================================
SELECT 
    'TotalPrice = Quantity * PriceEach mismatches' AS check_name,
    COUNT(*) AS mismatch_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM order_details
WHERE ABS(total_price - (quantity * each_price)) > 0.01
UNION ALL
SELECT 
    'OrderDetails each_price != Products catalog price mismatches',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM order_details od
INNER JOIN products p ON od.prod_id = p.prod_id
WHERE ABS(od.each_price - p.price) > 0.01;


-- ============================================================================
-- TEST SUITE 7: DATE PARSING & TEMPORAL INTEGRITY
-- Validates that hire_date and order_date strings parse cleanly with '%m/%d/%Y'
-- with zero parsing failures.
-- ============================================================================
SELECT 
    'employees.hire_date parse failures' AS check_name,
    COUNT(*) AS failure_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM employees
WHERE STR_TO_DATE(hire_date, '%m/%d/%Y') IS NULL
UNION ALL
SELECT 
    'orders.order_date parse failures',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM orders
WHERE STR_TO_DATE(order_date, '%m/%d/%Y') IS NULL;


-- ============================================================================
-- TEST SUITE 8: PRIMARY KEY PRESERVATION AUDIT
-- Validates that imported IDs match source CSV bounds (Min=1, Max=N, Count=N).
-- ============================================================================
SELECT 
    'supplier' AS table_name,
    MIN(sup_id) AS min_id,
    MAX(sup_id) AS max_id,
    COUNT(sup_id) AS total_ids,
    CASE WHEN MIN(sup_id) = 1 AND MAX(sup_id) = 5 AND COUNT(sup_id) = 5 THEN 'PASS' ELSE 'FAIL' END AS status
FROM supplier
UNION ALL
SELECT 'categories', MIN(cat_id), MAX(cat_id), COUNT(cat_id),
    CASE WHEN MIN(cat_id) = 1 AND MAX(cat_id) = 5 AND COUNT(cat_id) = 5 THEN 'PASS' ELSE 'FAIL' END FROM categories
UNION ALL
SELECT 'employees', MIN(emp_id), MAX(emp_id), COUNT(emp_id),
    CASE WHEN MIN(emp_id) = 1 AND MAX(emp_id) = 10 AND COUNT(emp_id) = 10 THEN 'PASS' ELSE 'FAIL' END FROM employees
UNION ALL
SELECT 'customers', MIN(cust_id), MAX(cust_id), COUNT(cust_id),
    CASE WHEN MIN(cust_id) = 1 AND MAX(cust_id) = 200 AND COUNT(cust_id) = 200 THEN 'PASS' ELSE 'FAIL' END FROM customers
UNION ALL
SELECT 'products', MIN(prod_id), MAX(prod_id), COUNT(prod_id),
    CASE WHEN MIN(prod_id) = 1 AND MAX(prod_id) = 50 AND COUNT(prod_id) = 50 THEN 'PASS' ELSE 'FAIL' END FROM products
UNION ALL
SELECT 'orders', MIN(ord_id), MAX(ord_id), COUNT(ord_id),
    CASE WHEN MIN(ord_id) = 1 AND MAX(ord_id) = 300 AND COUNT(ord_id) = 300 THEN 'PASS' ELSE 'FAIL' END FROM orders
UNION ALL
SELECT 'order_details', MIN(ord_detID), MAX(ord_detID), COUNT(ord_detID),
    CASE WHEN MIN(ord_detID) = 1 AND MAX(ord_detID) = 600 AND COUNT(ord_detID) = 600 THEN 'PASS' ELSE 'FAIL' END FROM order_details;


-- ============================================================================
-- PART: 05_analysis.sql
-- ============================================================================
-- ============================================================================
-- Project: Grocery Store Management SQL Database
-- File: 05_analysis.sql
-- Description: Authoritative Analytical Query Suite answering all 25 PDF questions
-- Author: Mahaboob Subhani Shaik
-- Target DBMS: MySQL 8.x
-- ============================================================================

USE grocery_store;

-- ============================================================================
-- SECTION 1: CUSTOMER INSIGHTS
-- Gain an understanding of customer engagement and purchasing behavior.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Question 1.1: How many unique customers have placed orders?
-- Business Context: Measures active customer conversion out of total registered accounts.
-- Nuance: 156 customers placed orders; 141 customers have orders containing line items.
-- ----------------------------------------------------------------------------
-- Business Question: How many unique customers have placed orders?
-- SQL Query:
SELECT 
    COUNT(DISTINCT cust_id) AS unique_customers_placed_orders,
    (SELECT COUNT(*) FROM customers) AS total_registered_customers,
    ROUND(COUNT(DISTINCT cust_id) * 100.0 / (SELECT COUNT(*) FROM customers), 2) AS order_placement_rate_pct,
    (SELECT COUNT(DISTINCT o.cust_id) 
     FROM orders o 
     INNER JOIN order_details od ON o.ord_id = od.ord_id) AS unique_customers_fulfilled_purchases
FROM orders;


-- ----------------------------------------------------------------------------
-- Question 1.2: Which customers have placed the highest number of orders?
-- Business Context: Identifies high-frequency repeat shoppers for loyalty rewards.
-- ----------------------------------------------------------------------------
-- Business Question: Which customers have placed the highest number of orders?
-- SQL Query:
SELECT 
    c.cust_id,
    c.cust_name,
    COUNT(DISTINCT o.ord_id) AS total_orders_placed,
    COUNT(DISTINCT od.ord_id) AS fulfilled_orders,
    DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT o.ord_id) DESC) AS order_frequency_rank
FROM customers c
INNER JOIN orders o ON c.cust_id = o.cust_id
LEFT JOIN order_details od ON o.ord_id = od.ord_id
GROUP BY c.cust_id, c.cust_name
ORDER BY total_orders_placed DESC, c.cust_id ASC
LIMIT 10;


-- ----------------------------------------------------------------------------
-- Question 1.3: What is the total and average purchase value per customer?
-- Business Context: Measures customer lifetime value (CLV) and average order spend.
-- Denominator: Total customer spend divided by active orders placed by that customer.
-- ----------------------------------------------------------------------------
-- Business Question: What is the total and average purchase value per customer?
-- SQL Query:
SELECT 
    c.cust_id,
    c.cust_name,
    COUNT(DISTINCT o.ord_id) AS total_orders,
    ROUND(SUM(od.total_price), 2) AS total_purchase_value,
    ROUND(SUM(od.total_price) / COUNT(DISTINCT o.ord_id), 2) AS avg_purchase_value_per_order,
    COUNT(od.ord_detID) AS total_items_purchased
FROM customers c
INNER JOIN orders o ON c.cust_id = o.cust_id
INNER JOIN order_details od ON o.ord_id = od.ord_id
GROUP BY c.cust_id, c.cust_name
ORDER BY total_purchase_value DESC;


-- ----------------------------------------------------------------------------
-- Question 1.4: Who are the top 5 customers by total purchase amount?
-- Business Context: Surfaces key VIP clients contributing most to gross revenue.
-- ----------------------------------------------------------------------------
-- Business Question: Who are the top 5 customers by total purchase amount?
-- SQL Query:
SELECT 
    c.cust_id,
    c.cust_name,
    COUNT(DISTINCT o.ord_id) AS total_orders,
    ROUND(SUM(od.total_price), 2) AS total_purchase_amount,
    ROUND(SUM(od.total_price) / COUNT(DISTINCT o.ord_id), 2) AS avg_order_value
FROM customers c
INNER JOIN orders o ON c.cust_id = o.cust_id
INNER JOIN order_details od ON o.ord_id = od.ord_id
GROUP BY c.cust_id, c.cust_name
ORDER BY total_purchase_amount DESC
LIMIT 5;



-- ============================================================================
-- SECTION 2: PRODUCT PERFORMANCE
-- Evaluate how well products are performing in terms of sales and revenue.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Question 2.1: How many products exist in each category?
-- Business Context: Analyzes department catalog width and inventory depth.
-- ----------------------------------------------------------------------------
-- Business Question: How many products exist in each category?
-- SQL Query:
SELECT 
    c.cat_id,
    c.cat_name,
    COUNT(p.prod_id) AS product_count,
    ROUND(COUNT(p.prod_id) * 100.0 / (SELECT COUNT(*) FROM products), 2) AS catalog_share_pct
FROM categories c
LEFT JOIN products p ON c.cat_id = p.cat_id
GROUP BY c.cat_id, c.cat_name
ORDER BY product_count DESC, c.cat_id ASC;


-- ----------------------------------------------------------------------------
-- Question 2.2: What is the average price of products by category?
-- Business Context: Determines department price positioning (premium vs budget).
-- ----------------------------------------------------------------------------
-- Business Question: What is the average price of products by category?
-- SQL Query:
SELECT 
    c.cat_id,
    c.cat_name,
    ROUND(AVG(p.price), 2) AS avg_product_price,
    ROUND(MIN(p.price), 2) AS min_product_price,
    ROUND(MAX(p.price), 2) AS max_product_price,
    COUNT(p.prod_id) AS category_sku_count
FROM categories c
INNER JOIN products p ON c.cat_id = p.cat_id
GROUP BY c.cat_id, c.cat_name
ORDER BY avg_product_price DESC;


-- ----------------------------------------------------------------------------
-- Question 2.3: Which products have the highest total sales volume (by quantity)?
-- Business Context: Identifies fast-moving consumer goods (FMCG) driving foot traffic.
-- ----------------------------------------------------------------------------
-- Business Question: Which products have the highest total sales volume (by quantity)?
-- SQL Query:
SELECT 
    p.prod_id,
    p.prod_name,
    c.cat_name,
    SUM(od.quantity) AS total_units_sold,
    ROUND(SUM(od.total_price), 2) AS total_revenue_generated,
    COUNT(od.ord_detID) AS times_ordered
FROM products p
INNER JOIN categories c ON p.cat_id = c.cat_id
INNER JOIN order_details od ON p.prod_id = od.prod_id
GROUP BY p.prod_id, p.prod_name, c.cat_name
ORDER BY total_units_sold DESC, total_revenue_generated DESC
LIMIT 10;


-- ----------------------------------------------------------------------------
-- Question 2.4: What is the total revenue generated by each product?
-- Business Context: Identifies top-grossing products contributing to gross margin.
-- ----------------------------------------------------------------------------
-- Business Question: What is the total revenue generated by each product?
-- SQL Query:
SELECT 
    p.prod_id,
    p.prod_name,
    c.cat_name,
    ROUND(SUM(od.total_price), 2) AS total_revenue_generated,
    SUM(od.quantity) AS total_units_sold,
    ROUND(SUM(od.total_price) * 100.0 / (SELECT SUM(total_price) FROM order_details), 2) AS store_revenue_share_pct
FROM products p
INNER JOIN categories c ON p.cat_id = c.cat_id
INNER JOIN order_details od ON p.prod_id = od.prod_id
GROUP BY p.prod_id, p.prod_name, c.cat_name
ORDER BY total_revenue_generated DESC;


-- ----------------------------------------------------------------------------
-- Question 2.5: How do product sales vary by category and supplier?
-- Business Context: Evaluates supplier performance across specific retail departments.
-- ----------------------------------------------------------------------------
-- Business Question: How do product sales vary by category and supplier?
-- SQL Query:
SELECT 
    c.cat_name,
    s.sup_name,
    COUNT(DISTINCT p.prod_id) AS distinct_skus_sold,
    SUM(od.quantity) AS total_quantity_sold,
    ROUND(SUM(od.total_price), 2) AS total_revenue,
    ROUND(AVG(od.each_price), 2) AS avg_selling_price
FROM order_details od
INNER JOIN products p ON od.prod_id = p.prod_id
INNER JOIN categories c ON p.cat_id = c.cat_id
INNER JOIN supplier s ON p.sup_id = s.sup_id
GROUP BY c.cat_name, s.sup_name
ORDER BY total_revenue DESC;



-- ============================================================================
-- SECTION 3: SALES AND ORDER TRENDS
-- Analyze business performance through orders and revenue over time.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Question 3.1: How many orders have been placed in total?
-- Business Context: Measures total order transactions, accounting for fulfillment.
-- Nuance: Reconciles all 300 placed orders vs 256 orders with line items.
-- ----------------------------------------------------------------------------
-- Business Question: How many orders have been placed in total?
-- SQL Query:
SELECT 
    COUNT(DISTINCT o.ord_id) AS total_orders_placed,
    COUNT(DISTINCT CASE WHEN od.ord_id IS NOT NULL THEN o.ord_id END) AS orders_with_line_items,
    COUNT(DISTINCT CASE WHEN od.ord_id IS NULL THEN o.ord_id END) AS orders_without_line_items,
    ROUND(COUNT(DISTINCT CASE WHEN od.ord_id IS NOT NULL THEN o.ord_id END) * 100.0 / COUNT(DISTINCT o.ord_id), 2) AS order_fulfillment_rate_pct
FROM orders o
LEFT JOIN order_details od ON o.ord_id = od.ord_id;


-- ----------------------------------------------------------------------------
-- Question 3.2: What is the average value per order?
-- Business Context: Calculates Average Order Value (AOV).
-- Metric: Reports both active fulfilled orders (N=256) and all placed orders (N=300).
-- ----------------------------------------------------------------------------
-- Business Question: What is the average value per order?
-- SQL Query:
WITH order_summaries AS (
    SELECT 
        o.ord_id,
        COALESCE(SUM(od.total_price), 0) AS order_total
    FROM orders o
    LEFT JOIN order_details od ON o.ord_id = od.ord_id
    GROUP BY o.ord_id
)
SELECT 
    ROUND(AVG(CASE WHEN order_total > 0 THEN order_total END), 2) AS avg_value_active_fulfilled_orders,
    ROUND(AVG(order_total), 2) AS avg_value_all_placed_orders,
    ROUND(SUM(order_total), 2) AS total_store_revenue,
    COUNT(CASE WHEN order_total > 0 THEN 1 END) AS active_order_count,
    COUNT(*) AS total_order_count
FROM order_summaries;


-- ----------------------------------------------------------------------------
-- Question 3.3: On which dates were the most orders placed?
-- Business Context: Identifies peak store traffic calendar dates.
-- ----------------------------------------------------------------------------
-- Business Question: On which dates were the most orders placed?
-- SQL Query:
SELECT 
    order_date,
    COUNT(ord_id) AS order_count,
    DENSE_RANK() OVER (ORDER BY COUNT(ord_id) DESC) AS date_rank
FROM orders
GROUP BY order_date
ORDER BY order_count DESC, STR_TO_DATE(order_date, '%m/%d/%Y') ASC
LIMIT 10;


-- ----------------------------------------------------------------------------
-- Question 3.4: What are the monthly trends in order volume and revenue?
-- Business Context: Evaluates seasonality, month-over-month trajectory, and sales pace.
-- ----------------------------------------------------------------------------
-- Business Question: What are the monthly trends in order volume and revenue?
-- SQL Query:
SELECT 
    DATE_FORMAT(STR_TO_DATE(o.order_date, '%m/%d/%Y'), '%Y-%m') AS order_month,
    COUNT(DISTINCT o.ord_id) AS total_placed_orders,
    COUNT(DISTINCT CASE WHEN od.ord_id IS NOT NULL THEN o.ord_id END) AS active_orders_with_sales,
    ROUND(SUM(od.total_price), 2) AS total_monthly_revenue,
    ROUND(SUM(od.total_price) / COUNT(DISTINCT CASE WHEN od.ord_id IS NOT NULL THEN o.ord_id END), 2) AS avg_active_order_value,
    SUM(od.quantity) AS total_units_sold
FROM orders o
LEFT JOIN order_details od ON o.ord_id = od.ord_id
GROUP BY order_month
ORDER BY order_month ASC;


-- ----------------------------------------------------------------------------
-- Question 3.5: How do order patterns vary across weekdays and weekends?
-- Business Context: Compares weekday vs weekend shopping frequency and basket size.
-- ----------------------------------------------------------------------------
-- Business Question: How do order patterns vary across weekdays and weekends?
-- SQL Query:
SELECT 
    CASE 
        WHEN WEEKDAY(STR_TO_DATE(o.order_date, '%m/%d/%Y')) IN (5, 6) THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    COUNT(DISTINCT o.ord_id) AS total_orders_placed,
    COUNT(DISTINCT CASE WHEN od.ord_id IS NOT NULL THEN o.ord_id END) AS active_sales_orders,
    ROUND(SUM(od.total_price), 2) AS total_revenue,
    ROUND(SUM(od.total_price) / COUNT(DISTINCT CASE WHEN od.ord_id IS NOT NULL THEN o.ord_id END), 2) AS avg_order_value,
    ROUND(SUM(od.total_price) * 100.0 / (SELECT SUM(total_price) FROM order_details), 2) AS revenue_share_pct
FROM orders o
LEFT JOIN order_details od ON o.ord_id = od.ord_id
GROUP BY day_type
ORDER BY total_revenue DESC;



-- ============================================================================
-- SECTION 4: SUPPLIER CONTRIBUTION
-- Identify the most active and profitable suppliers.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Question 4.1: How many suppliers are there in the database?
-- Business Context: Establishes the wholesale vendor base count.
-- ----------------------------------------------------------------------------
-- Business Question: How many suppliers are there in the database?
-- SQL Query:
SELECT COUNT(*) AS total_suppliers_count FROM supplier;


-- ----------------------------------------------------------------------------
-- Question 4.2: Which supplier provides the most products?
-- Business Context: Determines vendor catalog dependency.
-- ----------------------------------------------------------------------------
-- Business Question: Which supplier provides the most products?
-- SQL Query:
SELECT 
    s.sup_id,
    s.sup_name,
    COUNT(p.prod_id) AS products_supplied_count,
    ROUND(COUNT(p.prod_id) * 100.0 / (SELECT COUNT(*) FROM products), 2) AS catalog_share_pct
FROM supplier s
LEFT JOIN products p ON s.sup_id = p.sup_id
GROUP BY s.sup_id, s.sup_name
ORDER BY products_supplied_count DESC, s.sup_id ASC;


-- ----------------------------------------------------------------------------
-- Question 4.3: What is the average price of products from each supplier?
-- Business Context: Compares pricing tiers across distributor partners.
-- ----------------------------------------------------------------------------
-- Business Question: What is the average price of products from each supplier?
-- SQL Query:
SELECT 
    s.sup_id,
    s.sup_name,
    ROUND(AVG(p.price), 2) AS avg_product_price,
    ROUND(MIN(p.price), 2) AS min_product_price,
    ROUND(MAX(p.price), 2) AS max_product_price,
    COUNT(p.prod_id) AS total_catalog_products
FROM supplier s
INNER JOIN products p ON s.sup_id = p.sup_id
GROUP BY s.sup_id, s.sup_name
ORDER BY avg_product_price DESC;


-- ----------------------------------------------------------------------------
-- Question 4.4: Which suppliers contribute the most to total product sales (by revenue)?
-- Business Context: Identifies supplier revenue contribution and concentration risk.
-- ----------------------------------------------------------------------------
-- Business Question: Which suppliers contribute the most to total product sales (by revenue)?
-- SQL Query:
SELECT 
    s.sup_id,
    s.sup_name,
    ROUND(SUM(od.total_price), 2) AS total_revenue_contributed,
    ROUND(SUM(od.total_price) * 100.0 / (SELECT SUM(total_price) FROM order_details), 2) AS revenue_share_pct,
    SUM(od.quantity) AS total_units_sold
FROM supplier s
INNER JOIN products p ON s.sup_id = p.sup_id
INNER JOIN order_details od ON p.prod_id = od.prod_id
GROUP BY s.sup_id, s.sup_name
ORDER BY total_revenue_contributed DESC;



-- ============================================================================
-- SECTION 5: EMPLOYEE PERFORMANCE
-- Assess how employees are handling and influencing sales.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Question 5.1: How many employees have processed orders?
-- Business Context: Verifies staff operational involvement in sales transactions.
-- ----------------------------------------------------------------------------
-- Business Question: How many employees have processed orders?
-- SQL Query:
SELECT 
    COUNT(DISTINCT emp_id) AS employees_processed_orders,
    (SELECT COUNT(*) FROM employees) AS total_store_employees,
    CASE 
        WHEN COUNT(DISTINCT emp_id) = (SELECT COUNT(*) FROM employees) 
        THEN '100% Staff Active' 
        ELSE 'Partial Staff Active' 
    END AS staffing_utilization_status
FROM orders;


-- ----------------------------------------------------------------------------
-- Question 5.2: Which employees have handled the most orders?
-- Business Context: Measures employee order processing workload and throughput.
-- ----------------------------------------------------------------------------
-- Business Question: Which employees have handled the most orders?
-- SQL Query:
SELECT 
    e.emp_id,
    e.emp_name,
    COUNT(DISTINCT o.ord_id) AS total_orders_handled,
    COUNT(DISTINCT od.ord_id) AS active_sales_orders_handled,
    DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT o.ord_id) DESC) AS workload_rank
FROM employees e
INNER JOIN orders o ON e.emp_id = o.emp_id
LEFT JOIN order_details od ON o.ord_id = od.ord_id
GROUP BY e.emp_id, e.emp_name
ORDER BY total_orders_handled DESC, e.emp_id ASC;


-- ----------------------------------------------------------------------------
-- Question 5.3: What is the total sales value processed by each employee?
-- Business Context: Measures employee gross revenue generation at checkout.
-- ----------------------------------------------------------------------------
-- Business Question: What is the total sales value processed by each employee?
-- SQL Query:
SELECT 
    e.emp_id,
    e.emp_name,
    COUNT(DISTINCT o.ord_id) AS total_orders_handled,
    ROUND(COALESCE(SUM(od.total_price), 0), 2) AS total_sales_value_processed,
    ROUND(COALESCE(SUM(od.total_price), 0) * 100.0 / (SELECT SUM(total_price) FROM order_details), 2) AS revenue_share_pct
FROM employees e
INNER JOIN orders o ON e.emp_id = o.emp_id
LEFT JOIN order_details od ON o.ord_id = od.ord_id
GROUP BY e.emp_id, e.emp_name
ORDER BY total_sales_value_processed DESC;


-- ----------------------------------------------------------------------------
-- Question 5.4: What is the average order value handled per employee?
-- Business Context: Evaluates cashier upselling efficiency and basket size.
-- ----------------------------------------------------------------------------
-- Business Question: What is the average order value handled per employee?
-- SQL Query:
WITH employee_order_totals AS (
    SELECT 
        o.emp_id,
        o.ord_id,
        SUM(od.total_price) AS order_total
    FROM orders o
    INNER JOIN order_details od ON o.ord_id = od.ord_id
    GROUP BY o.emp_id, o.ord_id
)
SELECT 
    e.emp_id,
    e.emp_name,
    COUNT(eot.ord_id) AS active_orders_handled,
    ROUND(AVG(eot.order_total), 2) AS avg_order_value_handled
FROM employees e
INNER JOIN employee_order_totals eot ON e.emp_id = eot.emp_id
GROUP BY e.emp_id, e.emp_name
ORDER BY avg_order_value_handled DESC;



-- ============================================================================
-- SECTION 6: ORDER DETAILS DEEP DIVE
-- Explore item-level sales patterns and pricing behavior.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Question 6.1: What is the relationship between quantity ordered and total price?
-- Business Context: Computes statistical Pearson correlation without unsupported functions.
-- Formula: (N*SUM(xy) - SUM(x)*SUM(y)) / (SQRT(N*SUM(x^2)-(SUM(x))^2) * SQRT(N*SUM(y^2)-(SUM(y))^2))
-- ----------------------------------------------------------------------------
-- Business Question: What is the relationship between quantity ordered and total price?
-- SQL Query:
SELECT 
    ROUND(
        (COUNT(*) * SUM(quantity * total_price) - SUM(quantity) * SUM(total_price)) /
        (SQRT(COUNT(*) * SUM(quantity * quantity) - POW(SUM(quantity), 2)) *
         SQRT(COUNT(*) * SUM(total_price * total_price) - POW(SUM(total_price), 2))),
        4
    ) AS pearson_correlation_coefficient,
    'Strong positive linear relationship (r = 0.7226)' AS mathematical_interpretation,
    COUNT(*) AS total_sample_size_n
FROM order_details;


-- ----------------------------------------------------------------------------
-- Question 6.2: What is the average quantity ordered per product?
-- Business Context: Analyzes consumer purchasing batch sizes for inventory pack sizing.
-- ----------------------------------------------------------------------------
-- Business Question: What is the average quantity ordered per product?
-- SQL Query:
SELECT 
    p.prod_id,
    p.prod_name,
    ROUND(AVG(od.quantity), 2) AS avg_quantity_per_order,
    SUM(od.quantity) AS total_units_ordered,
    COUNT(od.ord_detID) AS order_line_occurrences,
    MIN(od.quantity) AS min_units_per_order,
    MAX(od.quantity) AS max_units_per_order
FROM products p
INNER JOIN order_details od ON p.prod_id = od.prod_id
GROUP BY p.prod_id, p.prod_name
ORDER BY avg_quantity_per_order DESC;


-- ----------------------------------------------------------------------------
-- Question 6.3: How does the unit price vary across products and orders?
-- Business Context: Audits price consistency between catalog and transacted prices.
-- ----------------------------------------------------------------------------
-- Business Question: How does the unit price vary across products and orders?
-- SQL Query:
SELECT 
    p.prod_id,
    p.prod_name,
    ROUND(p.price, 2) AS catalog_price,
    ROUND(MIN(od.each_price), 2) AS min_transacted_price,
    ROUND(MAX(od.each_price), 2) AS max_transacted_price,
    ROUND(AVG(od.each_price), 2) AS avg_transacted_price,
    ROUND(MAX(od.each_price) - MIN(od.each_price), 2) AS unit_price_variance_across_orders
FROM products p
INNER JOIN order_details od ON p.prod_id = od.prod_id
GROUP BY p.prod_id, p.prod_name, p.price
ORDER BY catalog_price DESC;


