-- ========================================================================================== --
-- Segment 2: Product Performance
-- ========================================================================================== --

-- create the table manually so the raw data doesn't error out on import (Olist products dataset)
CREATE TABLE products (
    product_id VARCHAR(100),
    product_category_name VARCHAR(100),
    product_name_lenght VARCHAR(100),
    product_description_lenght VARCHAR(100),
    product_photos_qty VARCHAR(100),
    product_weight_g VARCHAR(100),
    product_length_cm VARCHAR(100),
    product_height_cm VARCHAR(100),
    product_width_cm VARCHAR(100)
);
-- check the data after import
SELECT * FROM olist_ecommerce.products;
desc products;
SELECT count(*) as total_rows FROM olist_ecommerce.products;

-- temporarily disable safe-update mode so the two queries below can run
SET SQL_SAFE_UPDATES = 0; 				-- disable safe mode
SET SQL_SAFE_UPDATES = 1; 				-- re-enable safe mode
-- when safe mode is on (1), UPDATE/DELETE only runs if the WHERE clause filters on a key/primary-key column or uses LIMIT.
-- disabling it is scoped to this tab/connection only, needed here because the blank-value cleanup query doesn't filter on product_id.

-- clean blank values before converting the columns to numeric types
UPDATE olist_ecommerce.products
SET
  product_name_lenght = NULLIF(TRIM(product_name_lenght), ''),
  product_description_lenght = NULLIF(TRIM(product_description_lenght), ''),
  product_photos_qty = NULLIF(TRIM(product_photos_qty), ''),
  product_weight_g = NULLIF(TRIM(product_weight_g), ''),
  product_length_cm = NULLIF(TRIM(product_length_cm), ''),
  product_height_cm = NULLIF(TRIM(product_height_cm), ''),
  product_width_cm = NULLIF(TRIM(product_width_cm), '');

-- convert the table's column types
ALTER TABLE olist_ecommerce.products
  MODIFY COLUMN product_id CHAR(32) NOT NULL,
  MODIFY COLUMN product_category_name VARCHAR(100) NULL,
  MODIFY COLUMN product_name_lenght SMALLINT UNSIGNED NULL,
  MODIFY COLUMN product_description_lenght SMALLINT UNSIGNED NULL,
  MODIFY COLUMN product_photos_qty SMALLINT UNSIGNED NULL,
  MODIFY COLUMN product_weight_g INT UNSIGNED NULL,
  MODIFY COLUMN product_length_cm SMALLINT UNSIGNED NULL,
  MODIFY COLUMN product_height_cm SMALLINT UNSIGNED NULL,
  MODIFY COLUMN product_width_cm SMALLINT UNSIGNED NULL,
  ADD PRIMARY KEY (product_id);
-- re-check using the query above and confirm the row count matches the RAW file.
-- done — the products dataset is ready to use.

-- create the table manually so the raw data doesn't error out on import (Olist sellers dataset)
CREATE TABLE sellers (
    seller_id VARCHAR(100),
    seller_zip_code_prefix VARCHAR(100),
    seller_city VARCHAR(100),
    seller_state VARCHAR(100)
);
-- check the data after import
SELECT * FROM olist_ecommerce.sellers;
desc sellers;
SELECT count(*) as total_rows FROM olist_ecommerce.sellers;

-- validate / re-check
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT seller_id) AS unique_seller_id,
  SUM(seller_id IS NULL OR CHAR_LENGTH(seller_id) <> 32) AS invalid_seller_id,
  SUM(seller_zip_code_prefix IS NULL
      OR CHAR_LENGTH(seller_zip_code_prefix) <> 5) AS invalid_zip_code,
  SUM(seller_city IS NULL OR TRIM(seller_city) = '') AS invalid_city,
  SUM(seller_state IS NULL OR CHAR_LENGTH(seller_state) <> 2) AS invalid_state
FROM olist_ecommerce.sellers;

