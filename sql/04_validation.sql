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
