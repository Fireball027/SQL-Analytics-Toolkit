/*
===============================================================================
Measures Exploration (Key Metrics)
===============================================================================
Purpose:
    - To calculate aggregated business KPIs for sales, customer behavior, and product performance.
    - To enrich insights with ratios, averages, and counts.
    - To produce a clean unified output for dashboards or reporting.

===============================================================================
*/

-- Which section is running in output?
PRINT '=== Summary: Core Business Metrics ===';

-- Total Sales Revenue (all-time)
SELECT SUM(sales_amount) AS total_sales
FROM gold.fact_sales;

-- Total Quantity Sold
SELECT SUM(quantity) AS total_quantity
FROM gold.fact_sales;

-- Average Selling Price (across all sales)
SELECT AVG(price) AS avg_price
FROM gold.fact_sales;

-- Total Number of Orders (unique order IDs)
SELECT COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales;

-- Total Number of Products in the Catalog
SELECT COUNT(DISTINCT product_key) AS total_products
FROM gold.dim_products;

-- Total Number of Customers in the Database
SELECT COUNT(DISTINCT customer_key) AS total_customers
FROM gold.dim_customers;

-- Total Number of Customers Who Placed Orders
SELECT COUNT(DISTINCT customer_key) AS ordering_customers
FROM gold.fact_sales;

-- % of Registered Customers Who Have Ordered
SELECT
    CAST(COUNT(DISTINCT fs.customer_key) * 100.0 / NULLIF(dc.total_customers, 0) AS DECIMAL(5,2))
    AS percent_customers_ordered
FROM gold.fact_sales fs
CROSS JOIN (
    SELECT COUNT(DISTINCT customer_key) AS total_customers FROM gold.dim_customers
) dc;

-- Revenue Per Order
SELECT
    CAST(SUM(sales_amount) / NULLIF(COUNT(DISTINCT order_number), 0) AS DECIMAL(10,2)) AS revenue_per_order
FROM gold.fact_sales;

-- Revenue Per Customer (average revenue per unique ordering customer)
SELECT
    CAST(SUM(sales_amount) / NULLIF(COUNT(DISTINCT customer_key), 0) AS DECIMAL(10,2)) AS revenue_per_customer
FROM gold.fact_sales;

-- Average Quantity Per Order
SELECT
    CAST(SUM(quantity) / NULLIF(COUNT(DISTINCT order_number), 0) AS DECIMAL(10,2)) AS avg_quantity_per_order
FROM gold.fact_sales;

-- Generate a Unified Key Metrics Report with Labels and Units
PRINT '=== Business KPI Report ===';

SELECT 'Total Sales' AS metric, CAST(SUM(sales_amount) AS DECIMAL(12,2)) AS value, 'INR' AS unit FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity Sold', SUM(quantity), 'Units' FROM gold.fact_sales
UNION ALL
SELECT 'Average Selling Price', CAST(AVG(price) AS DECIMAL(10,2)), 'INR' FROM gold.fact_sales
UNION ALL
SELECT 'Total Orders', COUNT(DISTINCT order_number), 'Orders' FROM gold.fact_sales
UNION ALL
SELECT 'Revenue Per Order', CAST(SUM(sales_amount) / NULLIF(COUNT(DISTINCT order_number), 0) AS DECIMAL(10,2)), 'INR' FROM gold.fact_sales
UNION ALL
SELECT 'Total Products', COUNT(DISTINCT product_key), 'Products' FROM gold.dim_products
UNION ALL
SELECT 'Total Customers', COUNT(DISTINCT customer_key), 'Customers' FROM gold.dim_customers
UNION ALL
SELECT 'Ordering Customers', COUNT(DISTINCT customer_key), 'Customers' FROM gold.fact_sales
UNION ALL
SELECT 'Revenue Per Customer', CAST(SUM(sales_amount) / NULLIF(COUNT(DISTINCT customer_key), 0) AS DECIMAL(10,2)), 'INR' FROM gold.fact_sales
UNION ALL
SELECT 'Avg Quantity per Order', CAST(SUM(quantity) / NULLIF(COUNT(DISTINCT order_number), 0) AS DECIMAL(10,2)), 'Units' FROM gold.fact_sales
UNION ALL
SELECT '% Customers Ordered',
    CAST(COUNT(DISTINCT fs.customer_key) * 100.0 / NULLIF(dc.total_customers, 0) AS DECIMAL(5,2)),
    '%'
FROM gold.fact_sales fs
CROSS JOIN (
    SELECT COUNT(DISTINCT customer_key) AS total_customers FROM gold.dim_customers
) dc;

PRINT '=== End of Metrics Summary ===';