-- convert the sellers table's column types
ALTER TABLE olist_ecommerce.sellers
  MODIFY COLUMN seller_id CHAR(32) NOT NULL,
  MODIFY COLUMN seller_zip_code_prefix CHAR(5) NOT NULL,
  MODIFY COLUMN seller_city VARCHAR(100) NOT NULL,
  MODIFY COLUMN seller_state VARCHAR(2) NOT NULL,
  ADD PRIMARY KEY (seller_id);
-- re-check using the query above and confirm the row count matches the RAW file.
-- done — the sellers dataset is ready to use.

-- create the table for product_category_name_translation
CREATE TABLE product_category_name_translation_raw (
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100)
) CHARACTER SET utf8mb4;

-- rename the table
RENAME TABLE product_category_name_translation_raw TO product_category_name_translation;

-- check the data after import (confirm the row count matches the RAW file)
SELECT * FROM olist_ecommerce.product_category_name_translation;

desc product_category_name_translation;

SELECT count(*) as total_rows FROM product_category_name_translation;

SELECT
    COUNT(*) AS total_rows,
    SUM(product_category_name IS NULL) AS null_category,
    SUM(product_category_name_english IS NULL) AS null_english
FROM product_category_name_translation;
-- DONE — the product_category_name_translation dataset is ready to use.

-- ============================================================================= -- 
-- ========= Data quality checks for Segment 2: Product Performance ========== --
-- ============================================================================= -- 

-- DQ1 = check total row counts
SELECT 'products' AS table_name, COUNT(*) AS total_rows
FROM products
UNION ALL
SELECT 'order_items', COUNT(*)
FROM order_items
UNION ALL
SELECT 'translation', COUNT(*)
FROM product_category_name_translation;
	-- results check out
    
-- DQ2 = check for duplicate product_id
SELECT COUNT(*) AS total_rows,
    COUNT(DISTINCT product_id) AS unique_product_id
FROM products;
-- results check out — total rows = unique_product_id (32,951 = 32,951)

-- DQ3 = check for NULLs (should be 0) in products
SELECT
    COUNT(*) AS total_rows,
    SUM(product_id IS NULL OR product_id = '') AS null_product_id,
    SUM(product_category_name IS NULL OR product_category_name = '') AS null_category,
    SUM(product_name_lenght IS NULL OR product_name_lenght = '') AS null_name_length,
    SUM(product_description_lenght IS NULL OR product_description_lenght = '') AS null_description_length,
    SUM(product_photos_qty IS NULL OR product_photos_qty = '') AS null_photos,
    SUM(product_weight_g IS NULL OR product_weight_g = '') AS null_weight,
    SUM(product_length_cm IS NULL OR product_length_cm = '') AS null_length,
    SUM(product_height_cm IS NULL OR product_height_cm = '') AS null_height,
    SUM(product_width_cm IS NULL OR product_width_cm = '') AS null_width
FROM products;

SELECT
    SUM(product_weight_g IS NULL) AS null_weight,
    SUM(product_length_cm IS NULL) AS null_length,
    SUM(product_height_cm IS NULL) AS null_height,
    SUM(product_width_cm IS NULL) AS null_width,
    SUM(product_photos_qty IS NULL) AS null_photos
FROM products;

-- since some products rows are null, dig deeper
-- confirm exactly how many records have a NULL/blank weight.
SELECT
    SUM(product_weight_g IS NULL) AS weight_null,
    SUM(product_weight_g = '') AS weight_empty,
    SUM(product_weight_g = '0') AS weight_zero
FROM products;

-- check whether product_id has any true NULLs
SELECT COUNT(*) AS null_product_id
FROM products
WHERE product_id IS NULL
   OR product_id = '';

-- re-check the six rows above without the OR condition
SELECT
    product_id,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM products
WHERE product_weight_g IS NULL;

SELECT
    product_id,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM products
WHERE product_weight_g = '';

