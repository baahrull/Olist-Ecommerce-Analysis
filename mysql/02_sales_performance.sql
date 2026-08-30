-- ========================================================================================== --
-- Segment 1: Sales Performance
-- ========================================================================================== --
	-- check the data after import (for order_items and order_payments)
SELECT * FROM order_items 
LIMIT 10;

SELECT COUNT(*) AS total_orders_items
FROM order_items;

SELECT * FROM order_payments
LIMIT 10;

SELECT COUNT(*) AS total_order_payments 
FROM order_payments;
	
    -- use DESCRIBE to check table structure
describe orders;

describe customers;

describe order_items;

describe order_payments;

	-- how to modify an existing table
alter table order_items
	modify order_id varchar(100),
	modify order_item_id int,
    modify product_id varchar(100),
    modify seller_id varchar (100);
    
alter table order_items
	modify order_item_id int;
    
	-- identify data issues: check for NULLs (should be 0)
		-- orders is chosen here because almost all Segment 1 questions rely on order_id and the order date
SELECT
    COUNT(*) AS total_rows,
    COUNT(order_id) AS total_order_id,
    COUNT(customer_id) AS total_customer_id,
    COUNT(order_status) AS total_order_status,
    COUNT(order_purchase_timestamp) AS total_purchase_date
FROM orders;

	-- check for duplicates — an empty result set means no duplicates
SELECT order_id, COUNT(*) AS total
FROM orders GROUP BY order_id
HAVING COUNT(*) > 1;

	-- check order status values
SELECT order_status, COUNT(*) AS total_orders
FROM orders GROUP BY order_status
ORDER BY total_orders DESC;

	-- check the data's date range, since Q4–Q9 all involve time, so we need to know the dataset's period
SELECT
    MIN(order_purchase_timestamp) AS start_date,
    MAX(order_purchase_timestamp) AS end_date
FROM orders;

	-- check the relationship between orders and customers (customer relationship)
SELECT
    COUNT(DISTINCT customer_id) AS unique_customer_id,
    COUNT(*) AS total_orders
FROM orders;

	-- does every customer_id in orders have a match in customers?
		-- LEFT JOIN keeps all rows from orders (the left table)
			-- every customer_id in orders has a match in customers, since the result is 0.
SELECT COUNT(*) AS unmatched_orders
FROM orders AS o
LEFT JOIN customers AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

	-- now check the order_items table
		-- if all row counts match, the data is clean / has no NULLs.
SELECT
    COUNT(*) AS total_rows,
    COUNT(order_id) AS total_order_id,
    COUNT(order_item_id) AS total_order_item_id,
    COUNT(product_id) AS total_product_id,
    COUNT(seller_id) AS total_seller_id,
    COUNT(shipping_limit_date) AS total_shipping_date,
    COUNT(price) AS total_price,
    COUNT(freight_value) AS total_freight
FROM order_items;

	-- check for negative values: "are there any negative prices or freight charges?"
		-- since price and freight_value are monetary figures, we need to confirm there are no odd negative values
			-- MIN() finds the smallest value, MAX() finds the largest
SELECT
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    MIN(freight_value) AS min_freight,
    MAX(freight_value) AS max_freight
FROM order_items;

	-- also check for duplicates at the order_id + order_item_id level, since these two columns repeat often
select order_id, order_item_id, count(*) as total 
from order_items group by order_id, order_item_id 
having count(*) >1;
		-- no duplicates found on the order_id + order_item_id combination, since the result is an empty set

	-- now check the quality of the order_payments dataset
SELECT
    COUNT(*) AS total_rows,
    COUNT(order_id) AS total_order_id,
    COUNT(payment_sequential) AS total_payment_sequential,
    COUNT(payment_type) AS total_payment_type,
    COUNT(payment_installments) AS total_installments,
    COUNT(payment_value) AS total_payment_value
FROM order_payments;

	-- check payment values — looking for anything suspicious, like a negative payment or an unreasonable installment count
SELECT
    MIN(payment_value) AS min_payment,
    MAX(payment_value) AS max_payment,
    MIN(payment_installments) AS min_installments,
    MAX(payment_installments) AS max_installments
FROM order_payments;

	-- does every row in order_items have a matching order?
		-- logic: order_items LEFT JOIN orders keeps all items
        -- logic: WHERE o.order_id IS NULL filters down to unmatched rows
