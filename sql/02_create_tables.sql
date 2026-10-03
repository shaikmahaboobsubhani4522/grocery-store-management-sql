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
