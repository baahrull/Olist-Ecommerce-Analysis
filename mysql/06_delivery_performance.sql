-- ========================================================================================== --
-- Segment 5: Delivery Performance
-- ========================================================================================== --

-- create the table for order_reviews, needed for Q40
CREATE TABLE order_reviews (
    review_id VARCHAR(100),
    order_id VARCHAR(100),
    review_score text, -- should be INT/integer
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date text, -- should be DATETIME
    review_answer_timestamp text -- should be DATETIME
); -- total rows in the raw data: 99,224
-- note: every column is initially created as text/varchar to minimize row loss/failure during import.

-- check the order_reviews dataset after import (confirm total rows = 99,224)
SELECT * FROM olist_ecommerce.order_reviews;
desc order_reviews;
SELECT count(*) as total_rows FROM olist_ecommerce.order_reviews;

-- enable manual import from a local device
SET GLOBAL local_infile = 0;

SET GLOBAL local_infile = 1;

-- manual import from local device — requires SET GLOBAL local_infile = 1 and OPT_local_infile = 1 in the connection settings
LOAD DATA LOCAL INFILE '/path/to/your/dataset/olist_order_reviews_dataset.csv'
INTO TABLE order_reviews
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(review_id, order_id, review_score,
 @review_comment_title, @review_comment_message,
 @review_creation_date, @review_answer_timestamp)
SET
  review_comment_title    = NULLIF(@review_comment_title,''),
  review_comment_message  = NULLIF(@review_comment_message,''),
  review_creation_date    = NULLIF(@review_creation_date,''),
  review_answer_timestamp = NULLIF(@review_answer_timestamp,'');
-- then re-check whether the total row count matches the raw data

-- then convert the order_reviews column types (matching each column's actual type)
ALTER TABLE order_reviews
    modify review_score INT,
    modify review_creation_date DATETIME, 
    modify review_answer_timestamp DATETIME; 

-- re-check the row count; any warnings here mean it's worth double-checking
show warnings;

-- check for odd review_score values (should only be 1-5)
SELECT COUNT(*) AS score_invalid
FROM order_reviews
WHERE review_score NOT BETWEEN 1 AND 5 OR review_score IS NULL;

-- check for review_creation_date values that became a zero-date or NULL
SELECT COUNT(*) AS creation_date_invalid
FROM order_reviews
WHERE CAST(review_creation_date AS CHAR) = '0000-00-00 00:00:00'
   OR review_creation_date IS NULL;

-- check for review_answer_timestamp values that became a zero-date or NULL
SELECT COUNT(*) AS answer_timestamp_invalid
FROM order_reviews
WHERE CAST(review_answer_timestamp AS CHAR) = '0000-00-00 00:00:00'
   OR review_answer_timestamp IS NULL;
-- DONE — order_reviews dataset is clean and ready for analysis.

-- =================================================================================================================== -- 
-- ===== BUSINESS ANALYSIS — SEGMENT 5: DELIVERY PERFORMANCE — ANSWERING THE QUESTIONS DEFINED ABOVE ===== --
-- =================================================================================================================== -- 

	-- Q32. What is the average delivery time to customers?
SELECT 
    ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 1) AS avg_delivery_days
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;
-- Insight: overall, Olist takes an average of 12.5 days from order placement to delivery. 
		-- this number becomes the main baseline for evaluating delivery performance by region and period.

-- Logic: DATEDIFF(delivered, purchase) computes the day difference between the two dates, then
		-- it's averaged across every order with a delivered status (IS NOT NULL).

	-- Q33. How many orders were delivered?
SELECT COUNT(*) AS total_delivered
FROM orders
WHERE order_status = 'delivered';
-- insight and logic for Q33-34 are combined under Q34.

	-- Q34. How many orders were canceled?
SELECT COUNT(*) AS total_canceled
FROM orders
WHERE order_status = 'canceled';
-- Insight: out of 99,441 total orders, 96,478 (97%) were successfully delivered, and only 625 (0.6%) were canceled.
	-- meaning Olist's fulfillment rate is healthy, with the remainder (~2,300 orders) likely sitting in other statuses (shipped, processing, unavailable, etc.).

-- Logic: a simple COUNT(*) filtered by each order_status.

	-- Q35. How many orders were late?
SELECT COUNT(*) AS total_late
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date > order_estimated_delivery_date;
-- insight and logic for Q35-36 are combined under Q36.

	-- Q36. What percentage of orders were late?
SELECT 
    ROUND(
        SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END)
        / COUNT(*) * 100, 2
    ) AS pct_late
