# Phase 1: Requirements and Data Audit Report

**Project:** Grocery Store Management SQL Project  
**Author / Data Lead:** Mahaboob Subhani Shaik  
**Role:** Senior SQL Developer, Database Architect & Data Analyst  
**Audit Date:** October 2026  
**Status:** Completed & Ready for Review  

---

## 1. Executive Summary

This audit establishes the rigorous technical foundation and single source of truth for the **Grocery Store Management** database and portfolio analytics project.

The audit analyzed:
1. The official project requirements specification (`Grocery_Store_Managment.pdf`).
2. The complete raw datasets (`Categories.csv`, `Customers.csv`, `OrderDetails.csv`, `Orders.csv`, `Products.csv`, `Store_Employees.csv`, `Suppliers.csv`) retrieved directly from the project source repository.
3. The existing reference SQL file (`SQL_project(1).sql`) and current local project workspace files.

### Key Audit Findings:
- **100% Referential Integrity:** Every foreign key in child tables references an existing parent primary key (zero orphan records across all 7 entities).
- **100% Mathematical Consistency:** `TotalPrice` in `OrderDetails.csv` exactly equals `Quantity * PriceEach` across all 600 records with zero mismatches.
- **Identical Catalog Pricing:** `PriceEach` in `OrderDetails.csv` matches the catalog `Price` in `Products.csv` for 100% of rows (no dynamic pricing or unrecorded discounts).
- **Critical Business Data Nuance Discovered:** Out of 300 orders in `Orders.csv`, exactly **44 orders have no line items** in `OrderDetails.csv`. Only **256 orders have recorded sales**. This is critical for calculating average order values, customer spend, and monthly trends without distorted metrics.
- **Customer Participation Nuance:** 156 distinct customers placed orders in `Orders.csv`, but only 141 customers have orders containing line items in `OrderDetails.csv` (15 customers placed orders that were unfulfilled or empty).
- **Discrepancy in Reference SQL:** `SQL_project(1).sql` attempts to use `corr(quantity, total_price)` in Section 6 Q1. `corr()` **does not exist in MySQL 8** and causes a runtime syntax error. A standard Pearson correlation formula must be implemented.
- **Column Name Discrepancy:** The CSV headers use `PascalCase` (`CustomerID`, `PriceEach`, `TotalPrice`, `SupplierName`, etc.), whereas the project DDL and SQL schema use `snake_case` (`cust_id`, `each_price`, `total_price`, `sup_name`, etc.). MySQL import routines must map these explicitly.
- **Privacy & Security Audit Passed:** All customer, supplier, and employee records contain synthetic Indian names and dummy street addresses. There are no actual emails, phone numbers, passwords, financial tokens, or PII. The dataset is safe for a public GitHub portfolio repository.

---

## 2. Table Requirements & Entity Specifications

The project requires exactly seven interrelated relational tables:

| Table Name | Entity Description | Primary Key | Foreign Keys | Row Count |
| :--- | :--- | :--- | :--- | :--- |
| **`supplier`** | Stores supplier business details and locations | `sup_id` (TINYINT) | None | 5 |
| **`categories`** | Product category classifications | `cat_id` (TINYINT) | None | 5 |
| **`employees`** | Store staff handling customer orders | `emp_id` (TINYINT) | None | 10 |
| **`customers`** | Customer contact profiles and addresses | `cust_id` (SMALLINT) | None | 200 |
| **`products`** | Product catalog items, prices, and categories | `prod_id` (TINYINT) | `sup_id` → `supplier(sup_id)`<br>`cat_id` → `categories(cat_id)` | 50 |
| **`orders`** | Order placement logs linking customer and employee | `ord_id` (SMALLINT) | `cust_id` → `customers(cust_id)`<br>`emp_id` → `employees(emp_id)` | 300 |
| **`order_details`** | Line items for each order (product, quantity, price) | `ord_detID` (SMALLINT) | `ord_id` → `orders(ord_id)`<br>`prod_id` → `products(prod_id)` | 600 |

### Relational Schema Diagram & Cardinalities
```
    [supplier] (1) ─────────────< (M) [products] (1) ───────────< (M) [order_details]
                                          │                                 │
    [categories] (1) ───────────< (M) ────┘                                 │
                                                                            │
    [customers] (1) ────────────< (M) [orders] (1) ─────────────< (M) ──────┘
                                          │
    [employees] (1) ────────────< (M) ────┘
```