-- DQ4 = check order_items
SELECT
    COUNT(*) AS total_rows,
    SUM(order_id IS NULL OR order_id = '') AS null_order_id,
    SUM(product_id IS NULL OR product_id = '') AS null_product_id,
    SUM(seller_id IS NULL OR seller_id = '') AS null_seller_id,
    SUM(price IS NULL) AS null_price,
    SUM(freight_value IS NULL) AS null_freight
FROM order_items;

-- DQ5 = check the price column
SELECT
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    ROUND(AVG(price), 2) AS avg_price
FROM order_items;
-- then check for any negative values
SELECT COUNT(*) AS negative_price
FROM order_items
WHERE price < 0;

-- check referential integrity
-- confirm every product_id appearing in a transaction actually exists in the products master table
SELECT COUNT(*) AS orphan_items
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- DQ7 = translation coverage
-- since product_category_name_translation_raw already has 71 rows, check whether any product category is missing a translation.
SELECT
    COUNT(DISTINCT p.product_category_name) AS total_categories,
    COUNT(DISTINCT t.product_category_name) AS translated_categories
FROM products p
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND p.product_category_name <> '';
  -- then find the categories that don't have a translation yet:
SELECT DISTINCT
    p.product_category_name
FROM products p
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND p.product_category_name <> ''
  AND t.product_category_name IS NULL
ORDER BY p.product_category_name;

-- DQ8 = check for duplicate order_items
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CONCAT(order_id, '-', order_item_id)) AS unique_item_keys
FROM order_items;

-- since two categories don't have a translation, need to know how many products/items are affected
-- this answers: how many products and units sold actually belong to those two untranslated categories?
SELECT
    p.product_category_name,
    COUNT(DISTINCT p.product_id) AS product_count,
    COUNT(oi.product_id) AS units_sold
FROM products p
LEFT JOIN order_items oi
    ON p.product_id = oi.product_id
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE t.product_category_name IS NULL
  AND p.product_category_name IS NOT NULL
  AND p.product_category_name <> ''
GROUP BY p.product_category_name
ORDER BY units_sold DESC;
-- Segment 2 data quality checks all pass, with the remaining missing values being within expectations.

-- ========================================================================================================== -- 
-- ===== BUSINESS ANALYSIS — SEGMENT 2: PRODUCT PERFORMANCE — ANSWERING THE QUESTIONS DEFINED ABOVE ===== --
-- ========================================================================================================== -- 

-- Q10 = Which product category generates the highest revenue?
SELECT
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Uncategorized'
    ) AS category,
    ROUND(SUM(oi.price), 2) AS revenue
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
GROUP BY
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Uncategorized'
	)
ORDER BY revenue DESC
LIMIT 10;
-- Business insight: health_beauty is the highest-revenue category, 
					-- at roughly R$1.26M, followed by watches_gifts at R$1.21M and bed_bath_table at R$1.04M. 
                    -- This shows Olist's revenue is fairly concentrated among a handful of core categories, 
					-- with health & beauty the strongest at generating sales value.
                    
-- query logic: this joins order_items -> products -> product_category_name_translation. 
				-- order_items is the transaction source since price is the item's sale value, 
                -- products supplies the category via product_id, and the translation table converts Portuguese category names to English. 
                -- SUM(oi.price) then totals revenue per category, 
				-- while GROUP BY aggregates transactions by category.

	-- Q11 = Which product category has the highest unit sales volume?
SELECT
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Uncategorized'
    ) AS category,
    COUNT(*) AS units_sold
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
GROUP BY
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Uncategorized'
    )
ORDER BY units_sold DESC
LIMIT 10;
-- Business insight: bed_bath_table has the highest unit sales volume at 11,115 items, followed by health_beauty at 9,670 items. 
                -- This shows bed & bath table is the category with the highest unit demand on the Olist platform. 
				-- However, high sales volume doesn't necessarily mean the highest revenue, so Q11 needs to be compared against Q10.

