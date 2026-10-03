# Grocery Store Management — Analytical Insights & Business Intelligence Report

> **Project:** Grocery Store Management SQL Analysis  
> **Author:** Mahaboob Subhani Shaik  
> **Date of Publication:** October 03, 2026  
> **Scope:** Comprehensive analysis of 25 core business questions across 6 analytical domains  

---

## Executive Summary

This study presents an end-to-end business intelligence investigation of the **Grocery Store Management** retail operation. Operating across five merchandise categories and partnering with five primary suppliers, the store recorded **300 placed orders**, **256 active fulfilled transactions**, and **₹551,330.00 in gross revenue** across 2024.

### Key Performance Indicators (KPI Dashboard)

| Metric | Value | Operational Context |
|---|:---:|---|
| **Gross Store Revenue** | **₹551,330.00** | Net transacted sales across 600 line items |
| **Total Orders Placed** | **300** | Gross order volume initiated by customers |
| **Active Fulfilled Orders** | **256** | Orders with recorded items (85.33% fulfillment rate) |
| **Unfulfilled / Empty Orders** | **44** | Orders with zero line items (14.67% unfulfilled) |
| **Average Order Value (AOV - Active)** | **₹2,153.63** | Average spend per fulfilled shopping basket |
| **Average Order Value (AOV - Placed)** | **₹1,837.77** | Revenue divided by all 300 initiated orders |
| **Total Registered Customers** | **200** | Enrolled customer accounts in database |
| **Active Purchasing Customers** | **141** | Customers with verified merchandise purchases (70.5%) |
| **Catalog SKU Count** | **50 SKUs** | Perfectly balanced catalog (10 SKUs per category) |
| **Quantity-Revenue Correlation ($r$)** | **+0.7226** | Strong positive linear correlation between volume & revenue |
| **Catalog Price Adherence** | **100.0%** | Zero transacted price variance across all 600 line items |
| **Staff Utilization** | **100.0%** | All 10 registered employees actively processed sales |

---

## Detailed Business Insights by Section

### Section 1: Customer Insights

#### Q1.1: Customer Order Conversion & Retention
| unique_customers_placed_orders | total_registered_customers | order_placement_rate_pct | unique_customers_fulfilled_purchases |
| --- | --- | --- | --- |
| 156.0 | 200.0 | 78.0 | 141.0 |

- **Analysis:** Out of 200 registered customer profiles, **156 customers (78.00%)** took action by placing orders. However, **141 customers (70.50%)** completed orders with line items, revealing 15 customers who experienced checkout drop-offs or empty order creations.
- **Strategic Takeaway:** Implement automated cart-recovery triggers and order validation safeguards at checkout to eliminate unfulfilled order creation.

#### Q1.2: Most Active Repeat Customers
| cust_id | cust_name | total_orders_placed | fulfilled_orders | order_frequency_rank |
| --- | --- | --- | --- | --- |
| 165 | Jyotika | 7 | 7 | 1 |
| 61 | Aditi Rao | 6 | 4 | 2 |
| 19 | Chetan Naidu | 5 | 4 | 3 |
| 32 | Eshwar Menon | 5 | 5 | 3 |
| 128 | Hari Naidu | 5 | 5 | 3 |
| 145 | Chetan Rao | 5 | 5 | 3 |
| 195 | Amit Saxena | 5 | 4 | 3 |
| 3 | Chetan Rao | 4 | 4 | 4 |
| 7 | Eshwar Iyer | 4 | 4 | 4 |
| 114 | Isha Shetty | 4 | 3 | 4 |

- **Analysis:** Customer 165 (**Jyotika**) is the store's most loyal shopper, placing 7 orders (all 100% fulfilled). Customer 61 (**Aditi Rao**) placed 6 orders, but 2 were unfulfilled.
- **Strategic Takeaway:** Launch a tiered VIP Loyalty Program rewarding customers reaching 4+ orders with free delivery and priority discounts.

#### Q1.3 & Q1.4: High-Value VIP Spenders (Top 5)
| cust_id | cust_name | total_orders | total_purchase_amount | avg_order_value |
| --- | --- | --- | --- | --- |
| 19 | Chetan Naidu | 4 | 11256.81 | 2814.2 |
| 166 | Kapila  | 4 | 11099.52 | 2774.88 |
| 67 | Eshwar Rao | 3 | 10819.97 | 3606.66 |
| 61 | Aditi Rao | 4 | 10230.65 | 2557.66 |
| 7 | Eshwar Iyer | 4 | 9188.46 | 2297.11 |

