-- ----------------------------------------------------------------------------------------
-- OLIST BRAZIL E-COMMERCE ANALYSIS --
-- Analyzing Olist's business performance across:
-- Sales, customers, products, payments, sellers, delivery, and customer satisfaction
-- to find what's working well and what needs improvement
-- -----------------------------------------------------------------------------------------

-- Business questions are split into 6 segments:
-- 1. Sales Performance: How big is Olist's sales performance, and how is it trending?
	-- Q1. What is Olist's total revenue?
	-- Q2. How many total orders were successfully placed?
    -- Q3. How many total products/items were sold?
    -- Q4. How has order volume trended over time?
	-- Q5. How has revenue trended over time?
	-- Q6. Which month/year generated the highest revenue?
	-- Q7. What is the average order value?
	-- Q8. How does revenue compare month over month?
	-- Q9. Does order growth move in line with revenue growth?
    
-- 2. Product Performance: What products actually drive the business?
	-- Q10. Which product category generates the highest revenue?
    -- Q11. Which product category has the highest sales volume?
	-- Q12. What are the top 10 products by revenue?
	-- Q13. What are the top 10 products by units sold?
    -- Q14. Which product has the highest average price?
	-- Q15. Which category has the highest average product price?
	-- Q16. Which category has the most products?
	-- Q17. Does the category with the highest sales volume also generate the highest revenue?
    
-- 3. Customer Analysis: Who's buying, and how do customers behave?
	-- Q18. How many unique customers does Olist have?
    -- Q19. Which states do customers come from?
    -- Q20. Which state has the most customers?
    -- Q21. Which state generates the most revenue?
	-- Q22. What is the average order value by state?
	-- Q23. Does the state with the most customers also generate the most revenue?
	-- Q24. How many customers made more than one purchase?
	-- Q25. What percentage of orders come from repeat customers?
    
-- 4. Payments Analysis
	-- Q26. Which payment method is used the most?
	-- Q27. What is the total transaction value by payment method?
	-- Q28. Which payment method generates the highest transaction value?
	-- Q29. What is the average number of installments by payment method?
	-- Q30. Do customers who use installments have a higher average transaction value?
	-- Q31. What is the usage distribution of credit card, boleto, voucher, and debit card?
    
-- 5. Delivery Performance: Is Olist able to deliver on estimated time?
	-- Q32. What is the average delivery time to customers?
	-- Q33. How many orders were delivered?
	-- Q34. How many orders were canceled?
	-- Q35. How many orders were late?
	-- Q36. What percentage of orders were late?
	-- Q37. Which state has the longest average delivery time?
    -- Q38. Which state has the highest late-delivery rate?
	-- Q39. How has delivery performance trended over time?
    -- Q40. Do late orders get lower customer ratings?
    
-- 6. Customer Satisfaction: Are customers satisfied with the experience?
	-- Q41. What is Olist's average review score?
	-- Q42. What is the distribution of ratings 1–5?
	-- Q43. How many customers gave a rating of 1?
	-- Q44. How many customers gave a rating of 5?
	-- Q45. Which product category has the highest average rating?
	-- Q46. Which category has the lowest average rating?
	-- Q47. Is late delivery associated with lower ratings?
	-- Q48. Which state has the highest customer satisfaction?
-- -----------------------------------------------------------------------------------------------------------------------------------------

-- FIRST STEP = (DQ) Data Quality / cleaning / entry: input, check, and clean the data (step by step)

-- STEP 1: create the database for the raw olist_ecommerce data
create database olist_ecommerce;
use olist_ecommerce;

-- STEP 2: create the tables for the datasets used
	-- table creation could be done automatically via the import wizard,
	-- but doing it manually means full control over data types and table structure
CREATE TABLE customers (
    customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state VARCHAR(10)
); 	
-- note: VARCHAR = text/string, and (100) is the max character length. INT = whole number/integer.
CREATE TABLE orders (
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    order_status VARCHAR(30),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);
-- STEP 3: check the tables exist and confirm the structure is correct
show tables; -- check tables
describe customers; 			-- confirm table structure
describe orders; 				-- confirm table structure

-- STEP 4: import the data (matching the tables/order created above)

SELECT 'customers' AS table_name, COUNT(*) AS total_rows
FROM customers
UNION ALL
SELECT 'orders', COUNT(*)
FROM orders
UNION ALL
SELECT 'order_items', COUNT(*)
FROM order_items
UNION ALL
SELECT 'order_payments', COUNT(*)
FROM order_payments;

	-- pattern used: IMPORT -> CHECK
	-- after importing, re-check with the query below (customers dataset)
