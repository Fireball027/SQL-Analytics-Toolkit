/*
===============================================================================
Dimensions Exploration Script
===============================================================================

Purpose:
    - To explore unique values and groupings in dimension tables.
    - Understand distribution of key descriptive fields like country, category, subcategory, etc.
    - Useful for validating dimensionality in star schema models or checking data quality.

SQL Concepts Used:
    - DISTINCT
    - ORDER BY
    - GROUP BY
    - COUNT

===============================================================================
*/

-- Explore unique customer countries
PRINT 'Step 1: Retrieving list of unique countries from gold.dim_customers...';

SELECT DISTINCT
    country
FROM gold.dim_customers
WHERE country IS NOT NULL
ORDER BY country;

-- Count of distinct countries
PRINT 'Step 1.1: Counting total distinct customer countries...';

SELECT
    COUNT(DISTINCT country) AS unique_country_count
FROM gold.dim_customers
WHERE country IS NOT NULL;
GO

-- Explore unique combinations of category, subcategory, and product
PRINT 'Step 2: Retrieving unique combinations of category, subcategory, and product_name from gold.dim_products...';

SELECT DISTINCT
    category,
    subcategory,
    product_name
FROM gold.dim_products
WHERE category IS NOT NULL AND subcategory IS NOT NULL AND product_name IS NOT NULL
ORDER BY category, subcategory, product_name;
GO

-- Count of distinct product categories
PRINT 'Step 2.1: Counting total distinct product categories...';

SELECT
    COUNT(DISTINCT category) AS unique_category_count
FROM gold.dim_products
WHERE category IS NOT NULL;

-- Count of distinct category-subcategory pairs
PRINT 'Step 2.2: Counting total distinct category-subcategory combinations...';

SELECT
    COUNT(DISTINCT CONCAT(category, '|', subcategory)) AS unique_cat_subcat_combinations
FROM gold.dim_products
WHERE category IS NOT NULL AND subcategory IS NOT NULL;

-- Distribution of product counts by category and subcategory
PRINT 'Step 2.3: Showing product distribution grouped by category and subcategory...';

SELECT
    category,
    subcategory,
    COUNT(DISTINCT product_name) AS product_count
FROM gold.dim_products
WHERE category IS NOT NULL AND subcategory IS NOT NULL
GROUP BY category, subcategory
ORDER BY category, subcategory;
GO

-- Products without a category or subcategory (data issue check)
PRINT 'Step 3: Checking for products with missing category or subcategory (potential data quality issues)...';

SELECT
    product_id,
    product_name,
    category,
    subcategory
FROM gold.dim_products
WHERE category IS NULL OR subcategory IS NULL;
GO

PRINT 'Dimensions exploration completed successfully.';