-- query logic: this joins order_items to products via product_id to get the category of each item sold. 
				-- COUNT(*) then counts the line items/units sold per category, 
                -- and GROUP BY groups all transactions by category. 
                -- LEFT JOIN to translation is still used so the two categories without a translation are still counted, 
				-- with COALESCE() falling back to the original category name.

	-- Q12 = What are the top 10 products by revenue?
SELECT
    oi.product_id,
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Uncategorized'
    ) AS category,
    ROUND(SUM(oi.price), 2) AS revenue
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
GROUP BY
    oi.product_id,
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Uncategorized'
    )
ORDER BY revenue DESC
LIMIT 10;
-- Business insight: Olist's revenue doesn't come from a single dominant category or product. The top 10 products by revenue span several categories,
					-- with health_beauty contributing two of the top products and the single highest product earning around R$63.9K. 
					-- This shows revenue at the SKU level is fairly spread out, though categories like health & beauty and computers appear more often among the top-revenue products.

-- query logic: order_items is used directly since it already stores product_id and price at the transaction-item level. 
			-- SUM(oi.price) totals sales value per product, then GROUP BY product_id produces each product's total revenue.
            -- ORDER BY revenue DESC sorts products from highest to lowest revenue, and LIMIT 10 takes the top 10. 
            -- This fits Q12 since the comparison needed is between individual products, not categories. 
			-- order_items' structure already has one row per item within an order, with product_id and price.

	-- Q13 = What are the top 10 products by units sold?
SELECT
    oi.product_id,
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Uncategorized'
    ) AS category,
    COUNT(*) AS units_sold
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
GROUP BY
    oi.product_id,
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Uncategorized'
    )
ORDER BY units_sold DESC
LIMIT 10;
-- Business insight: the top products by sales volume are dominated by furniture_decor, bed_bath_table, and garden_tools, with the best-seller reaching 527 units. 
					-- However, this pattern differs from Q12, where the highest-revenue product came from health_beauty. 
                    -- This shows the best-selling product isn't necessarily the highest-revenue one,
					-- since revenue is also shaped by each product's price.

-- query logic: order_items is the primary source since each row represents one item sold. 
				-- COUNT(*) counts the units sold per product_id, 
				-- then GROUP BY groups the transactions by product. products supplies the category, 
                -- while LEFT JOIN to translation and COALESCE() keep products whose category has no translation in the results. 
				-- ORDER BY units_sold DESC sorts by highest units sold, and LIMIT 10 takes the top 10 products.

	-- Q14 = Which product has the highest average price?
SELECT
    oi.product_id,
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Uncategorized'
    ) AS category,
    ROUND(AVG(oi.price), 2) AS avg_price,
    COUNT(*) AS units_sold
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
GROUP BY
    oi.product_id,
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Uncategorized'
    )
ORDER BY avg_price DESC
LIMIT 10;
-- Business insight: the highest-average-price products fall in the R$4,000–R$6,735 range, with the priciest product at R$6,735. 
					-- However, every product in this top 10 sold exactly one unit, so a high average price alone doesn't indicate strong demand.
                    -- This points to a high-value, low-volume product segment, 
					-- so the strategy for these products shouldn't be judged on sales volume alone.

-- query logic: AVG(oi.price) calculates each product's average price based on every recorded transaction, 
				-- while GROUP BY product_id keeps the calculation at the product level. products and translation are only used to show a more informative category name. 
            -- COUNT(*) AS units_sold is added for context, since a product with a high average price isn't necessarily sold often. 
				-- ORDER BY avg_price DESC then sorts products from highest to lowest average price.

    -- Q15. Which category has the highest average product price?
SELECT
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Uncategorized'
    ) AS category,
    ROUND(AVG(oi.price), 2) AS avg_price,
    COUNT(*) AS units_sold
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
GROUP BY
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Uncategorized'
    )
ORDER BY avg_price DESC
LIMIT 10;
-- Business insight: the computers category has the highest average transaction price, around R$1,098 per item, far above the second-place category at around R$624. 
					-- However, its sales volume is only 203 units. In contrast, watches_gifts has a much lower average price, around R$201, but records nearly 6,000 units sold. 
					-- This shows a category with a high average price doesn't automatically have high sales volume.