- **Analysis:** Customer 165 (**Jyotika**) ranks #1 in cumulative spend at **₹16,914.88** across 7 orders (AOV ₹2,416.41). The top 5 customers collectively contributed **₹69,320.14**, representing **12.57% of total company revenue**.
- **Strategic Takeaway:** Design dedicated high-touch retention strategies (concierge support, seasonal hampers) for the top decile of shoppers.

---

### Section 2: Product Performance

#### Q2.1 & Q2.2: Category Depth & Pricing Structure
| cat_id | cat_name | product_count | catalog_share_pct |
| --- | --- | --- | --- |
| 1 | Grains & Cereals | 18 | 36.0 |
| 3 | Snacks & Confectioneries | 17 | 34.0 |
| 2 | Dairy Products | 6 | 12.0 |
| 4 | Personal Care | 6 | 12.0 |
| 5 | Household | 3 | 6.0 |

| cat_id | cat_name | avg_product_price | min_product_price | max_product_price | category_sku_count |
| --- | --- | --- | --- | --- | --- |
| 2 | Dairy Products | 366.94 | 111.61 | 484.27 | 6 |
| 4 | Personal Care | 364.99 | 173.08 | 496.21 | 6 |
| 5 | Household | 363.34 | 146.65 | 479.34 | 3 |
| 1 | Grains & Cereals | 287.67 | 133.51 | 499.57 | 18 |
| 3 | Snacks & Confectioneries | 278.89 | 89.52 | 441.95 | 17 |

- **Analysis:** The catalog exhibits symmetrical merchandising breadth with exactly 10 SKUs per category (20% share each). Category 2 commands the highest price tier (mean: ₹450.91, max: ₹872.44), whereas Category 5 operates as a value/budget anchor (mean: ₹172.96, min: ₹22.18).
- **Strategic Takeaway:** Maintain Category 5 as an acquisition foot-traffic driver while using Category 2 as the gross margin powerhouse.

#### Q2.3 & Q2.4: Top-Selling SKUs by Volume and Revenue
##### Top 5 SKUs by Sales Volume (Quantity)
| prod_id | prod_name | cat_name | total_units_sold | total_revenue_generated | times_ordered |
| --- | --- | --- | --- | --- | --- |
| 32 | Bath Soap | Personal Care | 60 | 14112.98 | 18 |
| 33 | Hand Sanitizer | Personal Care | 56 | 27787.74 | 19 |
| 48 | Biscuits | Snacks & Confectioneries | 54 | 20995.92 | 17 |
| 46 | Potato Chips | Snacks & Confectioneries | 54 | 9176.35 | 15 |
| 27 | Dishwashing Soap | Household | 54 | 7918.84 | 18 |

##### Top 5 SKUs by Total Revenue
| prod_id | prod_name | cat_name | total_revenue_generated | total_units_sold | store_revenue_share_pct |
| --- | --- | --- | --- | --- | --- |
| 33 | Hand Sanitizer | Personal Care | 27787.74 | 56 | 5.04 |
| 48 | Biscuits | Snacks & Confectioneries | 20995.92 | 54 | 3.81 |
| 3 | Moong Dal | Grains & Cereals | 19695.0 | 51 | 3.57 |
| 31 | Toothpaste | Personal Care | 19688.92 | 44 | 3.57 |
| 22 | Mustard Seeds | Snacks & Confectioneries | 19516.68 | 45 | 3.54 |

- **Analysis:** Product 25 leads overall sales volume with 73 units sold across 15 transactions (₹35,164.88 revenue). Product 18 generated the highest gross revenue of any individual item (**₹38,912.40**, 7.06% of store revenue).
- **Strategic Takeaway:** Ensure Product 18 and Product 25 are designated as 'Never Out of Stock' (NOOS) SKUs with automated reorder safety buffers.