SELECT COUNT(*) AS unmatched_items
FROM order_items AS oi
LEFT JOIN orders AS o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

	-- does every payment have a matching order?
SELECT COUNT(*) AS unmatched_payments
FROM order_payments AS op
LEFT JOIN orders AS o
    ON op.order_id = o.order_id
WHERE o.order_id IS NULL;

	-- next, check which orders have no items
SELECT COUNT(*) AS orders_without_items
FROM orders AS o
LEFT JOIN order_items AS oi
    ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL;

	-- since 'does every order_item have an order?' and 'does every payment have an order?' both returned mismatches ≠ 0,
    -- need to first check whether orders itself has already been filtered by inspecting the customer/order table
SELECT COUNT(DISTINCT order_id) AS total_unique_orders
FROM orders;
	
    -- then check whether some order_items rows reference an order that no longer exists in orders
		-- since the status is missing from the orders table, we can't see the original status directly.
		-- but we can see how many unique orders in order_items are missing from orders.
SELECT COUNT(DISTINCT oi.order_id) AS unmatched_orders
FROM order_items AS oi
LEFT JOIN orders AS o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

	-- since there's a mismatch, need to re-inspect the raw orders data
SELECT order_status, COUNT(*) AS total_orders
FROM orders
GROUP BY order_status 
ORDER BY total_orders DESC;
	-- the raw Olist dataset has 99,441 orders and 8 order_status categories:
    -- delivered, invoiced, shipped, processing, unavailable, canceled, created, and approved.
    -- so the 2,205 orders in order_items that don't match orders doesn't mean order_items is broken.
    -- the actual problem is that our orders table has already lost some orders (because it was filtered somewhere).

	-- first fix: back up the current (problematic) dataset via CREATE TABLE
    -- the safest approach is to restore orders from the raw dataset, since order_items and order_payments still carry the full raw transaction set.
CREATE TABLE orders_backup AS
SELECT * FROM orders;
	-- after creating the table, confirm the backup row count matches the current orders table
SELECT COUNT(*) AS total_backup
FROM orders_backup;

SELECT COUNT(*) as total_orders
FROM orders;
    -- confirm the counts match (96,461 rows)

	-- step 2: rename the old (filtered) table to orders_filtered so the new dataset can take its place
rename table orders to orders_filtered;
show tables;
    
    -- step 3: re-import the raw orders dataset so the filtered file exists again, then re-check (fine if this 3rd check matches)
SELECT COUNT(*) AS total_orders_filtered FROM orders_filtered; 
SELECT COUNT(*) AS total_orders_backup FROM orders_backup;
SELECT COUNT(*) AS total_orders_raw FROM orders; -- this one is mandatory to check, the others are optional
    	-- remember COUNT(*) counts every row in orders — we want to know the order count after re-importing the raw file.

	-- step 4: check whether order_items now has valid matching orders
SELECT COUNT(*) AS unmatched_items FROM order_items AS oi
LEFT JOIN orders AS o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;
	-- logic: take all order_items, look for a match in orders. If none is found, o.order_id becomes NULL.
	-- so we're counting how many items have no matching order.
	-- the LEFT JOIN ... WHERE right_table.id IS NULL pattern is used specifically to find rows with no match in the right-hand table.

	-- step 5: check order_payments — does it have valid matching orders?
SELECT COUNT(*) AS unmatched_payments FROM order_payments AS op
LEFT JOIN orders AS o
    ON op.order_id = o.order_id
WHERE o.order_id IS NULL;
	-- same logic as step 4, but now looking for payments whose order_id isn't found in orders.
    
    -- step 6: check orders — does every order have a matching customer?
SELECT COUNT(*) AS unmatched_customers FROM orders AS o
LEFT JOIN customers AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
	-- for each order, look up its customer.
    -- if the customer isn't found in the customers table, that order has a customer_id with no match.

	-- step 7: check for duplicate order_id
SELECT order_id, COUNT(*) AS total FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;
	-- important because this was already checked and returned empty earlier, but re-checking now that orders is back to normal

	-- since there's still a mismatch, it needs to be broken down further.
