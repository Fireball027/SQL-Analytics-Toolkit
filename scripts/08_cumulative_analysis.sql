/*
===============================================================================
Cumulative Analysis
===============================================================================
Purpose:
    - To calculate running totals or moving averages for key business metrics.
    - To track cumulative performance across time (monthly, quarterly, yearly).
    - Useful for understanding sales momentum, price trends, and customer growth.

SQL Functions Used:
    - Window Functions: SUM() OVER(), AVG() OVER(), COUNT() OVER()
    - Date Functions: DATETRUNC()
    - Aggregations: SUM(), AVG(), COUNT()

Other Functions:
    - Total customer count for each period.
    - Cumulative customer growth over time.
    - Used DATETRUNC() to group by month instead of year.
    - Aliased subquery columns clearly for readability.

===============================================================================
*/

-- Main Cumulative Sales and Price Trend Analysis
SELECT
    order_month,                            -- Truncated to month level for time series grouping
    total_sales,                            -- Total sales in that month
    total_customers,                        -- Number of unique customers in that month
    avg_price,                              -- Average product price in that month

    -- Cumulative sales till the current month
    SUM(total_sales) OVER (ORDER BY order_month) AS running_total_sales,

    -- Cumulative customers till the current month (customer growth)
    SUM(total_customers) OVER (ORDER BY order_month) AS cumulative_customers,

    -- Moving average price till current month (smoothed price trend)
    AVG(avg_price) OVER (ORDER BY order_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_price_3_months,

    -- Moving total sales for last 3 months (rolling window)
    SUM(total_sales) OVER (ORDER BY order_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3_month_sales

FROM (
    -- Subquery: Aggregate data at monthly level
    SELECT
        DATETRUNC(month, order_date) AS order_month,      -- Convert order date to month-level granularity
        SUM(sales_amount) AS total_sales,                 -- Sum of all sales
        COUNT(DISTINCT customer_key) AS total_customers,  -- Unique customers per month
        AVG(price) AS avg_price                           -- Average product price
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATETRUNC(month, order_date)
) AS monthly_summary

-- Sort for visualization or charting
ORDER BY order_month;