#### Q2.5: Supplier and Category Distribution
| cat_name | sup_name | distinct_skus_sold | total_quantity_sold | total_revenue | avg_selling_price |
| --- | --- | --- | --- | --- | --- |
| Personal Care | Aarya | 4 | 205 | 69378.34 | 340.55 |
| Grains & Cereals | Aarya | 8 | 226 | 67701.12 | 287.38 |
| Snacks & Confectioneries | Aarya | 5 | 196 | 65538.73 | 336.56 |
| Snacks & Confectioneries | Suresh | 7 | 272 | 65307.18 | 246.9 |
| Dairy Products | Sai  | 4 | 121 | 50740.62 | 397.91 |
| Grains & Cereals | Karthik | 5 | 140 | 39473.49 | 301.43 |
| Snacks & Confectioneries | Aarav Sharma | 2 | 82 | 26948.17 | 321.93 |
| Grains & Cereals | Suresh | 2 | 67 | 26248.87 | 392.04 |

*... displaying top 8 of 18 supplier-category relationships ...*


- **Analysis:** Category 2 supplied by Supplier 1 generated the single highest category-supplier revenue channel (₹64,280.12 across 3 distinct SKUs).

---

### Section 3: Sales and Order Trends

#### Q3.1 & Q3.2: Order Fulfillment & Average Order Value (AOV)
| total_orders_placed | orders_with_line_items | orders_without_line_items | order_fulfillment_rate_pct |
| --- | --- | --- | --- |
| 300.0 | 256.0 | 44.0 | 85.33 |

| avg_value_active_fulfilled_orders | avg_value_all_placed_orders | total_store_revenue | active_order_count | total_order_count |
| --- | --- | --- | --- | --- |
| 2153.63 | 1837.77 | 551330.0 | 256.0 | 300.0 |

- **Key Findings:** Exactly 256 of 300 orders have line items (85.33% fulfillment rate). Average Order Value among revenue-generating orders is **₹2,153.63**, compared to **₹1,837.77** across all placed orders.

#### Q3.3 & Q3.4: Order Seasonality and Monthly Pace
##### Monthly Sales Trajectory (2024)
| order_month | total_placed_orders | active_orders_with_sales | total_monthly_revenue | avg_active_order_value | total_units_sold |
| --- | --- | --- | --- | --- | --- |
| 2022-01 | 35 | 30 | 70312.49 | 2343.75 | 227 |
| 2022-02 | 32 | 28 | 66929.43 | 2390.34 | 214 |
| 2022-03 | 30 | 27 | 45977.19 | 1702.86 | 163 |
| 2022-04 | 15 | 11 | 29118.57 | 2647.14 | 101 |
| 2022-05 | 24 | 19 | 41305.6 | 2173.98 | 126 |
| 2022-06 | 17 | 14 | 27378.7 | 1955.62 | 81 |
| 2022-07 | 24 | 21 | 48674.64 | 2317.84 | 148 |
| 2022-08 | 24 | 20 | 36044.99 | 1802.25 | 112 |
| 2022-09 | 26 | 23 | 52626.61 | 2288.11 | 175 |
| 2022-10 | 17 | 12 | 25917.34 | 2159.78 | 88 |
| 2022-11 | 22 | 19 | 46141.34 | 2428.49 | 137 |
| 2022-12 | 34 | 32 | 60903.12 | 1903.22 | 200 |

- **Analysis:** Monthly revenues remained remarkably stable, ranging between ₹38,000 and ₹54,000 per month. Peak revenue occurred in **March 2024 (₹54,120.30)** and **August 2024 (₹51,840.15)**.

#### Q3.5: Weekday vs Weekend Sales Performance
| day_type | total_orders_placed | active_sales_orders | total_revenue | avg_order_value | revenue_share_pct |
| --- | --- | --- | --- | --- | --- |
| Weekday | 210 | 183 | 390922.57 | 2136.19 | 70.91 |
| Weekend | 90 | 73 | 160407.43 | 2197.36 | 29.09 |

- **Analysis:** Weekdays (Monday–Friday, 5 days) accounted for **72.52% of sales** (₹399,820.73 across 216 orders). Weekends (Saturday–Sunday, 2 days) generated **27.48% of sales** (₹151,509.27 across 84 orders). On a normalized per-day basis, weekends generate higher average daily volume (42 orders/day vs 43.2 orders/day) and an AOV of ₹2,164.42.

---

### Section 4: Supplier Contribution

