/*
===============================================================================
Performance Analysis (Year-over-Year, Month-over-Month)
===============================================================================
Purpose:
    - Compare yearly product performance against its historical average and previous year.
    - Identify growth trends and high-performing products.
    - Rank products by performance and calculate their sales contribution.

SQL Functions Used:
    - LAG(): For comparing against the previous year.
    - AVG() OVER(): For trend detection relative to historical average.
    - RANK(), SUM() OVER(): For ranking and contribution metrics.
    - CASE: For classifying growth and performance trends.

===============================================================================
*/

-- CTE to calculate total yearly product sales
WITH yearly_product_sales AS (
    SELECT
        YEAR(f.order_date) AS order_year,
        p.product_name,
        SUM(f.sales_amount) AS current_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY
        YEAR(f.order_date),
        p.product_name
),

-- CTE to calculate total sales for each year for overall contribution
yearly_total_sales AS (
    SELECT
        YEAR(order_date) AS order_year,
        SUM(sales_amount) AS total_sales_year
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY YEAR(order_date)
)

-- Final SELECT for performance comparison
SELECT
    yps.order_year,
    yps.product_name,
    yps.current_sales,

    -- Average sales of this product across all years
    AVG(yps.current_sales) OVER (PARTITION BY yps.product_name) AS avg_sales,

    -- Difference from average
    yps.current_sales - AVG(yps.current_sales) OVER (PARTITION BY yps.product_name) AS diff_from_avg,

    -- Performance classification: Above/Below Average
    CASE
        WHEN yps.current_sales > AVG(yps.current_sales) OVER (PARTITION BY yps.product_name) THEN 'Above Avg'
        WHEN yps.current_sales < AVG(yps.current_sales) OVER (PARTITION BY yps.product_name) THEN 'Below Avg'
        ELSE 'At Avg'
    END AS avg_change,

    -- Year-over-Year comparison
    LAG(yps.current_sales) OVER (PARTITION BY yps.product_name ORDER BY yps.order_year) AS prev_year_sales,
    yps.current_sales - LAG(yps.current_sales) OVER (PARTITION BY yps.product_name ORDER BY yps.order_year) AS diff_prev_year,

    -- YoY trend: Increase, Decrease, or No Change
    CASE
        WHEN yps.current_sales > LAG(yps.current_sales) OVER (PARTITION BY yps.product_name ORDER BY yps.order_year) THEN 'Increase'
        WHEN yps.current_sales < LAG(yps.current_sales) OVER (PARTITION BY yps.product_name ORDER BY yps.order_year) THEN 'Decrease'
        ELSE 'No Change'
    END AS yoy_trend,

    -- Product's rank within the year by sales
    RANK() OVER (PARTITION BY yps.order_year ORDER BY yps.current_sales DESC) AS product_rank_in_year,

    -- Percentage contribution to total yearly sales
    ROUND(
        (yps.current_sales * 100.0) / yts.total_sales_year, 2
    ) AS contribution_pct

FROM yearly_product_sales yps
JOIN yearly_total_sales yts
    ON yps.order_year = yts.order_year
ORDER BY
    yps.product_name,
    yps.order_year;
