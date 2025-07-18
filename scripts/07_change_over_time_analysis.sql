/*
===============================================================================
Change Over Time Analysis
===============================================================================
Purpose:
    - Analyze sales trends, customer engagement, and product movement over time.
    - Identify seasonal behavior and trends in performance.
    - Include Month-over-Month (MoM) % change and Year-to-Date (YTD) metrics.

SQL Functions Used:
    - Date Functions: DATEPART(), DATETRUNC(), FORMAT(), LAG()
    - Aggregate Functions: SUM(), COUNT(), AVG()
    - Window Functions: LAG(), SUM() OVER ()

===============================================================================
*/

-- Basic Monthly Trend Analysis
PRINT '=== Monthly Sales Trend using YEAR-MONTH Breakdown ==='
SELECT
    YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS unique_customers,
    SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY order_year, order_month;


-- Monthly Trend using DATETRUNC for precise monthly buckets
PRINT '=== Monthly Trend Using DATETRUNC for Order Date ==='
SELECT
    DATETRUNC(month, order_date) AS month_bucket,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS unique_customers,
    SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month, order_date)
ORDER BY month_bucket;


-- Month-over-Month Change: Adds previous month's revenue and computes % change
PRINT '=== Monthly Sales with Month-over-Month Growth Percentage ==='
SELECT
    FORMAT(order_date, 'yyyy-MMM') AS month_name,
    DATETRUNC(month, order_date) AS month_start,
    SUM(sales_amount) AS total_sales,
    LAG(SUM(sales_amount)) OVER (ORDER BY DATETRUNC(month, order_date)) AS prev_month_sales,
    ROUND(
        (SUM(sales_amount) - LAG(SUM(sales_amount)) OVER (ORDER BY DATETRUNC(month, order_date)))
        * 100.0 / NULLIF(LAG(SUM(sales_amount)) OVER (ORDER BY DATETRUNC(month, order_date)), 0), 2
    ) AS pct_mom_change
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month, order_date), FORMAT(order_date, 'yyyy-MMM')
ORDER BY month_start;


-- Year-To-Date (YTD) Sales and Running Totals
PRINT '=== Cumulative Year-To-Date (YTD) Sales ==='
SELECT
    DATETRUNC(month, order_date) AS month_start,
    SUM(sales_amount) AS monthly_sales,
    SUM(SUM(sales_amount)) OVER (PARTITION BY YEAR(order_date) ORDER BY DATETRUNC(month, order_date)) AS ytd_sales
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month, order_date), YEAR(order_date)
ORDER BY month_start;


-- 3-Month Moving Average Sales to smooth seasonality
PRINT '=== 3-Month Moving Average of Sales ==='
SELECT
    DATETRUNC(month, order_date) AS month_start,
    SUM(sales_amount) AS monthly_sales,
    ROUND(AVG(SUM(sales_amount)) OVER (
        ORDER BY DATETRUNC(month, order_date)
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_3_month
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month, order_date)
ORDER BY month_start;
