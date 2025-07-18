/*
===============================================================================
Ranking Analysis
===============================================================================
Purpose:
    - Rank products and customers based on revenue and order metrics.
    - Identify top and bottom performers using window functions.
    - Provide flexible and scalable analysis for decision-making.

SQL Concepts Used:
    - Window Functions: RANK(), DENSE_RANK(), ROW_NUMBER()
    - Aggregate Functions: SUM(), COUNT(), AVG()
    - CTEs (Common Table Expressions)
    - GROUP BY, ORDER BY, TOP clause

===============================================================================
*/

-- Top 5 Products by Revenue
PRINT 'Top 5 Products by Total Revenue (Simple Aggregate Method)';
SELECT TOP 5
    p.product_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue DESC;

-- Top 5 Products by Revenue using Window Function for dynamic filtering
PRINT 'Top 5 Products by Total Revenue (Using Window Functions)';
WITH product_revenue AS (
    SELECT
        p.product_name,
        SUM(f.sales_amount) AS total_revenue,
        RANK() OVER (ORDER BY SUM(f.sales_amount) DESC) AS revenue_rank
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON p.product_key = f.product_key
    GROUP BY p.product_name
)
SELECT *
FROM product_revenue
WHERE revenue_rank <= 5;

-- Bottom 5 Products by Revenue (Least Performing)
PRINT 'Bottom 5 Products by Revenue';
SELECT TOP 5
    p.product_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue;

-- Top 10 Customers by Revenue
PRINT 'Top 10 Customers Based on Total Revenue Generated';
SELECT TOP 10
    c.customer_key,
    c.first_name,
    c.last_name,
    c.country,
    SUM(f.sales_amount) AS total_revenue,
    COUNT(DISTINCT f.order_number) AS total_orders,
    AVG(f.sales_amount) AS avg_order_value
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
GROUP BY
    c.customer_key,
    c.first_name,
    c.last_name,
    c.country
ORDER BY total_revenue DESC;

-- Bottom 3 Customers by Order Count
PRINT '3 Customers with the Fewest Orders Placed';
SELECT TOP 3
    c.customer_key,
    c.first_name,
    c.last_name,
    COUNT(DISTINCT f.order_number) AS total_orders
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
GROUP BY
    c.customer_key,
    c.first_name,
    c.last_name
ORDER BY total_orders ASC;

-- Rank Products Within Categories by Revenue
PRINT 'Top Products by Revenue Within Each Category';
WITH ranked_products_by_category AS (
    SELECT
        p.category,
        p.product_name,
        SUM(f.sales_amount) AS total_revenue,
        RANK() OVER (PARTITION BY p.category ORDER BY SUM(f.sales_amount) DESC) AS category_rank
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    GROUP BY p.category, p.product_name
)
SELECT *
FROM ranked_products_by_category
WHERE category_rank <= 3
ORDER BY category, category_rank;

-- Most Loyal Customers - Highest Repeat Orders
PRINT 'Top 5 Customers with Highest Repeat Orders (Loyalty Analysis)';
SELECT TOP 5
    c.customer_key,
    c.first_name,
    c.last_name,
    COUNT(f.order_number) AS total_order_instances,
    COUNT(DISTINCT f.order_number) AS unique_orders,
    COUNT(f.order_number) - COUNT(DISTINCT f.order_number) AS repeated_orders
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
GROUP BY
    c.customer_key,
    c.first_name,
    c.last_name
ORDER BY repeated_orders DESC;

-- Rank Countries by Total Revenue
PRINT 'Ranking Countries by Total Revenue Generated';
SELECT
    c.country,
    SUM(f.sales_amount) AS total_revenue,
    RANK() OVER (ORDER BY SUM(f.sales_amount) DESC) AS country_rank
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key
GROUP BY c.country
ORDER BY country_rank;
