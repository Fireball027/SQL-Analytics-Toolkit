/*
===============================================================================
Data Segmentation Analysis
===============================================================================
Purpose:
    - Segment products based on cost for pricing strategy or stocking decisions.
    - Classify customers based on historical spending and loyalty.
    - Provide granular insights for decision-makers on product and customer behavior.

SQL Functions Used:
    - CASE: Custom segmentation logic.
    - GROUP BY: Segment grouping.
    - Aggregates: COUNT(), AVG(), MIN(), MAX(), SUM()
    - DATEDIFF(): Time difference calculation.
    - CTE (Common Table Expressions): Logical structuring.

===============================================================================
*/

-- Product Segmentation based on Cost
WITH product_segments AS (
    SELECT
        product_key,
        product_name,
        cost,
        -- Segmenting products into predefined cost brackets
        CASE
            WHEN cost < 100 THEN 'Below 100'
            WHEN cost BETWEEN 100 AND 500 THEN '100-500'
            WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
            ELSE 'Above 1000'
        END AS cost_range
    FROM gold.dim_products
    -- WHERE cost IS NOT NULL         -- Ignore nulls
),
product_stats AS (
    SELECT
        cost_range,
        COUNT(product_key) AS total_products,
        ROUND(AVG(cost), 2) AS avg_cost
    FROM product_segments
    GROUP BY cost_range
),
top_products_per_segment AS (
    SELECT
        cost_range,
        product_name,
        cost,
        ROW_NUMBER() OVER (PARTITION BY cost_range ORDER BY cost DESC) AS rank
    FROM product_segments
)
-- Final Product Segmentation Output
SELECT
    ps.cost_range,
    ps.total_products,
    ps.avg_cost,
    tp.product_name AS top_product,
    tp.cost AS top_product_cost
FROM product_stats ps
LEFT JOIN top_products_per_segment tp
    ON ps.cost_range = tp.cost_range AND tp.rank = 1  -- Only top product per segment
ORDER BY ps.total_products DESC;

-- Customer Segmentation based on Spending & Lifespan
WITH customer_spending AS (
    SELECT
        c.customer_key,
        SUM(f.sales_amount) AS total_spending,
        MIN(order_date) AS first_order,
        MAX(order_date) AS last_order,
        -- Customer lifespan in months
        DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key
    GROUP BY c.customer_key
),
segmented_customers AS (
    SELECT
        customer_key,
        total_spending,
        lifespan,
        -- Define customer tiers
        CASE
            WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
            WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
            ELSE 'New'
        END AS customer_segment
    FROM customer_spending
),
segment_stats AS (
    SELECT
        customer_segment,
        COUNT(customer_key) AS total_customers,
        ROUND(AVG(total_spending), 2) AS avg_spending,
        ROUND(AVG(lifespan), 1) AS avg_lifespan
    FROM segmented_customers
    GROUP BY customer_segment
)

-- Final Customer Segmentation Output
SELECT
    customer_segment,
    total_customers,
    avg_spending,
    avg_lifespan
FROM segment_stats
ORDER BY total_customers DESC;