- **supplier → products:** One-to-Many (`ON UPDATE CASCADE ON DELETE CASCADE`)
- **categories → products:** One-to-Many (`ON UPDATE CASCADE ON DELETE CASCADE`)
- **products → order_details:** One-to-Many (`ON UPDATE CASCADE ON DELETE CASCADE`)
- **orders → order_details:** One-to-Many (`ON UPDATE CASCADE ON DELETE CASCADE`)
- **customers → orders:** One-to-Many (`ON UPDATE CASCADE ON DELETE CASCADE`)
- **employees → orders:** One-to-Many (`ON UPDATE CASCADE ON DELETE CASCADE`)

---

## 3. CSV Dataset Structural Audit

Detailed inspection of the 7 raw CSV files downloaded from the source repository:

### 3.1. `Suppliers.csv`
- **File Size:** 282 bytes | **Rows:** 5 | **Columns:** 3
- **Headers:** `SupplierID`, `SupplierName`, `Address`
- **Null Values:** 0
- **PK Analysis:** `SupplierID` values 1 to 5 (strictly unique, non-null)
- **Sample Record:** `1, Aarav Sharma, "33 Main Street, Madhya Pradesh, India"`

### 3.2. `Categories.csv`
- **File Size:** 119 bytes | **Rows:** 5 | **Columns:** 2
- **Headers:** `CategoryID`, `CategoryName`
- **Null Values:** 0
- **PK Analysis:** `CategoryID` values 1 to 5 (strictly unique, non-null)
- **Categories:** Grains & Cereals, Dairy Products, Snacks & Confectioneries, Personal Care, Household

### 3.3. `Store_Employees.csv`
- **File Size:** 296 bytes | **Rows:** 10 | **Columns:** 3
- **Headers:** `EmployeeID`, `Name`, `HireDate`
- **Null Values:** 0
- **PK Analysis:** `EmployeeID` values 1 to 10 (strictly unique, non-null)
- **Date Format:** `%m/%d/%Y` (e.g., `2/3/2021`, `8/26/2020`). All hire dates occur in 2020 and 2021.
- **Sample Record:** `1, Aarav Kumar 1, 2/3/2021`

### 3.4. `Customers.csv`
- **File Size:** 10,344 bytes | **Rows:** 200 | **Columns:** 3
- **Headers:** `CustomerID`, `Name`, `Address`
- **Null Values:** 0
- **PK Analysis:** `CustomerID` values 1 to 200 (strictly unique, non-null)
- **Sample Record:** `1, Aditi Shetty, "37 Main Street, Bengaluru, India"`

### 3.5. `Products.csv`
- **File Size:** 1,607 bytes | **Rows:** 50 | **Columns:** 5
- **Headers:** `ProductID`, `Name`, `SupplierID`, `CategoryID`, `Price`
- **Null Values:** 0
- **PK Analysis:** `ProductID` values 1 to 50 (strictly unique, non-null)
- **FK Validation:**
  - `SupplierID` values range from 1 to 5 → 100% match `Suppliers.csv` (0 orphans).
  - `CategoryID` values range from 1 to 5 → 100% match `Categories.csv` (0 orphans).
- **Price Range:** Min ₹89.52 (Potato Chips) to Max ₹499.57 (Brown Rice); Average ₹308.02.

### 3.6. `Orders.csv`
- **File Size:** 6,101 bytes | **Rows:** 300 | **Columns:** 4
- **Headers:** `OrderID`, `CustomerID`, `EmployeeID`, `OrderDate`
- **Null Values:** 0
- **PK Analysis:** `OrderID` values 1 to 300 (strictly unique, non-null)
- **FK Validation:**
  - `CustomerID` values range from 1 to 200 → 100% match `Customers.csv` (0 orphans).
  - `EmployeeID` values range from 1 to 10 → 100% match `Store_Employees.csv` (0 orphans).
- **Date Format:** `%m/%d/%Y` (e.g., `1/30/2022`, `12/30/2022`).
- **Date Range:** January 1, 2022 to December 30, 2022 (full calendar year 2022).

### 3.7. `OrderDetails.csv`
- **File Size:** 29,590 bytes | **Rows:** 600 | **Columns:** 6
- **Headers:** `OrderDetailID`, `OrderID`, `ProductID`, `Quantity`, `PriceEach`, `TotalPrice`
- **Null Values:** 0
- **PK Analysis:** `OrderDetailID` values 1 to 600 (strictly unique, non-null)
- **FK Validation:**
  - `OrderID` values range from 2 to 300 → 100% match `Orders.csv` (0 orphans).
  - `ProductID` values range from 1 to 50 → 100% match `Products.csv` (0 orphans).