FROM orders
WHERE order_status = 'delivered';
-- Insight: of all delivered orders, roughly 1 in 12 arrives later than estimated. This 8.11% figure is a key logistics KPI,
		-- and against a healthy e-commerce industry benchmark of under 5-10% late, Olist sits in an "acceptable" zone with room to improve.

-- Logic: comparing order_delivered_customer_date > order_estimated_delivery_date — if the actual date is later than the estimate, it's late. 
		-- CASE WHEN...THEN 1 ELSE 0 converts the condition into a number so it can be SUM'd and divided by COUNT(*) to get a percentage.

	-- Q37. Which state has the longest average delivery time?
SELECT 
    c.customer_state,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 1) AS avg_delivery_days,
    COUNT(*) AS total_orders
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_days DESC;
-- Insight: northern states like RR, AP, and AM have the longest average delivery times.
		-- this pattern points to geographic logistics challenges worth attention, 
		-- though the specific cause can't be pinned down from this data alone.

-- Logic: JOIN orders to customers via customer_id to get customer_state, 
		-- then GROUP BY state and AVG(DATEDIFF(...)) per group, sorted DESC so the longest delivery times appear first.

    -- Q38. Which state has the highest late-delivery rate?
SELECT 
    c.customer_state,
    COUNT(*) AS total_order,
    SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) AS total_late,
    ROUND(
        SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END)
        / COUNT(*) * 100, 2
    ) AS pct_late
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
HAVING total_order >= 30      -- filter out states with too few orders so the percentage isn't skewed
ORDER BY pct_late DESC;
-- Insight: AL has the highest late-delivery rate at 23.93%, despite not being the state with the longest average delivery time. 
		-- this shows delivery issues aren't just about how long delivery takes, 
		-- but also about the system's ability to meet the estimate given to the customer. 
		-- this pattern suggests the delivery-estimation formula or the operational process in that state needs further review.

-- Logic: same as Q37, but SUM(CASE WHEN late THEN 1 ELSE 0 END) divided by COUNT(*). 
		-- HAVING total_order >= 30 excludes small states so the percentage isn't skewed (a state with only 5 orders and 2 late = 40%, which isn't representative).

	-- Q39. How has delivery performance trended over time?
SELECT 
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS month,
    ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 1) AS avg_delivery_days,
    ROUND(
        SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END)
        / COUNT(*) * 100, 2
    ) AS pct_late
FROM orders
WHERE order_status = 'delivered'
GROUP BY month
ORDER BY month;
-- Insight: the earliest period in the dataset shows an unusually high delivery time. Since monthly order volume isn't shown in this query,
	-- that anomaly needs to be validated against order counts before treating it as representative of a trend.
	-- the more reliable trend starts from 2017 onward: average delivery stabilizes at 11-15 days and the late rate sits in the 3-8% range, 
    -- with a small uptick in April 2017 (7.86%) that could be worth investigating (seasonality? a spike in order volume?).

-- Logic: DATE_FORMAT(..., '%Y-%m') buckets the dates into a "year-month" format, 
		-- GROUP BY that month, ORDER BY month to keep it chronological.

    -- Q40. Do late orders get lower customer ratings?
SELECT
    CASE 
    WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
		THEN 'Late'
		ELSE 'On Time'
		END AS delivery_status,
    ROUND(AVG(r.review_score), 2) AS avg_rating,
    COUNT(*) AS total_orders
FROM orders o
JOIN (SELECT order_id,
	AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id) r
		ON o.order_id = r.order_id
		WHERE o.order_status = 'delivered'
		GROUP BY delivery_status;
-- Insight: late orders have a much lower average customer rating — 2.57 versus 4.29 for on-time orders. 
        -- the 1.72-point gap shows a strong relationship between delivery punctuality and customer satisfaction.
		-- this means late delivery isn't just an operational problem, it also has real potential to hurt the customer experience.

-- Logic: CASE WHEN labels each order as "Late" or "On Time", 
		-- JOIN to order_reviews via order_id, GROUP BY that label, AVG(review_score) to see the average rating per group.
        
-- ================================== Segment 5 Business Insight Summary: Delivery Performance ======================================== -- 
-- Olist's delivery performance is relatively strong, with 97% of orders reaching delivered status and an average delivery time of 12.5 days. 
-- However, 8.11% of orders still arrive later than estimated, with the late rate varying significantly by state.
-- The most important finding: late orders average a 2.57 rating, far below the 4.29 average for on-time orders. 
-- This means delivery punctuality is a critical factor in customer satisfaction and should be a priority in evaluating logistics performance.
-- ================================== Segment 5 Business Insight Summary: Delivery Performance ======================================== -- 