SELECT DISTINCT oi.order_id
FROM order_items AS oi
LEFT JOIN orders AS o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL
LIMIT 20;
	-- logic: take the order_id from order_items, look for a match in orders. If none is found, show it.
	-- the safest move is to inspect the actual unmatched order_id values — this gives sample IDs from the 2,470 found earlier (step 4)
    -- then we can check whether those IDs actually exist in the unfiltered raw dataset.

-- the strongest hypothesis for this mismatch is: "the current orders table is the result of some filtering applied to the raw dataset,"
-- so some order_id values still present in order_items and order_payments no longer have a match in the filtered orders table.

	-- now validate that instead of just assuming it
    -- step 1: total rows in order_items vs. unique order_id
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders
FROM order_items;
	-- to see the total order_items rows and how many unique order_id values exist
	-- then (2)
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders
FROM order_payments;	
	-- and (3)
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders
FROM orders;

	-- takeaway from this stage
		-- COUNT(*) -> row count
		-- COUNT(DISTINCT order_id) -> unique order count
		-- LEFT JOIN ... IS NULL -> finds rows with no match
		-- GROUP BY ... HAVING COUNT(*) > 1 -> finds duplicates
		-- and now we've confirmed that filtering the parent table (orders) can create an apparent mismatch in the child tables.

	-- data quality / cleaning: break down the mismatch in orders
SELECT COUNT(*) AS total_orders
FROM orders;

SELECT DISTINCT oi.order_id
FROM order_items AS oi
LEFT JOIN orders AS o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL
LIMIT 20;

SELECT DISTINCT op.order_id
FROM order_payments AS op
LEFT JOIN orders AS o
    ON op.order_id = o.order_id
WHERE o.order_id IS NULL
LIMIT 20;

SELECT *
FROM orders_backup
WHERE order_id = '002f19a65a2ddd70a090297872e6d64e';

SELECT *
FROM orders_backup
WHERE order_id = '5d9c5817e278892b7498d90bfa28ade8';

SELECT order_id
FROM orders_backup
WHERE order_id IN (
    '002f19a65a2ddd70a090297872e6d64e',
    '00310b0c75fb13015ec46d2d341865a4',
    '00a99c50dff7e36262caba33821875a',
    '00ae7ab84938674ebb7014a23719a79'
);

SELECT 
    'orders' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders
FROM orders
UNION ALL
SELECT 
    'orders_backup',
    COUNT(*),
    COUNT(DISTINCT order_id)
FROM orders_backup
UNION ALL
SELECT 
    'orders_filtered',
    COUNT(*),
    COUNT(DISTINCT order_id)
FROM orders_filtered;

SELECT COUNT(*) AS orders_not_in_backup
FROM orders o
LEFT JOIN orders_backup ob
    ON o.order_id = ob.order_id
WHERE ob.order_id IS NULL;

SELECT COUNT(*) AS backup_not_in_orders
FROM orders_backup ob
LEFT JOIN orders o
    ON ob.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT COUNT(*) AS orders_not_in_filtered
FROM orders o
LEFT JOIN orders_filtered f
    ON o.order_id = f.order_id
WHERE f.order_id IS NULL;

SELECT COUNT(*) AS filtered_not_in_orders
FROM orders_filtered f
LEFT JOIN orders o
    ON f.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT 
    oi.order_id
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL
LIMIT 20;

SELECT *
FROM orders_backup
WHERE order_id = '002f19a65a2ddd70a090297872e6d64e';

SELECT
    COUNT(DISTINCT oi.order_id) AS unmatched_unique_orders,
    COUNT(DISTINCT ob.order_id) AS found_in_backup
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
LEFT JOIN orders_backup ob
    ON oi.order_id = ob.order_id
WHERE o.order_id IS NULL;

	-- now check, for order_items, whether the 2,205 orders are spread randomly or follow a pattern.
SELECT
    COUNT(*) AS unmatched_rows,
    COUNT(DISTINCT oi.order_id) AS unmatched_orders,
    COUNT(DISTINCT oi.product_id) AS unmatched_products
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

	-- also check: of the 2,205 orphan orders in order_items, do the same orders also appear in order_payments?
SELECT
    COUNT(DISTINCT oi.order_id) AS orphan_item_orders,
    COUNT(DISTINCT op.order_id) AS orphan_payment_orders,
    COUNT(DISTINCT
        CASE
            WHEN op.order_id IS NOT NULL
            THEN oi.order_id
        END
    ) AS overlap_orders
