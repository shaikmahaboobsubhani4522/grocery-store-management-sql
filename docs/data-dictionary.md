# Grocery Store Management — Data Dictionary & Entity Reference

**Project:** Grocery Store Management SQL Database  
**Author / Database Architect:** Mahaboob Subhani Shaik  
**Database System:** MySQL 8.x  
**Storage Engine:** InnoDB  
**Character Set:** utf8mb4 | **Collation:** utf8mb4_unicode_ci  

---

## 1. Relational Schema Architecture

The database models a retail grocery store operations ecosystem across 7 normalized tables:

```
[supplier] (1) ─────────────< (M) [products] (1) ───────────< (M) [order_details]
                                      │                                 │
[categories] (1) ───────────< (M) ────┘                                 │
                                                                        │
[customers] (1) ────────────< (M) [orders] (1) ─────────────< (M) ──────┘
                                      │
[employees] (1) ────────────< (M) ────┘
```

---

## 2. Table Specifications & Attribute Dictionaries

### 2.1. Table: `supplier`
- **Purpose:** Stores business profile, contact name, and physical warehouse/state address of wholesale product vendors.
- **Row Count:** 5 records
- **Primary Source:** `Suppliers.csv`

| Column | Data Type | Nullable | Key | Constraints / Default | Description | Example |
| :--- | :--- | :---: | :---: | :--- | :--- | :--- |
| `sup_id` | `TINYINT` | No | PK | `AUTO_INCREMENT` | Unique identifier for supplier (Range: 1–5). | `1` |
| `sup_name` | `VARCHAR(255)` | No | - | - | Full business or commercial contact name. | `Aarav Sharma` |
| `address` | `TEXT` | Yes | - | - | Street, city, state, and country location. | `33 Main Street, Madhya Pradesh, India` |

---

### 2.2. Table: `categories`
- **Purpose:** Organizes inventory products into logical grocery retail departments.
- **Row Count:** 5 records
- **Primary Source:** `Categories.csv`

| Column | Data Type | Nullable | Key | Constraints / Default | Description | Example |
| :--- | :--- | :---: | :---: | :--- | :--- | :--- |
| `cat_id` | `TINYINT` | No | PK | `AUTO_INCREMENT` | Unique department code (Range: 1–5). | `1` |
| `cat_name` | `VARCHAR(255)` | No | - | - | Commercial grocery classification. | `Grains & Cereals` |

*Category Roster:*
1. Grains & Cereals (18 products)
2. Dairy Products (6 products)
3. Snacks & Confectioneries (17 products)
4. Personal Care (6 products)
5. Household (3 products)

---

### 2.3. Table: `employees`
- **Purpose:** Records store staff members, cashiers, and managers responsible for processing customer sales orders.
- **Row Count:** 10 records
- **Primary Source:** `Store_Employees.csv`

| Column | Data Type | Nullable | Key | Constraints / Default | Description | Example |
| :--- | :--- | :---: | :---: | :--- | :--- | :--- |
| `emp_id` | `TINYINT` | No | PK | `AUTO_INCREMENT` | Unique employee identifier (Range: 1–10). | `1` |
| `emp_name` | `VARCHAR(255)` | No | - | - | Employee full name. | `Aarav Kumar 1` |
| `hire_date` | `VARCHAR(255)` | No | - | - | Date hired in `M/D/YYYY` format. | `2/3/2021` |

---

### 2.4. Table: `customers`
- **Purpose:** Master directory of registered retail customers.
- **Row Count:** 200 records
- **Primary Source:** `Customers.csv`

| Column | Data Type | Nullable | Key | Constraints / Default | Description | Example |
| :--- | :--- | :---: | :---: | :--- | :--- | :--- |
| `cust_id` | `SMALLINT` | No | PK | `AUTO_INCREMENT` | Unique customer account number (Range: 1–200). | `1` |
| `cust_name` | `VARCHAR(255)` | No | - | - | Customer full legal/display name. | `Aditi Shetty` |
| `address` | `TEXT` | Yes | - | - | Delivery street and city address. | `37 Main Street, Bengaluru, India` |