- **Quantity Range:** Min 1, Max 5; Average quantity = 3.01 units per line item.
- **Financial Cross-Check:**
  - `PriceEach == Products.Price`: 600 out of 600 match (100% consistency).
  - `TotalPrice == Quantity * PriceEach`: 600 out of 600 match (100% consistency).

---

## 4. Discrepancy & Resolution Matrix

| Issue Area | Requirements PDF | CSV Datasets | Reference SQL (`SQL_project(1).sql`) | Resolved Architecture |
| :--- | :--- | :--- | :--- | :--- |
| **Table 7 Name** | Typo on Page 2 lists Table 7 as `j`, but DDL specifies `order_details`. | File is named `OrderDetails.csv`. | Named `order_details`. | **`order_details`** (matches relational convention and DDL). |
| **File Names** | Mentions generic table names. | `Categories.csv`, `Suppliers.csv`, `Store_Employees.csv`, `Customers.csv`, `Products.csv`, `Orders.csv`, `OrderDetails.csv`. | N/A | Documented exact filenames in `03_import_data.sql`. |
| **Column Names** | Specifies snake_case (`cust_id`, `each_price`, `total_price`, etc.). | Uses PascalCase (`CustomerID`, `PriceEach`, `TotalPrice`, etc.). | Uses snake_case. | Keep clean snake_case schema; map PascalCase CSV columns during `LOAD DATA` or `INSERT`. |
| **Primary Keys & AUTO_INCREMENT** | Page 5 states: *"Add auto increment constraint in all table's primary keys"*. | All tables already have pre-assigned, clean integer IDs (1..N). | Only `order_details` has `AUTO_INCREMENT`. | Add `AUTO_INCREMENT` to primary keys while allowing explicit CSV ID values during import. |
| **Date Column Types** | Page 3 specifies `VARCHAR(255)` for `order_date` and `hire_date`. | Strings in `M/D/YYYY` format. | Stores as `VARCHAR(255)` and repeatedly uses `STR_TO_DATE(order_date, '%m/%d/%Y')`. | Support standard `VARCHAR(255)` with `STR_TO_DATE()` for strict assignment adherence, and provide clean `DATE` migration script for production best practices. |
| **Section 6 Q1 Query** | *"What is the relationship between quantity ordered and total price?"* | Correlation between `Quantity` and `TotalPrice` is **+0.7226**. | Uses `corr(quantity, total_price)`, which fails in MySQL 8. | Implement MySQL-compliant Pearson correlation formula and grouped price-quantity distribution. |
| **Missing Order Line Items** | Not mentioned. | 44 orders in `Orders.csv` have no line items in `OrderDetails.csv`. | Query uses `INNER JOIN`, silently dropping 44 orders. | Explicitly report both metrics (total orders vs orders with fulfilled line items) with clear analyst commentary. |
| **Customer Order Count** | *"How many unique customers have placed orders?"* | 156 customers placed orders; 141 have orders with items. | Counts `DISTINCT cust_id` from `Orders` (= 156). | Output 156 as primary answer; document 141 as customers with confirmed item fulfillments. |
| **Customer Average Spend** | *"What is the total and average purchase value per customer?"* | Active customers spend an average of ₹3,651.19 total across orders. | Calculates `AVG(od.total_price)` which is average line item (₹918.88), not average purchase value per customer! | Calculate total spend per customer AND average spend per order / per customer properly. |

---

## 5. Verified Analysis Ground Truth (23 Business Questions)

The exact answers have been computed directly from the source dataset:

### Section 1 — Customer Insights
1. **Unique customers who placed orders:** **156** unique customers in `Orders` (out of 200 registered). 141 customers have fulfilled line items.
2. **Customers with highest order count:**
   - `CustomerID 103` (Pari Kumar): 5 orders
   - `CustomerID 14` (Aarav Verma): 4 orders
   - `CustomerID 19` (Chetan Naidu): 4 orders
   - `CustomerID 61` (Aditi Rao): 4 orders
   - `CustomerID 63` (Diya Iyer): 4 orders
   - `CustomerID 166` (Kapila): 4 orders
   - `CustomerID 7` (Eshwar Iyer): 4 orders
3. **Total & Average purchase value per customer:**
   - Overall average total spend per active customer: **₹3,910.14** (₹551,330 / 141)
   - Highest total spender: Chetan Naidu (₹11,256.81 across 4 orders, avg ₹2,814.20/order)