SELECT * FROM customers 
LIMIT 10;
							-- note: * selects all columns (in this case, all columns of customers)
SELECT COUNT(*) AS total_customers 
FROM customers;
							-- note: COUNT(*) counts every row.
							-- (in this case: "there are 99,441 rows in the customers data")
                            -- shortcut: * for columns = all columns, * for rows = all rows.
	-- import the orders dataset, then re-check
SELECT * FROM orders 
LIMIT 10;

SELECT COUNT(*) AS total_orders 
FROM orders;

-- Checking data quality
	-- Are there any customer_id values in orders that have no match in customers?
		-- uses LEFT JOIN + IS NULL, with ON as the join condition and WHERE to filter the unmatched rows
SELECT COUNT(*) AS unmatched_customer_id
FROM orders as o
LEFT JOIN customers as c 
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

	-- Are there any NULL order_id values in orders?
SELECT COUNT(*) AS null_order_id
from orders where order_id is null;

	-- Does any order_id appear more than once in orders?
select order_id, COUNT(*) as total 
from orders group by order_id
Having count(*) > 1;

	-- Can a single customer place more than one order?
select customer_id, COUNT(*) as total_orders
from orders group by customer_id
having count(*) >1;

-- The Olist dataset has both customer_id and customer_unique_id, so understanding the data model before analysis matters.
-- customer_id -> a technical ID that links a customer to a specific order.
-- customer_unique_id -> the ID that represents the same real person, including across multiple orders.
-- so getting 0 rows for "can a customer place more than one order?" isn't a data error, it's a misunderstanding of the data model.
	
	-- so the corrected query below uses a JOIN
        -- join rows from orders and customers where customer_id matches (JOIN query)
        
select c.customer_unique_id, count(*) as total_orders from orders as o 
    join customers as c on o.customer_id = c.customer_id
	group by customer_unique_id
	having count(*) >1;
    
    -- LOGIC OF THE QUERY ABOVE:
		-- Take the orders data, join it to customers via customer_id.
		-- Once joined, group orders by customer_unique_id and count how many orders each customer has.
		-- Finally, only show customers with more than one order.
        
	-- How many unique customers actually exist in this dataset?
		-- COUNT(DISTINCT ...) counts the number of distinct values.
        -- COUNT(*) counts the number of rows.
        -- COUNT(customer_unique_id) counts non-NULL customer_unique_id values.
        
SELECT COUNT(DISTINCT customer_unique_id) AS total_unique_customers 
FROM customers;

	-- Total rows in customers = 99,441 -- Unique customer_unique_id = 96,096
	-- So the 3,345-row difference comes from additional records for a customer_unique_id that already appeared before.
	-- Careful not to jump straight to "repeat orders" here — need to actually count how many customer_unique_id values appear more than once.
    
select customer_unique_id, count(*) as total 
	from customers
    group by customer_unique_id having count(*) >1;
    
    -- result: 2,997 rows returned.
    -- meaning 2,997 customer_unique_id values appear more than once in the customers table.
    -- Don't call this 2,997 "repeat customers" yet — this query only looks at duplicate customer_unique_id in the customers table.
	-- the actual question is:
	-- "How many customers placed more than one order?" — so the correct query is:
    
SELECT c.customer_unique_id, COUNT(*) AS total_orders
FROM orders AS o JOIN customers AS c
ON o.customer_id = c.customer_id
GROUP BY c.customer_unique_id
HAVING COUNT(*) > 1;

SELECT COUNT(*) AS total_repeat_customers
FROM (
	SELECT c.customer_unique_id
    FROM orders AS o JOIN customers AS c
	ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
    HAVING COUNT(*) > 1
) AS repeat_customers;
	-- result: 2,800 customers placed repeat orders

	-- a simple customer retention KPI
		-- CASE WHEN = "if this condition is true, assign this value" (simple logic)
        -- CASE 
			-- WHEN condition_1 THEN result_1
			-- WHEN condition_2 THEN result_2
			-- WHEN condition_3 THEN result_3
			-- ELSE other_result
		-- END AS new_column_name
SELECT customer_unique_id, total_orders,
CASE
	WHEN total_orders = 1 THEN 'One-time'
	WHEN total_orders > 1 THEN 'Repeat'
END AS customer_type
FROM (SELECT c.customer_unique_id, COUNT(*) AS total_orders
    FROM orders AS o
    JOIN customers AS c
	ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
) AS customer_orders;

	-- How many One-time vs. Repeat customers are there, and what's the percentage split?
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