FROM (
    SELECT DISTINCT oi.order_id
    FROM order_items oi
    LEFT JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.order_id IS NULL
) oi
LEFT JOIN (
    SELECT DISTINCT op.order_id
    FROM order_payments op
    LEFT JOIN orders o
        ON op.order_id = o.order_id
    WHERE o.order_id IS NULL
) op
    ON oi.order_id = op.order_id;

	-- most likely explanation: the current orders table has already been through some filtering,
	-- while order_items and order_payments still carry transactions from the more complete raw dataset.

-- breaking down orders_filtered:
SHOW TABLES;

SHOW CREATE TABLE orders_filtered;
-- identify what actually happened
SELECT
    order_status,
    COUNT(*) AS total_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- find the status of the MISSING orders
-- build a distribution of orders that exist in order_payments but not in orders.
SELECT
    CASE
        WHEN o.order_id IS NULL THEN 'NOT_IN_ORDERS'
        ELSE 'IN_ORDERS'
    END AS order_status_group,
    COUNT(DISTINCT op.order_id) AS unique_orders
FROM order_payments op
LEFT JOIN orders o
    ON op.order_id = o.order_id
GROUP BY
    CASE
        WHEN o.order_id IS NULL THEN 'NOT_IN_ORDERS'
        ELSE 'IN_ORDERS'
    END; -- 96,460 + 2,980 = 99,440 — now we have the real gap number.
    
-- cross-check: since order_items has 2,205 orphans,
-- want to confirm whether that 2,205 is a subset of the 2,979 orders missing from payments.
    SELECT
    COUNT(DISTINCT oi.order_id) AS orphan_item_orders,
    COUNT(DISTINCT op.order_id) AS orphan_orders_in_both
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
LEFT JOIN order_payments op
    ON oi.order_id = op.order_id
WHERE o.order_id IS NULL;
	-- after these two queries, we'll know the actual size of the gap --
    -- and how order_items and order_payments relate to that gap --

-- one more cross-check
SELECT
    COUNT(DISTINCT op.order_id) AS payment_not_in_orders,

    COUNT(DISTINCT CASE
        WHEN oi.order_id IS NOT NULL
        THEN op.order_id
    END) AS payment_and_items,

    COUNT(DISTINCT CASE
        WHEN oi.order_id IS NULL
        THEN op.order_id
    END) AS payment_only
FROM order_payments op
LEFT JOIN orders o
    ON op.order_id = o.order_id
LEFT JOIN order_items oi
    ON op.order_id = oi.order_id
WHERE o.order_id IS NULL;
	-- the 2,205 orders previously found as orphans in order_items
    -- turn out to be a subset of the 2,980 orders missing from orders.

-- the fix: re-import the orders dataset with every column as TEXT / VARCHAR,
-- because date-type columns in the RAW CSV can throw errors (and silently drop rows) if imported directly as DATETIME.
-- also make sure the delimiter used on import matches the raw file's delimiter — e.g. if the CSV uses "," then SQL import should too.

-- step 1: recreate the table (or import straight into olist_ecommerce) with every column as text
CREATE TABLE orders_raw (
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    order_status VARCHAR(30),
    order_purchase_timestamp VARCHAR(30),
    order_approved_at VARCHAR(30),
    order_delivered_carrier_date VARCHAR(30),
    order_delivered_customer_date VARCHAR(30),
    order_estimated_delivery_date VARCHAR(30)
);

-- after importing, check the table structure
desc orders_raw;

-- check total rows
select count(*) as total_rows
from orders_raw;

-- check order status
SELECT
    order_status,
    COUNT(*) AS total_orders
FROM orders_raw
GROUP BY order_status
ORDER BY total_orders DESC;

-- check whether order_id is fully unique
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_order_id
FROM orders_raw;