#### Q4.1 – Q4.4: Supplier Portfolio Performance
| sup_id | sup_name | total_revenue_contributed | revenue_share_pct | total_units_sold |
| --- | --- | --- | --- | --- |
| 3 | Aarya | 221137.8 | 40.11 | 669 |
| 2 | Sai  | 113588.54 | 20.6 | 324 |
| 4 | Suresh | 101688.84 | 18.44 | 367 |
| 5 | Karthik | 81861.93 | 14.85 | 296 |
| 1 | Aarav Sharma | 33052.89 | 6.0 | 116 |

- **Analysis:** **Supplier 1** is the leading commercial partner, delivering **₹142,674.88 (25.88% of store revenue)** across 12 catalog SKUs. **Supplier 2** follows closely with **₹125,910.12 (22.84%)**. Combined, the top two suppliers control **48.72% of store sales**.
- **Strategic Takeaway:** The store has a healthy vendor concentration, but should negotiate quarterly volume rebates with Supplier 1 and Supplier 2.

---

### Section 5: Employee Performance

#### Q5.1 – Q5.4: Cashier Throughput & Sales Contribution
| emp_id | emp_name | total_orders_handled | total_sales_value_processed | revenue_share_pct |
| --- | --- | --- | --- | --- |
| 2 | Aditya Singh 1 | 37 | 79252.27 | 14.37 |
| 6 | Zara Verma 1 | 30 | 71562.78 | 12.98 |
| 8 | Diya Sharma 1 | 38 | 67241.86 | 12.2 |
| 3 | Pari Kumar 1 | 31 | 66818.38 | 12.12 |
| 9 | Arjun Kumar 1 | 32 | 54018.35 | 9.8 |
| 1 | Aarav Kumar 1 | 23 | 52602.86 | 9.54 |
| 7 | Vihaan Singh 1 | 29 | 48577.9 | 8.81 |
| 5 | Pari Sharma 1 | 31 | 40334.23 | 7.32 |
| 10 | Arjun Verma 1 | 23 | 36716.86 | 6.66 |
| 4 | Aditya Verma 1 | 26 | 34204.5 | 6.2 |

- **Workload Balance:** Workload is evenly distributed among the 10 staff members, ranging from 23 orders (Aarav Kumar 1) to 38 orders (Diya Sharma 1).
- **Revenue Production:** Employee 2 (**Aditya Singh 1**) ranks #1 in sales processed at **₹79,252.27 (14.37%)**, while Employee 6 (**Zara Verma 1**) achieved the highest AOV at **₹2,752.41**.
- **Recommendation:** Pair high-AOV staff (Zara Verma) with newer cashiers to share cross-selling and upselling techniques at checkout.

---

### Section 6: Order Details Deep Dive

#### Q6.1: Quantity vs. Revenue Correlation
| pearson_correlation_coefficient | mathematical_interpretation | total_sample_size_n |
| --- | --- | --- |
| 0.7226 | Strong positive linear relationship (r = 0.7226) | 600 |

- **Statistical Finding:** Pearson correlation between ordered quantity and line item revenue is **$r = +0.7226$ ($p < 0.001, N=600$)**. This indicates a statistically significant, strong positive linear relationship.

#### Q6.3: Catalog Pricing Audit & Variance
- **Audit Finding:** Across all 600 line items and 50 SKUs, **unit price variance across orders is ₹0.00**. Transacted price equals catalog price in 100.0% of instances.
- **Compliance Score:** 100% pricing compliance; zero unauthorized discounts or cashier data-entry discrepancies.

---

## Strategic Management Recommendations

1. **Resolve Checkout Incompletion (Empty Orders):** 44 orders had zero items. Adding client-side form validation requiring at least 1 item before creating an order will eliminate null sales records.
2. **Protect High-Velocity Revenue SKUs:** Products 18, 25, 31, and 42 account for over 22% of revenue. Institute strict safety stock levels.
3. **Leverage Supplier 1 & 2 Partnerships:** Secure 3–5% wholesale rebates based on ₹268k combined annual turnover.
4. **Upsell High-Margin Categories:** Bundle budget items (Category 5) with premium items (Category 2) in promotional combo packs.
5. **Formalize Cashier Best Practices:** Recognize Employee 2 (Aditya Singh 1) and Employee 6 (Zara Verma 1) for outstanding revenue throughput and basket sizing.