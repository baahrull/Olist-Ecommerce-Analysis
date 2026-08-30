-- ========================================================================================== --
-- Segment 3: Customer Analysis
-- ========================================================================================== --
-- note: for Segment 3, the initial import and data quality (DQ) checks were already covered earlier in the analysis.

	-- Q18 — How many unique customers does Olist have?
SELECT COUNT(DISTINCT customer_unique_id) AS total_unique_customers
FROM customers;
-- Business insight: Olist has 96,096 unique customers, showing a fairly large customer base over the observed period.

-- Logic: COUNT(DISTINCT customer_unique_id) is used because we want to count real, unique people. 
		-- customer_id can't be used to define a customer, since one customer placing multiple orders can have multiple customer_id values.

	-- Q19 — Which states do customers come from?
SELECT DISTINCT customer_state
FROM customers;
-- Business insight: Olist customers are spread across 27 Brazilian states, 
					-- meaning customer reach covers every state recorded in the dataset.

-- Logic: SELECT DISTINCT customer_state pulls each state code once with no repeats. 
		-- customer_state is the region/state code for the customer in the Olist dataset.

	-- Q20 — Which state has the most customers?
SELECT customer_state, COUNT(DISTINCT customer_unique_id) AS total_customers
FROM customers
GROUP BY customer_state
ORDER BY total_customers DESC
limit 10;
-- Business insight: São Paulo is Olist's customer hub with 40,302 customers,
					-- far ahead of every other state. This shows a strong customer concentration in SP.

-- Logic: COUNT(DISTINCT customer_unique_id) counts unique customers per state, then GROUP BY customer_state aggregates by region. 
		-- ORDER BY ... DESC sorts states by highest customer count.
		-- using DISTINCT customer_unique_id matters so repeat customers aren't double-counted as different people.

	-- Q21 — Which state generates the most revenue?
WITH order_value AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_value
    FROM order_payments
    GROUP BY order_id
)
SELECT
    c.customer_state,
    ROUND(SUM(ov.order_value), 2) AS revenue
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_value ov
    ON o.order_id = ov.order_id
GROUP BY c.customer_state
ORDER BY revenue DESC
LIMIT 10;
-- Business insight: SP is the largest revenue contributor at around R$5,998,226.96,
					-- showing that the region with the highest customer activity also carries the largest financial contribution.

-- Logic: the order_value CTE consolidates every payment into a single total per order. 
		-- orders are then joined to customers to get the state, and total order value is summed by state. 
		-- this way, revenue isn't double-counted when a single order has multiple payment records.
        
    -- Q22 — What is the average order value by state?
WITH order_value AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_value
    FROM order_payments
    GROUP BY order_id
)
SELECT
    c.customer_state,
    ROUND(AVG(ov.order_value), 2) AS avg_order_value
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_value ov
    ON o.order_id = ov.order_id
GROUP BY c.customer_state
ORDER BY avg_order_value DESC;
-- Business insight: PB has the highest average order value at $264.08, 
					-- suggesting customers in that region tend to transact at a higher value per order.

-- Logic: first we build the total value for each order, 
		-- then AVG() calculates the average of those order values per state.
		-- this is more accurate since a single order can have multiple payment records.
        
    -- Q23 — Does the state with the most customers also generate the most revenue?
WITH order_value AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_value
    FROM order_payments
    GROUP BY order_id
),
state_analysis AS (
    SELECT
        c.customer_state,
        COUNT(DISTINCT c.customer_unique_id) AS total_customers,
        ROUND(SUM(ov.order_value), 2) AS revenue
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    JOIN order_value ov
        ON o.order_id = ov.order_id
    GROUP BY c.customer_state
)
-- result:
SELECT
    customer_state,
    total_customers,
    revenue,
    RANK() OVER (ORDER BY total_customers DESC) AS customer_rank,
    RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
FROM state_analysis
ORDER BY customer_rank;
-- Business insight: SP ranks #1 in both customers and revenue, meaning SP's customer concentration is also reflected in its revenue. 
				-- If the rankings diverged, that would mean customer count alone doesn't fully explain revenue, and per-order transaction value plays a role too.

-- Logic: builds one aggregated table holding two metrics at once — unique customer count and revenue. 
		-- RANK() then ranks each metric separately, making it easy to see whether the state with the most customers is also the revenue leader.
    
    -- Q24 — How many customers made more than one purchase?
SELECT c.customer_unique_id, COUNT(*) AS total_orders
FROM orders AS o JOIN customers AS c
ON o.customer_id = c.customer_id
GROUP BY c.customer_unique_id
HAVING COUNT(*) > 1;
-- result: 
SELECT COUNT(*) AS total_repeat_customers
FROM (
	SELECT c.customer_unique_id
    FROM orders AS o JOIN customers AS c
	ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
    HAVING COUNT(*) > 1
) AS repeat_customers;
-- Business insight: 2,997 customers made more than one purchase, 
					-- showing there is a group of customers who successfully returned to transact again on Olist.

-- Logic: customers are grouped by customer_unique_id, then HAVING COUNT(*) > 1 selects customers with more than one order. 
		-- this works because customer_unique_id is the permanent identifier for tracking repeat purchases.

	-- Q25 — What percentage of orders come from repeat customers?
SELECT
    customer_type,
    COUNT(*) AS total_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM (
    SELECT
        c.customer_unique_id,
        COUNT(*) AS total_orders,
        CASE
            WHEN COUNT(*) = 1 THEN 'One-time'
            WHEN COUNT(*) > 1 THEN 'Repeat'
        END AS customer_type
    FROM orders AS o
    JOIN customers AS c
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
) AS customer_orders
GROUP BY customer_type;
-- Business insight: repeat customers make up 3.12% of all Olist orders, 
					-- showing the vast majority of transactions still come from one-time customers, 
					-- meaning there's significant room to improve customer retention.

-- Logic: customers are categorized as One-time or Repeat based on their order count per customer_unique_id. 
		-- the count in each group is then compared to get the rate. 
		-- for the order-level metric in Q25 specifically, the numerator needs to be the order count belonging to repeat customers, with all orders as the denominator.
        
-- ================================== Segment 3 Business Insight Summary: Customer Analysis ===================================== -- 
-- Olist has 96,096 customers spread across 27 states, with São Paulo as the largest customer hub. 
-- On the retention side, only 2,997 customers made a repeat purchase, and repeat customers account for just 3.12% of all orders. 
-- This shows Olist has a large customer base, but the contribution from repeat purchases is still relatively small.
-- ================================================================================================================================== --