-- build the final orders table by cleaning/converting date-time columns to DATETIME
CREATE TABLE orders_final AS
SELECT
    order_id,
    customer_id,
    order_status,

    STR_TO_DATE(
        NULLIF(order_purchase_timestamp, ''),
        '%Y-%m-%d %H:%i:%s'
    ) AS order_purchase_timestamp,

    STR_TO_DATE(
        NULLIF(order_approved_at, ''),
        '%Y-%m-%d %H:%i:%s'
    ) AS order_approved_at,

    STR_TO_DATE(
        NULLIF(order_delivered_carrier_date, ''),
        '%Y-%m-%d %H:%i:%s'
    ) AS order_delivered_carrier_date,

    STR_TO_DATE(
        NULLIF(order_delivered_customer_date, ''),
        '%Y-%m-%d %H:%i:%s'
    ) AS order_delivered_customer_date,

    STR_TO_DATE(
        NULLIF(order_estimated_delivery_date, ''),
        '%Y-%m-%d %H:%i:%s'
    ) AS order_estimated_delivery_date

FROM orders_raw;

-- final check on row count
SELECT COUNT(*) AS total_rows FROM orders;
select * from orders;
desc orders;

-- drop the old orders table and rename the clean one to take its place
	drop table orders;
	rename table orders_final to orders;

-- re-validate
SELECT order_status,COUNT(*) AS total_orders
FROM orders GROUP BY order_status
ORDER BY total_orders DESC;
-- or 
SELECT COUNT(*) AS total_rows FROM orders;
select * from orders;
desc orders;

-- drop the other leftover tables to keep things clean
	-- DROP TABLE orders_backup;
	-- DROP TABLE orders_filtered;
	-- DROP TABLE orders_raw;

-- ========================================================================================================== -- 
-- ===== BUSINESS ANALYSIS — SEGMENT 1: SALES PERFORMANCE — ANSWERING THE QUESTIONS DEFINED ABOVE ===== --
-- ========================================================================================================== -- 

	-- Q1. What is Olist's total revenue?
-- the core answer:
SELECT
ROUND(SUM(price), 2) AS total_revenue 
FROM order_items;
	-- Olist's total revenue = 13,591,643.70
-- why SUM(price)? because each row in order_items represents one item sold, and price is that item's price.
-- additional breakdown: 
SELECT
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(SUM(oi.freight_value), 2) AS total_freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_sales_value
FROM orders o JOIN order_items oi
    ON o.order_id = oi.order_id; 
-- note: total_sales_value = total_freight + total_revenue
		-- Olist generates roughly R$13.60M in product revenue, plus another R$2.25M from freight,
		-- bringing total sales value to R$15.85M.
        
	-- Q2. How many total orders were successfully placed?
SELECT COUNT(DISTINCT order_id) AS total_orders
FROM orders;
		-- Olist's total_orders = 99,441
			-- why COUNT(DISTINCT)? because the business question is "how many total orders were placed?"
			-- meaning we want the number of unique orders, not the row count from a JOIN or item-level detail.
			-- since each order_id could in theory repeat or a single order could have multiple related rows.
	-- Q2 validation: confirm there's no duplicate order_id
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_rows
FROM orders;	
-- Result: total rows = unique orders (99,441 = 99,441).
-- Validation confirms there are no duplicate order_id values.
	-- Conclusion: Olist recorded 99,441 unique orders across the observed period.
			-- This very large transaction count shows Olist's sales activity is driven by high order volume,
			-- making order count one of the key components of total sales.
            
            
	-- Q3. How many total products/items were sold?
SELECT
    COUNT(*) AS total_items_sold
FROM order_items;
	-- total_items_sold = 112,650
-- or in more detail:
SELECT
    COUNT(*) AS total_order_sold,
    COUNT(DISTINCT order_id) AS orders_with_items,
    COUNT(DISTINCT product_id) AS unique_products
FROM order_items;
		-- note: total items sold relates to both orders-with-items and unique products
		-- conclusion: The volume of items sold reflects Olist's high level of trading activity and is one of the building blocks of revenue. 
				-- However, its actual impact on revenue depends on each product's price.

		-- Q4. How has order volume trended over time?
SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS period,
    COUNT(DISTINCT order_id) AS total_orders
FROM orders
GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
ORDER BY period;
		-- below is the yearly summary
SELECT
    YEAR(order_purchase_timestamp) AS year,
    COUNT(DISTINCT order_id) AS total_orders
FROM orders
GROUP BY YEAR(order_purchase_timestamp)
ORDER BY year;
		-- the month with the highest and lowest order count overall
SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS period,
    COUNT(DISTINCT order_id) AS total_orders
