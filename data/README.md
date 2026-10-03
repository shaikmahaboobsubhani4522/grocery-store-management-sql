# Grocery Store Management — Dataset Documentation

## Overview

This directory contains the authoritative raw CSV datasets for the **Grocery Store Management SQL Project**. The data simulates the transactional and operational database of a retail grocery business, capturing supplier relations, product inventory, customer demographics, employee staffing, and retail customer orders with itemized sales receipts.

---

## Dataset Inventory & Summary

| File Name | Target SQL Table | Row Count | Attributes | Primary Key | Description |
| :--- | :--- | :---: | :---: | :--- | :--- |
| **`Suppliers.csv`** | `supplier` | 5 | 3 | `SupplierID` (1–5) | Stores distributor information and regional warehouse addresses across India. |
| **`Categories.csv`** | `categories` | 5 | 2 | `CategoryID` (1–5) | Product department classifications (Grains, Dairy, Snacks, Personal Care, Household). |
| **`Store_Employees.csv`** | `employees` | 10 | 3 | `EmployeeID` (1–10) | Store cashier and sales staff responsible for order intake and customer fulfillment. |
| **`Customers.csv`** | `customers` | 200 | 3 | `CustomerID` (1–200) | Registered grocery customers with billing/shipping addresses. |
| **`Products.csv`** | `products` | 50 | 5 | `ProductID` (1–50) | Complete inventory catalog items linked to their category and primary supplier. |
| **`Orders.csv`** | `orders` | 300 | 4 | `OrderID` (1–300) | Order transaction headers linking customers, handling employees, and timestamps. |
| **`OrderDetails.csv`** | `order_details` | 600 | 6 | `OrderDetailID` (1–600) | Itemized receipt lines with unit price, order quantity, and line-item total price. |

---

## Critical Data Audit Findings

A rigorous technical audit conducted during Phase 1 established the following authoritative dataset properties:

1. **Strict Referential Integrity (Zero Orphans):**
   - 100% of product category and supplier references match existing parent records.
   - 100% of order customer and employee references match existing registered profiles.
   - 100% of order detail lines match existing orders and catalog products.

2. **100% Arithmetic Precision:**
   - For all 600 line items in `OrderDetails.csv`, `TotalPrice == Quantity * PriceEach` holds with zero discrepancy.
   - Unit prices (`PriceEach`) in `OrderDetails.csv` match catalog prices (`Price`) in `Products.csv` for 100% of records.

3. **Critical Business Nuance — 44 Orders with No Line Items:**
   - Out of **300 logged orders**, exactly **44 orders have no itemized records** in `OrderDetails.csv`.
   - Exactly **256 orders have recorded sales**, generating a combined gross revenue of **₹551,330.00**.
   - These 44 orders represent unfulfilled, abandoned, or zero-item transaction logs. Analytical queries must differentiate between **all placed orders (300)** and **orders with fulfilled sales (256)** to prevent metric distortion.

4. **Customer Order Participation Nuance:**
   - **156 unique customers** placed orders in `Orders.csv` (out of 200 registered customer profiles).
   - Only **141 unique customers** have orders with fulfilled line items in `OrderDetails.csv` (15 customers only placed orders that resulted in zero line items).

5. **Date Representation & Chronology:**
   - Dates are formatted as `M/D/YYYY` strings (e.g., `1/30/2022`, `11/12/2021`).
   - `Store_Employees.csv`: Staff hire dates span **August 2020 to November 2021**.
   - `Orders.csv`: Order placement dates span **January 1, 2022 to December 30, 2022** (a complete 12-month calendar year).

---

## Column Mapping Specification

The raw CSV files utilize `PascalCase` headers, whereas the normalized relational database utilizes standard SQL `snake_case`. The import pipeline (`sql/03_import_data.sql`) handles this mapping explicitly:

| Raw CSV File | Raw CSV Header | Target Table | Target SQL Column | Data Type |
| :--- | :--- | :--- | :--- | :--- |
| `Suppliers.csv` | `SupplierID`<br>`SupplierName`<br>`Address` | `supplier` | `sup_id`<br>`sup_name`<br>`address` | `TINYINT`<br>`VARCHAR(255)`<br>`TEXT` |
| `Categories.csv` | `CategoryID`<br>`CategoryName` | `categories` | `cat_id`<br>`cat_name` | `TINYINT`<br>`VARCHAR(255)` |
| `Store_Employees.csv` | `EmployeeID`<br>`Name`<br>`HireDate` | `employees` | `emp_id`<br>`emp_name`<br>`hire_date` | `TINYINT`<br>`VARCHAR(255)`<br>`VARCHAR(255)` |
| `Customers.csv` | `CustomerID`<br>`Name`<br>`Address` | `customers` | `cust_id`<br>`cust_name`<br>`address` | `SMALLINT`<br>`VARCHAR(255)`<br>`TEXT` |
| `Products.csv` | `ProductID`<br>`Name`<br>`SupplierID`<br>`CategoryID`<br>`Price` | `products` | `prod_id`<br>`prod_name`<br>`sup_id`<br>`cat_id`<br>`price` | `TINYINT`<br>`VARCHAR(255)`<br>`TINYINT`<br>`TINYINT`<br>`DECIMAL(10,2)` |
| `Orders.csv` | `OrderID`<br>`CustomerID`<br>`EmployeeID`<br>`OrderDate` | `orders` | `ord_id`<br>`cust_id`<br>`emp_id`<br>`order_date` | `SMALLINT`<br>`SMALLINT`<br>`TINYINT`<br>`VARCHAR(255)` |
| `OrderDetails.csv` | `OrderDetailID`<br>`OrderID`<br>`ProductID`<br>`Quantity`<br>`PriceEach`<br>`TotalPrice` | `order_details` | `ord_detID`<br>`ord_id`<br>`prod_id`<br>`quantity`<br>`each_price`<br>`total_price` | `SMALLINT`<br>`SMALLINT`<br>`TINYINT`<br>`TINYINT`<br>`DECIMAL(10,2)`<br>`DECIMAL(10,2)` |

---

## Privacy & Sensitivity Verification

This dataset has been verified to contain **100% synthetic/dummy educational data**:
- Names are generated combinations of Indian first and last names (*Aditi Shetty*, *Aarav Sharma*, *Pari Kumar 1*).
- Addresses are generic fictional street numbers (*"37 Main Street, Bengaluru, India"*).
- The dataset contains **no personal email addresses, phone numbers, passwords, financial account numbers, API keys, or private identifiers**.
- It is fully sanitized, public-safe, and appropriate for GitHub portfolio publication.
