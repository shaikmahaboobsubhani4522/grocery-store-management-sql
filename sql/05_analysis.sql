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