---

### 2.5. Table: `products`
- **Purpose:** Inventory catalog items with supplier association, category tagging, and standard retail prices.
- **Row Count:** 50 records
- **Primary Source:** `Products.csv`

| Column | Data Type | Nullable | Key | Constraints / Default | Description | Example |
| :--- | :--- | :---: | :---: | :--- | :--- | :--- |
| `prod_id` | `TINYINT` | No | PK | `AUTO_INCREMENT` | Unique inventory item SKU (Range: 1–50). | `1` |
| `prod_name` | `VARCHAR(255)` | No | - | - | Consumer product name. | `Basmati Rice` |
| `sup_id` | `TINYINT` | No | FK | References `supplier(sup_id)` | Linked supplier vendor code. | `3` |
| `cat_id` | `TINYINT` | No | FK | References `categories(cat_id)` | Linked retail department code. | `1` |
| `price` | `DECIMAL(10,2)` | No | - | `CHECK (price >= 0)` | Standard catalog unit retail price (INR). | `358.98` |

---

### 2.6. Table: `orders`
- **Purpose:** Transactional header records logging customer order events, assigned fulfillment staff, and transaction dates.
- **Row Count:** 300 records
- **Primary Source:** `Orders.csv`

| Column | Data Type | Nullable | Key | Constraints / Default | Description | Example |
| :--- | :--- | :---: | :---: | :--- | :--- | :--- |
| `ord_id` | `SMALLINT` | No | PK | `AUTO_INCREMENT` | Unique order transaction ID (Range: 1–300). | `1` |
| `cust_id` | `SMALLINT` | No | FK | References `customers(cust_id)` | Customer placing the order. | `197` |
| `emp_id` | `TINYINT` | No | FK | References `employees(emp_id)` | Staff member fulfilling the order. | `5` |
| `order_date` | `VARCHAR(255)` | No | - | - | Transaction date in `M/D/YYYY` format. | `1/30/2022` |

---

### 2.7. Table: `order_details`
- **Purpose:** Itemized line-item receipts detailing individual products purchased, units ordered, unit price, and extended subtotal.
- **Row Count:** 600 records
- **Primary Source:** `OrderDetails.csv`

| Column | Data Type | Nullable | Key | Constraints / Default | Description | Example |
| :--- | :--- | :---: | :---: | :--- | :--- | :--- |
| `ord_detID` | `SMALLINT` | No | PK | `AUTO_INCREMENT` | Unique receipt line item ID (Range: 1–600). | `1` |
| `ord_id` | `SMALLINT` | No | FK | References `orders(ord_id)` | Associated order transaction header. | `109` |
| `prod_id` | `TINYINT` | No | FK | References `products(prod_id)` | Item purchased SKU. | `23` |
| `quantity` | `TINYINT` | No | - | `CHECK (quantity > 0)` | Quantity of units purchased (Range: 1–5). | `3` |
| `each_price` | `DECIMAL(10,2)` | No | - | `CHECK (each_price >= 0)` | Transaction unit price at sale. | `140.62` |
| `total_price` | `DECIMAL(10,2)` | No | - | `CHECK (total_price >= 0)` | Extended line total (`quantity * each_price`). | `421.87` |

---

## 3. Referential Integrity & Foreign Key Cascade Rules

All foreign keys are configured with `ON UPDATE CASCADE ON DELETE CASCADE`:

| Source Table | Foreign Key | Target Table | Target Key | Cascade Behavior | Business Justification |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `products` | `sup_id` | `supplier` | `sup_id` | `CASCADE` | If a supplier ID changes, all associated catalog items update automatically. |
| `products` | `cat_id` | `categories` | `cat_id` | `CASCADE` | Category re-keying reflects immediately across inventory items. |
| `orders` | `cust_id` | `customers` | `cust_id` | `CASCADE` | Order transaction logs follow customer account ID lifecycle. |
| `orders` | `emp_id` | `employees` | `emp_id` | `CASCADE` | Employee ID updates propagate to fulfillment transaction records. |
| `order_details` | `ord_id` | `orders` | `ord_id` | `CASCADE` | Deleting an order header cleanly purges all its itemized receipt lines. |
| `order_details` | `prod_id` | `products` | `prod_id` | `CASCADE` | Line items remain synchronized with catalog SKU identity updates. |