-- query logic: AVG(oi.price) calculates the average price of items sold within each category, then GROUP BY shifts the analysis level from product to category. 
            -- JOIN products is needed to get the category from product_id, while LEFT JOIN translation + COALESCE() keep categories without a translation in the results. 
            -- COUNT(*) is deliberately included as volume context, so we can see whether a high-average-price category is also genuinely high-volume. 
			-- order_items' structure already provides product_id and price at the transaction-item level.

    -- Q16. Which category has the most products?
SELECT
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Uncategorized'
    ) AS category,
    COUNT(DISTINCT p.product_id) AS product_count
FROM products p
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND p.product_category_name <> ''
GROUP BY
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Uncategorized'
    )
ORDER BY product_count DESC
LIMIT 10;
-- Business insight: the category with the most products shows which category has the widest assortment on the marketplace. 
					-- bed_bath_table takes the top spot again, meaning this category isn't just high in transaction volume as seen in Q11, but also has a large catalog base. 
					-- However, having many products doesn't automatically mean high revenue, since SKU count only shows the breadth of choice, not sales performance.

-- query logic: products is the primary source since we want to count products available in the catalog, not transactions. 
			-- COUNT(DISTINCT p.product_id) ensures each product is only counted once, 
            -- then GROUP BY category produces the product count per category. 
            -- LEFT JOIN to translation keeps categories without a translation in the results, 
            -- while COALESCE() uses the English name where available and falls back to the original name otherwise. 
			-- WHERE excludes rows with a genuinely blank category so they don't show up as a meaningless group.
            
    -- Q17. Does the category with the highest sales volume also generate the highest revenue?
WITH category_sales AS (
    SELECT
        COALESCE(
            t.product_category_name_english,
            p.product_category_name,
            'Uncategorized'
        ) AS category,
        COUNT(*) AS units_sold,
        ROUND(SUM(oi.price), 2) AS revenue
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    LEFT JOIN product_category_name_translation t
        ON p.product_category_name = t.product_category_name
    GROUP BY
        COALESCE(
            t.product_category_name_english,
            p.product_category_name,
            'Uncategorized'
        )
)
SELECT
    category,
    units_sold,
    revenue,
    RANK() OVER (ORDER BY units_sold DESC) AS unit_rank,
    RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
FROM category_sales
ORDER BY unit_rank;
-- Business insight: the category with the highest sales volume isn't always the top revenue contributor. bed_bath_table records the highest units sold at 11,115 units, 
					-- while health_beauty generates the highest revenue at R$1.26M despite a lower sales volume. 
					-- This shows revenue performance isn't determined by sales volume alone, but also by the transaction value per item.

-- query logic: the first CTE builds a per-category sales summary using COUNT(*) for units sold and SUM(price) for revenue.
					-- RANK() OVER() is then used twice to rank by volume and by revenue separately. 
                -- This approach was chosen because Q17 isn't just asking which category has the highest value, but whether the volume leader is also the revenue leader. 
                -- Having both rankings in one table makes the difference visible immediately, without manually comparing the Q10 and Q11 results. 
				-- This same ranking pattern is reused elsewhere in the Olist analysis to compare sales volume against revenue.

-- ================================== Segment 2 Business Insight Summary: Product Performance ===================================== -- 
-- Olist's product performance shows sales volume and revenue don't always move together. 
-- health_beauty is the revenue leader at around R$1.26M, while bed_bath_table has the highest units sold at around 11,115 units. 
-- Meanwhile, the highest-priced product reaches R$6,735 but sold only one unit. 
-- In other words, Olist's revenue is driven by a combination of sales volume and per-unit transaction value.
-- This means Olist's product portfolio strategy needs to distinguish between categories strong in volume, 
-- categories strong in transaction value, and categories that are genuinely the main revenue drivers.
-- ================================================================================================================================== --