4. **Top 5 customers by total purchase amount:**
   1. `CustomerID 19` - Chetan Naidu: ₹11,256.81
   2. `CustomerID 166` - Kapila: ₹11,099.52
   3. `CustomerID 67` - Eshwar Rao: ₹10,819.97
   4. `CustomerID 61` - Aditi Rao: ₹10,230.65
   5. `CustomerID 7` - Eshwar Iyer: ₹9,188.46

### Section 2 — Product Performance
1. **Product count per category:**
   - Grains & Cereals: 18 products
   - Snacks & Confectioneries: 17 products
   - Dairy Products: 6 products
   - Personal Care: 6 products
   - Household: 3 products
   *(Total: 50 products)*
2. **Average product price by category:**
   - Dairy Products: ₹366.94
   - Personal Care: ₹364.99
   - Household: ₹363.34
   - Grains & Cereals: ₹287.67
   - Snacks & Confectioneries: ₹278.89
3. **Top products by sales volume (quantity sold):**
   1. Bath Soap (`ProductID 32`): 60 units
   2. Hand Sanitizer (`ProductID 33`): 56 units
   3. Biscuits (`ProductID 48`): 54 units
   4. Dishwashing Soap (`ProductID 27`): 54 units
   5. Potato Chips (`ProductID 46`): 54 units
4. **Top products by revenue generated:**
   1. Hand Sanitizer (`ProductID 33`): ₹27,787.74
   2. Biscuits (`ProductID 48`): ₹20,995.92
   3. Moong Dal (`ProductID 3`): ₹19,695.00
   4. Toothpaste (`ProductID 31`): ₹19,688.92
   5. Mustard Seeds (`ProductID 22`): ₹19,516.68
5. **Product sales by Category & Supplier:**
   - Top Category-Supplier pair by revenue: *Personal Care* supplied by *Aarya* (205 units, ₹69,378.34).
   - Second: *Grains & Cereals* supplied by *Aarya* (226 units, ₹67,701.12).

### Section 3 — Sales & Order Trends
1. **Total orders placed:** **300 orders**
2. **Average value per order:**
   - Across active orders with line items (256 orders): **₹2,153.63** (Total Store Revenue: **₹551,330.00**)
   - Across all 300 logged orders: **₹1,837.77**
3. **Dates with the most orders:**
   - `2022-03-30`: 4 orders
   - `2022-09-10`: 4 orders
   - `2022-01-14`: 3 orders
   - `2022-01-16`: 3 orders
   - `2022-01-28`: 3 orders
4. **Monthly trends in order volume & revenue (2022):**
   - Peak revenue month: **January 2022** (30 orders, ₹70,312.49)
   - Second highest revenue: **February 2022** (28 orders, ₹66,929.43)
   - Highest order volume: **December 2022** (32 orders, ₹60,903.12)
   - Lowest revenue month: **October 2022** (12 orders, ₹25,917.34)
5. **Weekday vs Weekend order patterns:**
   - Weekdays (Mon–Fri): 183 active orders (71.5%), ₹390,922.57 revenue, Average order value ₹2,136.19
   - Weekends (Sat–Sun): 73 active orders (28.5%), ₹160,407.43 revenue, Average order value ₹2,197.36
   - *Insight:* Weekends produce slightly higher average basket sizes (+2.9%) despite fewer total shopping days.

### Section 4 — Supplier Contribution
1. **Total suppliers:** **5 suppliers**
2. **Supplier providing the most products:**
   - `SupplierID 3` (Aarya): **18 products** (36% of catalog)
   - `SupplierID 4` (Suresh): 10 products
   - `SupplierID 2` (Sai): 10 products
   - `SupplierID 5` (Karthik): 9 products
   - `SupplierID 1` (Aarav Sharma): 3 products
3. **Average product price from each supplier:**
   - Sai: ₹342.67
   - Aarya: ₹319.33
   - Karthik: ₹288.23
   - Suresh: ₹281.82
   - Aarav Sharma: ₹271.37
4. **Suppliers contributing most to total sales revenue:**
   1. `Aarya`: **₹221,137.80** (40.1% of total revenue)
   2. `Sai`: ₹113,588.54 (20.6%)
   3. `Suresh`: ₹101,688.84 (18.4%)
   4. `Karthik`: ₹81,861.93 (14.8%)
   5. `Aarav Sharma`: ₹33,052.89 (6.0%)

### Section 5 — Employee Performance
1. **Employees processing orders:** **10 out of 10** employees are active.
2. **Employees handling the most orders:**
   - `EmployeeID 8` (Diya Sharma 1): **38 orders**
   - `EmployeeID 2` (Aditya Singh 1): **37 orders**
   - `EmployeeID 9` (Arjun Kumar 1): **32 orders**
   - `EmployeeID 3` (Pari Kumar 1): **31 orders**
   - `EmployeeID 5` (Pari Sharma 1): **31 orders**