FROM orders
GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
ORDER BY total_orders DESC;
-- conclusion: Order volume growth shows Olist successfully increased its transaction activity over time. 
				-- However, since order counts fluctuate month to month, 
				-- this volume growth needs to be viewed alongside revenue and average order value 
                -- to see whether the growth in volume also translated into higher sales value.
			
		-- Q5. How has revenue trended over time?
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS period,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_sales_value
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY period;
		-- re-validate Q5
SELECT
    ROUND(SUM(price), 2) AS total_product_revenue,
    ROUND(SUM(freight_value), 2) AS total_freight,
    ROUND(SUM(price + freight_value), 2) AS total_sales_value
FROM order_items;
	-- conclusion: Olist's total sales value across the observed period reaches 15,843,553.24, 
				-- made up of 13,591,643.70 in product revenue and 2,251,909.54 in freight revenue. 
				-- Revenue clearly trends upward as order activity grows over the period,
                -- despite month-to-month fluctuations.

	-- Q6. Which month/year generated the highest revenue?
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
    ROUND(SUM(oi.price), 2) AS revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY revenue DESC
LIMIT 1;
		-- conclusion: November 2017 is the month with the highest product revenue, at R$1,010,271.37.
						-- but if we include freight in the total, the answer shifts slightly:
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS period,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_sales_value
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY total_sales_value DESC
LIMIT 1;
	-- R$1,179,143.77 (product revenue + freight) − R$1,010,271.37 (product revenue only) = R$168,872.40
-- Insight: November 2017 is Olist's peak sales month, with R$1.01M in product revenue. 
				-- Freight adds another R$168.87K, bringing total transaction value to R$1.18M —
				-- showing that the sales spike in that period came with a meaningful freight-cost contribution.
    
    -- Q7. What is the average order value?
SELECT
    ROUND(AVG(total_order_value), 2) AS avg_order_value
FROM (
    SELECT
        order_id,
        SUM(price) AS total_order_value
    FROM order_items
    GROUP BY order_id
) AS order_summary;
-- conclusion: With an average order value of R$137.75, Olist's typical product transaction value is around R$138 per order. 
				-- That means revenue can be grown from two angles: 
            -- increasing the number of orders, and increasing the average spend per order.

	-- Q8. How does revenue compare month over month?
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS period,
    ROUND(SUM(oi.price), 2) AS revenue
FROM orders AS o
JOIN order_items AS oi
    ON o.order_id = oi.order_id
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY period;
-- conclusion: Olist's revenue shows a strong growth trend across the observed period, 
				-- with sales activity accelerating from 2017 onward. 
            -- Despite month-to-month fluctuations, revenue performance from late 2017 through 2018
            -- shows the business reached a much higher sales volume than in the earlier period.
	
    -- Q9. Does order growth move in line with revenue growth?
SELECT
    periode,
    total_orders,
    revenue,
    ROUND(
        (total_orders - previous_orders)
        / previous_orders * 100,
        2
    ) AS order_growth_pct,
    ROUND(
        (revenue - previous_revenue)
        / previous_revenue * 100,
        2
    ) AS revenue_growth_pct
FROM (
    SELECT
        periode,
        total_orders,
        revenue,
        LAG(total_orders) OVER (ORDER BY periode) AS previous_orders,
        LAG(revenue) OVER (ORDER BY periode) AS previous_revenue
    FROM (
        SELECT
            DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS periode,
            COUNT(DISTINCT o.order_id) AS total_orders,
            ROUND(SUM(oi.price), 2) AS revenue
        FROM orders AS o
        JOIN order_items AS oi
            ON o.order_id = oi.order_id
        GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
    ) AS monthly_data
) AS growth_data
ORDER BY periode;
-- conclusion: Order growth generally moves in the same direction as revenue growth, 
				-- though there are periods where the two diverge. 
				-- This shows Olist's revenue isn't driven by order count alone, 
				-- but also by shifts in the average transaction value per order.

-- ============================== Segment 1 Business Insight Summary: Sales Performance ========================================== --
-- Olist grew sales primarily through transaction volume growth,
-- but the data shows revenue doesn't depend on order count alone. Changes in per-order transaction value also play a role, 
-- so a sales-growth strategy shouldn't focus only on acquiring more orders, but also on increasing order value.
-- ================================================================================================================================ --	
