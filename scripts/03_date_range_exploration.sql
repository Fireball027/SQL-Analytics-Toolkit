/*
===============================================================================
Date Range Exploration Script
===============================================================================

Purpose:
    - Analyze temporal boundaries and trends in the data warehouse.
    - Understand data freshness, completeness, and time-based anomalies.
    - Evaluate customer demographics and sales time spans.

SQL Concepts Used:
    - MIN(), MAX(), DATEDIFF(), GETDATE(), AVG()

===============================================================================
*/

-- Explore the range of order dates
PRINT 'Step 1: Exploring sales order date range and overall duration in months...';

SELECT
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    DATEDIFF(DAY, MIN(order_date), MAX(order_date)) AS order_range_days,
    DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS order_range_months,
    DATEDIFF(YEAR, MIN(order_date), MAX(order_date)) AS order_range_years
FROM gold.fact_sales
WHERE order_date IS NOT NULL;
GO

-- Explore shipping and due date range
PRINT 'Step 2: Exploring shipping and due date range...';

SELECT
    MIN(shipping_date) AS first_shipping_date,
    MAX(shipping_date) AS last_shipping_date,
    MIN(due_date) AS earliest_due_date,
    MAX(due_date) AS latest_due_date
FROM gold.fact_sales
WHERE shipping_date IS NOT NULL AND due_date IS NOT NULL;
GO

-- Analyze average shipping lag (order to shipping)
PRINT 'Step 3: Analyzing average and max lag between order and shipping...';

SELECT
    AVG(DATEDIFF(DAY, order_date, shipping_date)) AS avg_shipping_lag_days,
    MAX(DATEDIFF(DAY, order_date, shipping_date)) AS max_shipping_lag_days
FROM gold.fact_sales
WHERE order_date IS NOT NULL AND shipping_date IS NOT NULL;
GO

-- Customer age exploration (youngest, oldest, and average)
PRINT 'Step 4: Exploring customer age demographics based on birthdate...';

SELECT
    MIN(birthdate) AS oldest_birthdate,
    DATEDIFF(YEAR, MIN(birthdate), GETDATE()) AS oldest_age_years,
    MAX(birthdate) AS youngest_birthdate,
    DATEDIFF(YEAR, MAX(birthdate), GETDATE()) AS youngest_age_years,
    AVG(DATEDIFF(DAY, birthdate, GETDATE())) / 365.25 AS average_age_years
FROM gold.dim_customers
WHERE birthdate IS NOT NULL;
GO

-- Identify missing or NULL date values in fact table
PRINT 'Step 5: Checking for rows with missing order, shipping, or due dates...';

SELECT
    COUNT(*) AS rows_with_missing_dates
FROM gold.fact_sales
WHERE order_date IS NULL
   OR shipping_date IS NULL
   OR due_date IS NULL;
GO

-- Recent activity check - how fresh is our data?
PRINT 'Step 6: Checking how recent the latest order is...';

SELECT
    MAX(order_date) AS last_order_date,
    DATEDIFF(DAY, MAX(order_date), GETDATE()) AS days_since_last_order
FROM gold.fact_sales
WHERE order_date IS NOT NULL;
GO

PRINT 'Date range exploration completed successfully.';