3. **Total sales value processed per employee:**
   1. `Aditya Singh 1`: **₹79,252.27**
   2. `Zara Verma 1`: ₹71,562.78
   3. `Diya Sharma 1`: ₹67,241.86
   4. `Pari Kumar 1`: ₹66,818.38
   5. `Arjun Kumar 1`: ₹54,018.35
4. **Average order value handled per employee:**
   1. `Aarav Kumar 1`: **₹2,768.57** (23 orders)
   2. `Zara Verma 1`: **₹2,650.47** (30 orders)
   3. `Aditya Singh 1`: **₹2,330.95** (37 orders)

### Section 6 — Order Details Deep Dive
1. **Relationship between quantity ordered and total price:**
   - Strong positive linear correlation: **r = 0.7226**
   - As purchase quantity increases from 1 to 5, total line-item price rises predictably across all product categories.
2. **Average quantity ordered per product:**
   - Highest average quantity: **Butter** (4.56 units/order across 9 orders)
   - Second highest: **Toothpaste** (3.67 units/order across 12 orders)
   - Lowest average quantity: **Soybean Oil** (1.64 units/order across 11 orders)
3. **Unit price variance across products & orders:**
   - Variance within individual products across orders: **₹0.00** (Every product sold at its exact fixed catalog price).
   - Variance across the catalog: Minimum unit price ₹89.52 to maximum unit price ₹499.57.

---

## 6. Proposed Project Architecture (Phase 2 Roadmap)

```
Grocery-store-management/
│
├── README.md                           <-- Professional GitHub portfolio presentation & documentation
├── .gitignore                          <-- Standard OS, IDE, temporary, and credential ignores
│
├── data/                               <-- Data directory
│   ├── README.md                       <-- Data dictionary, provenance, and import guide
│   ├── Categories.csv                  <-- Verified source data (5 rows)
│   ├── Customers.csv                   <-- Verified source data (200 rows)
│   ├── OrderDetails.csv                <-- Verified source data (600 rows)
│   ├── Orders.csv                      <-- Verified source data (300 rows)
│   ├── Products.csv                    <-- Verified source data (50 rows)
│   ├── Store_Employees.csv             <-- Verified source data (10 rows)
│   └── Suppliers.csv                   <-- Verified source data (5 rows)
│
├── sql/                                <-- Modular, executable SQL pipeline
│   ├── 01_create_database.sql          <-- Database initialization & charset configuration
│   ├── 02_create_tables.sql            <-- DDL with PK, FK, and CASCADE constraints
│   ├── 03_import_data.sql              <-- Cross-platform LOAD DATA / INSERT scripts
│   ├── 04_validation.sql               <-- Integrity checks, orphan scans, count audits
│   └── 05_analysis.sql                 <-- 23 business queries categorized into 6 sections
│
├── docs/                               <-- Detailed technical documentation
│   ├── requirements-audit.md           <-- Phase 1 complete audit report (this document)
│   ├── data-dictionary.md              <-- Complete schema metadata & column specifications
│   ├── data-quality-report.md          <-- Automated validation results & anomaly analysis
│   ├── query-validation.md             <-- Query execution logs & performance details
│   └── analysis-results.md             <-- Business findings, tables, and executive insights
│
├── diagrams/                           <-- Architecture & schema visualization
│   ├── er-diagram.png                  <-- High-resolution visual ER diagram
│   └── er-diagram.mermaid              <-- Mermaid source definition
│
├── presentation/                       <-- Presentation deck
│   ├── Grocery_Store_Management.pptx   <-- 14-slide executive presentation
│   └── presentation-guide.md           <-- Slide-by-slide speaker notes for interviews
│
└── final_submission/                   <-- Clean assignment deliverables
    ├── Grocery_Store_Management.sql    <-- Consolidated, turnkey SQL script
    └── Grocery_Store_Management.pptx   <-- Completed assignment presentation
```

---

## 7. Next Steps for Phase 2 Approval

Upon your approval, we will proceed immediately to:
1. **Phase 2:** Clean up the folder structure, remove empty directory artifacts, and organize directories.
2. **Phase 3 & 4:** Build the clean DDL (`01_create_database.sql`, `02_create_tables.sql`) and robust import pipeline (`03_import_data.sql`).
3. **Phase 5 & 6:** Write validation scripts and production-grade MySQL 8 analysis queries with real results.
