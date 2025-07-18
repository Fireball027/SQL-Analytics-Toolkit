/*
===============================================================================
Customer Report - Enhanced Version
===============================================================================
Purpose:
    - Consolidates essential customer behavior, demographics, and transactional metrics.
    - Enables segmentation for marketing, loyalty, and retention strategies.
    - Includes key performance indicators (KPIs) for strategic analysis.

Key Enhancements:
    - New KPIs: First Order Date, Tenure, Average Quantity per Order.
    - Customer segmentation (VIP, Loyal, Regular, New).
    - NULL-safe logic to avoid division errors.

===============================================================================
*/

-- Drop existing view (if it exists)
IF OBJECT_ID('gold.report_customers', 'V') IS NOT NULL
    DROP VIEW gold.report_customers;
GO

-- Create the enhanced customer report view
CREATE VIEW gold.report_customers AS

-- CTE: base_query
-- Fetch raw transactional and customer data
WITH base_query AS (
    SELECT
        f.order_number,
        f.product_key,
        f.order_date,
        f.sales_amount,
        f.quantity,
        c.customer_key,
        c.customer_number,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        DATEDIFF(YEAR, c.birthdate, GETDATE()) AS age
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON c.customer_key = f.customer_key
    WHERE f.order_date IS NOT NULL
)

-- CTE: customer_aggregation
-- Aggregate customer-level metrics
, customer_aggregation AS (
    SELECT
        customer_key,
        customer_number,
        customer_name,
        age,
        COUNT(DISTINCT order_number) AS total_orders,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        COUNT(DISTINCT product_key) AS total_products,
        MIN(order_date) AS first_order_date,
        MAX(order_date) AS last_order_date,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan -- active duration
    FROM base_query
    GROUP BY
        customer_key,
        customer_number,
        customer_name,
        age
)

-- Enriched customer report with segmentation and KPIs
SELECT
    customer_key,
    customer_number,
    customer_name,
    age,

    -- Create age buckets
    CASE
        WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50 and above'
    END AS age_group,

    -- Classify customers into segments based on total sales and lifespan
    CASE
        WHEN lifespan >= 12 AND total_sales > 10000 THEN 'VIP'
        WHEN lifespan >= 12 AND total_sales BETWEEN 5000 AND 10000 THEN 'Loyal'
        WHEN lifespan >= 6 THEN 'Regular'
        ELSE 'New'
    END AS customer_segment,

    first_order_date,
    last_order_date,
    DATEDIFF(MONTH, last_order_date, GETDATE()) AS recency,         -- Months since last order
    DATEDIFF(MONTH, first_order_date, GETDATE()) AS tenure,         -- Months since first order

    total_orders,
    total_sales,
    total_quantity,
    total_products,
    lifespan,

    -- Average Order Value (AOV)
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE ROUND(total_sales * 1.0 / total_orders, 2)
    END AS avg_order_value,

    -- Average Monthly Spend
    CASE
        WHEN lifespan = 0 THEN ROUND(total_sales, 2)
        ELSE ROUND(total_sales * 1.0 / lifespan, 2)
    END AS avg_monthly_spend,

    -- Average Quantity per Order
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE ROUND(total_quantity * 1.0 / total_orders, 2)
    END AS avg_quantity_per_order

FROM customer_aggregation;