---

## 4. Key Architectural & Implementation Decisions

### 4.1. AUTO_INCREMENT Strategy
- **Requirement:** The PDF states on Page 5: *"Add auto increment constraint in all the table’s primary keys."*
- **Implementation:** The validated source IDs will be explicitly inserted into `AUTO_INCREMENT` columns to preserve the original relational IDs. In MySQL InnoDB, supplying explicit non-null values during `INSERT` or `LOAD DATA` preserves the source primary keys exactly and advances the internal sequence counter to `MAX(id) + 1`. This satisfies the assignment requirement while maintaining referential integrity across all tables.

### 4.2. Date Column Typing & Handling
- **Requirement:** The PDF specifies `VARCHAR(255)` for `hire_date` and `order_date`.
- **Implementation:** Columns are created as `VARCHAR(255)` to ensure strict compatibility with direct assignment instructions. Analytical queries employ MySQL's `STR_TO_DATE(order_date, '%m/%d/%Y')` function to perform date arithmetic, monthly groupings, and weekday-weekend classification.

### 4.3. MySQL-Compatible Pearson Correlation (Section 6, Question 1)
- **Problem:** `SQL_project(1).sql` attempts to use `corr(quantity, total_price)`, which is not supported in MySQL.
- **Implementation:** Standard Pearson correlation coefficient formula implemented using MySQL aggregation functions:
  $$\rho = \frac{N \sum(xy) - \sum(x)\sum(y)}{\sqrt{\left[N \sum(x^2) - (\sum x)^2\right] \left[N \sum(y^2) - (\sum y)^2\right]}}$$
  Yielding the verified result: **r = +0.7226**.

---

## 5. Authoritative Assignment Questions Mapping (25 Total Questions)

Mapped directly from the official project PDF specification:

### Section 1: Customer Insights (4 Questions)
1. **Q1.1:** How many unique customers have placed orders?
2. **Q1.2:** Which customers have placed the highest number of orders?
3. **Q1.3:** What is the total and average purchase value per customer?
4. **Q1.4:** Who are the top 5 customers by total purchase amount?

### Section 2: Product Performance (5 Questions)
5. **Q2.1:** How many products exist in each category?
6. **Q2.2:** What is the average price of products by category?
7. **Q2.3:** Which products have the highest total sales volume (by quantity)?
8. **Q2.4:** What is the total revenue generated by each product?
9. **Q2.5:** How do product sales vary by category and supplier?

### Section 3: Sales and Order Trends (5 Questions)
10. **Q3.1:** How many orders have been placed in total?
11. **Q3.2:** What is the average value per order?
12. **Q3.3:** On which dates were the most orders placed?
13. **Q3.4:** What are the monthly trends in order volume and revenue?
14. **Q3.5:** How do order patterns vary across weekdays and weekends?

### Section 4: Supplier Contribution (4 Questions)
15. **Q4.1:** How many suppliers are there in the database?
16. **Q4.2:** Which supplier provides the most products?
17. **Q4.3:** What is the average price of products from each supplier?
18. **Q4.4:** Which suppliers contribute the most to total product sales (by revenue)?

### Section 5: Employee Performance (4 Questions)
19. **Q5.1:** How many employees have processed orders?
20. **Q5.2:** Which employees have handled the most orders?
21. **Q5.3:** What is the total sales value processed by each employee?
22. **Q5.4:** What is the average order value handled per employee?

### Section 6: Order Details Deep Dive (3 Questions)
23. **Q6.1:** What is the relationship between quantity ordered and total price?
24. **Q6.2:** What is the average quantity ordered per product?
25. **Q6.3:** How does the unit price vary across products and orders?
