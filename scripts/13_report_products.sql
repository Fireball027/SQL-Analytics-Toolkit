/*
===============================================================================
Product Performance Report View: gold.report_products
===============================================================================
Purpose:
    - To generate a comprehensive analytical summary of all products.
    - Supports product strategy with insights on sales, customer base, recency,
      profitability, and revenue trends.
    - Segments products into performance tiers for targeted decision-making.

Highlights:
    - Captures key dimensions and metrics: category, cost, lifespan, etc.
    - Adds profitability calculations: gross profit, profit margin, ROI.
    - Segments products by revenue and customer base.
    - Calculates average monthly & order revenue.

===============================================================================
*/

-- Drop the view if it already exists
IF OBJECT_ID('gold.report_products', 'V') IS NOT NULL
    DROP VIEW gold.report_products;
GO

-- Create the new enhanced view
CREATE VIEW gold.report_products AS

-- Base Data Extraction: Pull raw transactional data1
WITH base_query AS (
    SELECT
        f.order_number,
        f.order_date,
        f.customer_key,
        f.sales_amount,
        f.quantity,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
),

-- Product-Level Aggregation: Metrics per product
product_aggregations AS (
    SELECT
        product_key,
        product_name,
        category,
        subcategory,
        cost,
        MIN(order_date) AS first_sale_date,
        MAX(order_date) AS last_sale_date,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
        COUNT(DISTINCT order_number) AS total_orders,
        COUNT(DISTINCT customer_key) AS total_customers,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        -- Average Selling Price per item sold
        ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)), 2) AS avg_selling_price,
        -- Total Cost Estimate = unit cost * total quantity sold
        SUM(CAST(cost AS FLOAT) * quantity) AS total_cost,
        -- Gross Profit = sales - cost
        SUM(sales_amount - (CAST(cost AS FLOAT) * quantity)) AS gross_profit
    FROM base_query
    GROUP BY product_key, product_name, category, subcategory, cost
)

-- Reports: KPIs, Segmentation, Profitability, etc.
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    first_sale_date,
    last_sale_date,
    DATEDIFF(MONTH, last_sale_date, GETDATE()) AS recency_in_months,

    -- Product Tiering Based on Revenue
    CASE
        WHEN total_sales > 50000 THEN 'High-Performer'
        WHEN total_sales >= 10000 THEN 'Mid-Range'
        ELSE 'Low-Performer'
    END AS revenue_segment,

    -- Segment by Customer Base
    CASE
        WHEN total_customers > 100 THEN 'Broad Appeal'
        WHEN total_customers BETWEEN 25 AND 100 THEN 'Moderate Appeal'
        ELSE 'Niche Product'
    END AS customer_segment,

    lifespan,
    total_orders,
    total_sales,
    total_quantity,
    total_customers,
    avg_selling_price,

    -- Profit KPIs
    total_cost,
    gross_profit,
    -- Avoid division by zero for margin calculation
    ROUND(CASE WHEN total_sales > 0 THEN (gross_profit / total_sales) * 100 ELSE 0 END, 2) AS profit_margin_percent,
    ROUND(CASE WHEN total_cost > 0 THEN (gross_profit / total_cost) * 100 ELSE 0 END, 2) AS product_roi_percent,

    -- Average Order Revenue (AOR)
    ROUND(CASE WHEN total_orders > 0 THEN total_sales / total_orders ELSE 0 END, 2) AS avg_order_revenue,

    -- Average Monthly Revenue
    ROUND(CASE WHEN lifespan > 0 THEN total_sales / lifespan ELSE total_sales END, 2) AS avg_monthly_revenue

FROM product_aggregations;
