/*
===============================================================================
Part-to-Whole Analysis
===============================================================================
Purpose:
    - To understand how individual categories contribute to the overall sales.
    - Useful for prioritization and decision-making (e.g., which categories to invest more in).
    - Can support A/B testing, regional comparisons, or business unit evaluations.

Features:
    - Comparison with previous year’s category sales to track growth trends.
    - Ranking of categories based on percentage contribution.
    - Conditional tagging (e.g., "Top Performer", "Moderate", "Low Performer").
    - Overall summary row added using ROLLUP.

===============================================================================
*/

-- Aggregate sales by category and year for time-based analysis
WITH category_sales AS (
    SELECT
        p.category,
        YEAR(f.order_date) AS order_year,
        SUM(f.sales_amount) AS total_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON p.product_key = f.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY p.category, YEAR(f.order_date)
),

-- Add window functions for total market sales per year and category ranking
category_contributions AS (
    SELECT
        category,
        order_year,
        total_sales,
        SUM(total_sales) OVER (PARTITION BY order_year) AS overall_sales,
        ROUND((CAST(total_sales AS FLOAT) /
              SUM(total_sales) OVER (PARTITION BY order_year)) * 100, 2) AS percentage_of_total,
        RANK() OVER (PARTITION BY order_year ORDER BY total_sales DESC) AS sales_rank
    FROM category_sales
),

-- Add YoY comparison for growth trends
category_growth AS (
    SELECT
        *,
        LAG(total_sales) OVER (PARTITION BY category ORDER BY order_year) AS previous_year_sales,
        total_sales - LAG(total_sales) OVER (PARTITION BY category ORDER BY order_year) AS sales_diff,
        ROUND(
            CASE
                WHEN LAG(total_sales) OVER (PARTITION BY category ORDER BY order_year) IS NULL THEN NULL
                ELSE ((CAST(total_sales AS FLOAT) - LAG(total_sales) OVER (PARTITION BY category ORDER BY order_year))
                      / NULLIF(LAG(total_sales) OVER (PARTITION BY category ORDER BY order_year), 0)) * 100
            END
        , 2) AS growth_percentage
    FROM category_contributions
)

-- Present the insights
SELECT
    order_year,
    category,
    total_sales,
    overall_sales,
    percentage_of_total,
    sales_rank,
    previous_year_sales,
    sales_diff,
    growth_percentage,
    -- Tag categories based on % contribution
    CASE
        WHEN percentage_of_total >= 30 THEN 'Top Performer'
        WHEN percentage_of_total BETWEEN 10 AND 30 THEN 'Moderate'
        ELSE 'Low Performer'
    END AS performance_tag
FROM category_growth
ORDER BY order_year, sales_rank;
